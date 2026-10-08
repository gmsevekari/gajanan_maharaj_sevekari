const {onSchedule} = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");
const logger = require("firebase-functions/logger");
const {randomUUID} = require("node:crypto");
const {DateTime} = require("luxon");
const {groupNameEn} = require("./groups");

const MINUTE = 60 * 1000;
const HOUR = 60 * MINUTE;

const PACIFIC = "America/Los_Angeles";
const INDIA = "Asia/Kolkata";

/**
 * The reminders. A reminder is due while the slot starts within `lead` but
 * not within `lead - WINDOW`: wider than the 10 minutes between runs, so a
 * missed run is covered, and narrow enough that a sign-up made 5 hours ahead
 * gets no "tomorrow" reminder.
 */
const REMINDERS = [
  {key: "day", lead: 24 * HOUR, phrase: "is tomorrow"},
  {key: "hour", lead: HOUR, phrase: "starts in 1 hour"},
];
const WINDOW = 30 * MINUTE;
const LOOK_AHEAD = 24 * HOUR;

// An all-day slot starts at midnight, so "24 hours before" would wake people
// at midnight: its day reminder goes out at this hour the day before.
const ALL_DAY_REMINDER_HOUR = 9;

// Reminders are for sign-ups people can actually attend.
const SENDING_STATUSES = ["published", "closed"];

const ANDROID_CHANNEL = "signup_reminders";
const MAX_NAME_LENGTH = 80;
const MAX_LINE_LENGTH = 120;
// Characters FCM allows in a topic name.
const TOPIC_PART = /^[A-Za-z0-9\-_.~%]+$/;
const RECORD_TRIES = 2;

// An attempt that has been "in progress" this long is taken to have died with
// its run (the function's timeout is 300 seconds), so the next run may try
// the reminder again. Shorter than the 10 minutes between runs.
const STALE_ATTEMPT = 6 * MINUTE;

// A send that takes this long is treated as failed, so one hung call cannot
// hold up every other slot until the function is killed.
const SEND_TIMEOUT = 60 * 1000;

/**
 * The FCM topic a device subscribes to when it has an entry on a slot.
 * @param {string} signupId The sign-up's id.
 * @param {string} slotId The slot's id.
 * @return {string} The topic name.
 */
function reminderTopic(signupId, slotId) {
  return `signup_slot_${signupId}_${slotId}`;
}

/**
 * The zone a slot's times are shown in: India or, as in the app, Pacific for
 * anything else.
 * @param {string} timezone The slot's timezone.
 * @return {string} An IANA zone.
 */
function zoneOf(timezone) {
  return timezone === INDIA ? INDIA : PACIFIC;
}

/**
 * @param {Object} slot A slot document's data.
 * @param {string} field "startAt" or "endAt".
 * @return {DateTime} That instant in the slot's own zone, in English.
 */
function wallClock(slot, field) {
  return DateTime.fromMillis(slot[field].toMillis(), {
    zone: zoneOf(slot.timezone),
  }).setLocale("en-US");
}

/**
 * Whether the slot runs 00:00 to 23:59 in its own zone, which is what a slot
 * created without times looks like.
 * @param {Object} slot A slot document's data (with startAt and endAt).
 * @return {boolean} True for an all-day slot.
 */
function isAllDay(slot) {
  const start = wallClock(slot, "startAt");
  const end = wallClock(slot, "endAt");
  return start.hour === 0 && start.minute === 0 &&
      end.hour === 23 && end.minute === 59;
}

/**
 * A slot's date and time range as one line, in its own zone, in English, the
 * way the app shows it: "Sat, Oct 10, 9:00 AM – 11:00 AM PT"; just the date
 * for an all-day slot; both ends in full when it spans days; years only when
 * the start and end are in different years.
 * @param {Object} slot A slot document's data (with startAt and endAt).
 * @return {string} The line.
 */
function formatSlotWhen(slot) {
  const start = wallClock(slot, "startAt");
  const end = wallClock(slot, "endAt");
  const label = zoneOf(slot.timezone) === INDIA ? "IST" : "PT";
  const allDay = isAllDay(slot);

  if (start.toISODate() === end.toISODate()) {
    const date = start.toFormat("ccc, LLL d");
    if (allDay) return date;
    return `${date}, ${start.toFormat("h:mm a")} – ` +
        `${end.toFormat("h:mm a")} ${label}`;
  }

  const withYear = start.year !== end.year;
  const day = (when) => when.toFormat(withYear ? "LLL d, yyyy" : "LLL d");
  if (allDay) return `${day(start)} – ${day(end)}`;
  return `${day(start)}, ${start.toFormat("h:mm a")} – ` +
      `${day(end)}, ${end.toFormat("h:mm a")} ${label}`;
}

/**
 * How long before its start each reminder goes out, for this slot. An all-day
 * slot gets its day reminder at 9 AM the day before (its zone's wall clock)
 * and no hour reminder: an hour before midnight is no use to anyone.
 * @param {Object} slot A slot document's data (with startAt and endAt).
 * @return {Array<{key: string, lead: number}>} The reminders and their leads.
 */
function leadsFor(slot) {
  if (!isAllDay(slot)) {
    return REMINDERS.map(({key, lead}) => ({key, lead}));
  }
  const start = wallClock(slot, "startAt");
  const morning = start.minus({days: 1}).set({
    hour: ALL_DAY_REMINDER_HOUR, minute: 0, second: 0, millisecond: 0,
  });
  return [{key: "day", lead: start.toMillis() - morning.toMillis()}];
}

/**
 * Which reminders are due now for one slot, going by its time and the
 * records of what was already sent (not by who signed up or the sign-up's
 * status: those are checked only for a slot that is due).
 * @param {Object} args The slot.
 * @param {Object} args.slot The slot document's data.
 * @param {number} args.now Now, in ms since the epoch.
 * @return {string[]} The due reminder keys ("day", "hour"): none for a slot
 *   without a date or already reminded for its current start time.
 */
function dueReminders({slot, now}) {
  if (!slot.startAt || !slot.endAt) return [];

  const start = slot.startAt.toMillis();
  const ahead = start - now;
  const sent = slot.reminders || {};
  return leadsFor(slot)
      .filter(({key, lead}) =>
        ahead <= lead && ahead > lead - WINDOW && sent[key] !== start)
      .map(({key}) => key);
}

/**
 * @param {?Object} signup A sign-up document's data.
 * @return {boolean} Whether its slots get reminders: published and closed
 *   sign-ups do (closed means no new entries, not that it is cancelled); a
 *   draft or missing one does not.
 */
function isSendable(signup) {
  return !!signup && SENDING_STATUSES.includes(signup.status);
}

/**
 * Admin-typed text made fit for one line of a notification: whitespace
 * (including line breaks) collapsed to single spaces, and cut to [max]
 * characters with an ellipsis. Cuts between whole characters as a reader sees
 * them (so never inside an emoji or a Devanagari conjunct).
 * @param {string} text The text.
 * @param {number} max The most characters to keep.
 * @return {string} The cleaned text.
 */
function oneLine(text, max) {
  const clean = text.replace(/\s+/g, " ").trim();
  const characters = Array.from(
      new Intl.Segmenter("en", {granularity: "grapheme"}).segment(clean),
      (part) => part.segment);
  if (characters.length <= max) return clean;
  return `${characters.slice(0, max - 1).join("")}…`;
}

/**
 * @param {*} english The English text.
 * @param {*} marathi The Marathi text.
 * @return {string} The English text, or the Marathi only if there is none.
 */
function preferEnglish(english, marathi) {
  const en = typeof english === "string" ? english.trim() : "";
  if (en !== "") return en;
  return typeof marathi === "string" ? marathi.trim() : "";
}

/**
 * The push message for one reminder: always English, whatever language the
 * devotee uses in the app.
 * @param {Object} args The reminder.
 * @param {string} args.kind "day" or "hour".
 * @param {string} args.signupId The sign-up's id.
 * @param {string} args.slotId The slot's id.
 * @param {Object} args.slot The slot document's data.
 * @param {Object} args.signup The sign-up's data.
 * @return {Object} An FCM message for the slot's topic.
 */
function buildReminderMessage({kind, signupId, slotId, slot, signup}) {
  const phrase = REMINDERS.find((reminder) => reminder.key === kind).phrase;
  const signupName = oneLine(
      preferEnglish(signup.titleEn, signup.titleMr), MAX_NAME_LENGTH) ||
      "your sign-up";
  const slotName = oneLine(
      preferEnglish(slot.labelEn, slot.labelMr), MAX_NAME_LENGTH);
  const group = groupNameEn(signup.groupId);

  const title = `Reminder: ${signupName} ${phrase}`;
  const body = [
    oneLine(group === "" ? signupName : `${group} - ${signupName}`,
        MAX_LINE_LENGTH),
    ...(slotName === "" ? [] : [`Slot: ${slotName}`]),
    formatSlotWhen(slot),
  ].join("\n");

  return {
    notification: {title, body},
    data: {type: "SIGNUP_REMINDER", signup_id: signupId, slot_id: slotId},
    android: {
      priority: "high",
      notification: {
        channelId: ANDROID_CHANNEL,
        priority: "high",
        defaultSound: true,
      },
    },
    apns: {
      headers: {"apns-push-type": "alert", "apns-priority": "10"},
      payload: {aps: {alert: {title, body}, sound: "default"}},
    },
    topic: reminderTopic(signupId, slotId),
  };
}

/**
 * Starts an attempt at sending [kind] for the slot's current start time,
 * recorded in a transaction so that only one run attempts it at a time.
 * Nothing is recorded (and null is returned) if the slot is gone, has moved
 * since it was read, was already sent, or another run is attempting it right
 * now (an attempt older than STALE_ATTEMPT counts as dead).
 * @param {Object} args The attempt.
 * @param {Object} args.db Firestore.
 * @param {Object} args.ref The slot's document reference.
 * @param {string} args.kind "day" or "hour".
 * @param {number} args.start The start time that was read, in ms.
 * @param {number} args.now Now, in ms.
 * @param {string} args.id A unique id for this attempt.
 * @return {Promise<?Object>} The slot's current data if the attempt may go
 *   ahead, else null.
 */
function beginAttempt({db, ref, kind, start, now, id}) {
  return db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(ref);
    if (!snapshot.exists) return null;
    const data = snapshot.data();
    if (!data.startAt || data.startAt.toMillis() !== start) return null;
    if ((data.reminders || {})[kind] === start) return null;
    const attempt = (data.reminderAttempts || {})[kind];
    if (attempt && attempt.start === start &&
        now - attempt.at < STALE_ATTEMPT) {
      return null;
    }
    transaction.update(ref, {
      [`reminderAttempts.${kind}`]: {start, at: now, id},
    });
    return data;
  });
}

/**
 * Gives up an attempt that failed, so the next run tries again - but only if
 * it is still this attempt: a slot moved meanwhile has a newer one that must
 * stay. Tried twice; if both fail the attempt expires on its own after
 * STALE_ATTEMPT.
 * @param {Object} args The attempt.
 * @param {Object} args.db Firestore.
 * @param {Object} args.ref The slot's document reference.
 * @param {string} args.kind "day" or "hour".
 * @param {string} args.id The attempt's id.
 * @param {Object} args.FieldValue Firestore's FieldValue class.
 * @return {Promise<void>} Resolves once done or given up.
 */
async function abandonAttempt({db, ref, kind, id, FieldValue}) {
  for (let attempt = 1; attempt <= RECORD_TRIES; attempt++) {
    try {
      await db.runTransaction(async (transaction) => {
        const snapshot = await transaction.get(ref);
        if (!snapshot.exists) return;
        const current = (snapshot.data().reminderAttempts || {})[kind];
        if (!current || current.id !== id) return;
        transaction.update(ref, {
          [`reminderAttempts.${kind}`]: FieldValue.delete(),
        });
      });
      return;
    } catch (error) {
      logger.error(`Could not give up the failed ${kind} attempt ` +
          `(try ${attempt} of ${RECORD_TRIES})`, error);
    }
  }
}

/**
 * Records that [kind] reached FCM for this start time, which is what stops
 * it ever being sent again, and closes the attempt if it is still this one.
 * Done in a transaction, and only while the slot still starts at [start]: a
 * slot an admin has moved since has its own record, which a late write from
 * here must not overwrite. Tried twice; if both fail the reminder will be
 * sent a second time once the attempt expires, which is logged.
 * @param {Object} args The sent reminder.
 * @param {Object} args.db Firestore.
 * @param {Object} args.ref The slot's document reference.
 * @param {string} args.kind "day" or "hour".
 * @param {number} args.start The start time it was for, in ms.
 * @param {string} args.id The attempt's id.
 * @param {Object} args.FieldValue Firestore's FieldValue class.
 * @return {Promise<boolean>} False if it could not be recorded.
 */
async function confirmSent({db, ref, kind, start, id, FieldValue}) {
  for (let attempt = 1; attempt <= RECORD_TRIES; attempt++) {
    try {
      await db.runTransaction(async (transaction) => {
        const snapshot = await transaction.get(ref);
        if (!snapshot.exists) return;
        const data = snapshot.data();
        if (!data.startAt || data.startAt.toMillis() !== start) return;
        const fields = {[`reminders.${kind}`]: start};
        const current = (data.reminderAttempts || {})[kind];
        if (current && current.id === id) {
          fields[`reminderAttempts.${kind}`] = FieldValue.delete();
        }
        transaction.update(ref, fields);
      });
      return true;
    } catch (error) {
      logger.error(`Could not record the sent ${kind} reminder ` +
          `(try ${attempt} of ${RECORD_TRIES})`, error);
    }
  }
  return false;
}

/**
 * @param {Promise} promise What to wait for.
 * @param {number} ms The longest to wait.
 * @return {Promise} The promise's result, or a rejection after [ms].
 */
function withTimeout(promise, ms) {
  let timer;
  const timeout = new Promise((resolve, reject) => {
    timer = setTimeout(() => reject(new Error(`Timed out after ${ms} ms`)), ms);
  });
  return Promise.race([promise, timeout]).finally(() => clearTimeout(timer));
}

/**
 * Sends one reminder so that exactly one send succeeds: an attempt is
 * recorded first (so no other run sends it at the same time), a failed send
 * gives the attempt up (so the next run tries again), and a successful one is
 * recorded as sent (so it is never sent again). A run that dies mid-send
 * leaves an attempt that expires after STALE_ATTEMPT, so the reminder is
 * still retried.
 * @param {Object} args The reminder.
 * @param {Object} args.deps db, messaging, now and FieldValue.
 * @param {Object} args.doc The slot's query document.
 * @param {string} args.signupId The sign-up's id.
 * @param {Object} args.signup The sign-up's data.
 * @param {string} args.kind "day" or "hour".
 * @return {Promise<?{recorded: boolean}>} Null if there was nothing to
 *   send; otherwise that it was sent, and whether that was recorded. Throws
 *   if the send failed.
 */
async function sendOne({deps, doc, signupId, signup, kind}) {
  const {db, messaging, FieldValue, now, sendTimeout = SEND_TIMEOUT} = deps;
  const start = doc.data().startAt.toMillis();
  const id = randomUUID();
  const slot = await beginAttempt({db, ref: doc.ref, kind, start, now, id});
  if (slot === null) return null;
  try {
    await withTimeout(messaging.send(buildReminderMessage({
      kind, signupId, slotId: doc.id, slot, signup,
    })), sendTimeout);
  } catch (error) {
    await abandonAttempt({db, ref: doc.ref, kind, id, FieldValue});
    throw error;
  }
  const recorded = await confirmSent({
    db, ref: doc.ref, kind, start, id, FieldValue,
  });
  return {recorded};
}

/**
 * Whether any device is linked to an entry on the slot, so a reminder has
 * someone to reach. Read from the entries themselves, not the slot's
 * `claimedCount`: the rules let anyone nudge that counter by one per write,
 * so it can be driven to 0 to silence a slot.
 * @param {Object} args The slot.
 * @param {Object} args.db Firestore.
 * @param {string} args.signupId The sign-up's id.
 * @param {string} args.slotId The slot's id.
 * @return {Promise<boolean>} True if an entry on the slot has a device.
 */
async function hasDeviceEntry({db, signupId, slotId}) {
  const snapshot = await db.collection("signups").doc(signupId)
      .collection("entries").where("slotId", "==", slotId).get();
  return snapshot.docs.some((entry) => {
    const deviceId = entry.data().deviceId;
    return typeof deviceId === "string" && deviceId !== "";
  });
}

/**
 * Sends what is due for one slot of the query, reading the sign-up (once
 * per run) and the entries only when something is due.
 * @param {Object} args The slot.
 * @param {Object} args.deps db, messaging, now and FieldValue.
 * @param {Map} args.signups The run's cache of sign-up data by id.
 * @param {Object} args.doc The slot's query document.
 * @return {Promise<{sent: number, unrecorded: number}>} How many reminders
 *   were sent, and how many of those could not be recorded as sent.
 */
async function remindSlot({deps, signups, doc}) {
  const {db, now} = deps;
  const kinds = dueReminders({slot: doc.data(), now});
  const none = {sent: 0, unrecorded: 0};
  if (kinds.length === 0) return none;

  const signupId = doc.ref.parent.parent.id;
  if (!TOPIC_PART.test(signupId) || !TOPIC_PART.test(doc.id)) {
    logger.warn(`Slot ${doc.id} of ${signupId} has an id that cannot be ` +
        "part of a topic name; skipped.");
    return none;
  }
  if (!signups.has(signupId)) {
    const snapshot = await db.collection("signups").doc(signupId).get();
    signups.set(signupId, snapshot.exists ? snapshot.data() : null);
  }
  const signup = signups.get(signupId);
  if (!isSendable(signup)) return none;
  if (!await hasDeviceEntry({db, signupId, slotId: doc.id})) return none;

  const tally = {sent: 0, unrecorded: 0};
  for (const kind of kinds) {
    const result = await sendOne({deps, doc, signupId, signup, kind});
    if (result === null) continue;
    tally.sent++;
    if (!result.recorded) tally.unrecorded++;
  }
  return tally;
}

/**
 * One run: sends every reminder that is due.
 * @param {Object} deps What the run needs, injected so it can be tested.
 * @param {Object} deps.db Firestore.
 * @param {Object} deps.messaging Firebase Cloud Messaging.
 * @param {number} deps.now Now, in ms since the epoch.
 * @param {Object} deps.Timestamp Firestore's Timestamp class.
 * @param {Object} deps.FieldValue Firestore's FieldValue class.
 * @return {Promise<{checked: number, sent: number, unrecorded: number,
 *   failed: number}>} A tally; `unrecorded` counts reminders that were sent but
 *   could not be recorded as sent, which will be sent again.
 */
async function runSignupReminders(deps) {
  const {db, now, Timestamp} = deps;
  const snapshot = await db.collectionGroup("slots")
      .where("startAt", ">", Timestamp.fromMillis(now))
      .where("startAt", "<=", Timestamp.fromMillis(now + LOOK_AHEAD))
      .get();

  const signups = new Map();
  const tally = {
    checked: snapshot.docs.length, sent: 0, unrecorded: 0, failed: 0,
  };
  for (const doc of snapshot.docs) {
    try {
      const result = await remindSlot({deps, signups, doc});
      tally.sent += result.sent;
      tally.unrecorded += result.unrecorded;
    } catch (error) {
      tally.failed++;
      logger.error(`Sign-up reminder failed for slot ${doc.id}`, error);
    }
  }
  return tally;
}

/**
 * Every 10 minutes, reminds the devotees who signed up for a slot, 1 day and
 * 1 hour before it starts, through the slot's FCM topic (devices subscribe
 * to it when they sign up or claim an entry).
 */
exports.sendSignupReminders = onSchedule(
    {
      schedule: "every 10 minutes",
      // One run at a time. The next run, 10 minutes on, is the retry, so the
      // platform does not also retry a failed one.
      maxInstances: 1,
      retryCount: 0,
      timeoutSeconds: 300,
    },
    async () => {
      const tally = await runSignupReminders({
        db: admin.firestore(),
        messaging: admin.messaging(),
        now: Date.now(),
        Timestamp: admin.firestore.Timestamp,
        FieldValue: admin.firestore.FieldValue,
      });
      logger.info("Sign-up reminders", tally);
    },
);

exports.reminderTopic = reminderTopic;
exports.isAllDay = isAllDay;
exports.formatSlotWhen = formatSlotWhen;
exports.dueReminders = dueReminders;
exports.isSendable = isSendable;
exports.oneLine = oneLine;
exports.buildReminderMessage = buildReminderMessage;
exports.runSignupReminders = runSignupReminders;

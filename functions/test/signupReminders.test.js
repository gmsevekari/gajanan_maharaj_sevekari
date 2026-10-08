const test = require("firebase-functions-test")();
const chai = require("chai");
const sinon = require("sinon");
const expect = chai.expect;
const admin = require("firebase-admin");

const HOUR = 60 * 60 * 1000;
const MINUTE = 60 * 1000;

describe("Sign-up reminders", () => {
  let reminders;

  before(() => {
    if (admin.initializeApp.restore) admin.initializeApp.restore();
    sinon.stub(admin, "initializeApp");

    require("../index.js");
    reminders = require("../signupReminders.js");
  });

  after(() => {
    sinon.restore();
    test.cleanup();
  });

  const NOW = Date.parse("2026-10-08T12:00:00Z");

  /**
   * A Firestore-timestamp lookalike.
   * @param {number} millis Milliseconds since the epoch.
   * @return {Object} Has toMillis().
   */
  const ts = (millis) => ({toMillis: () => millis});

  /**
   * A slot document's data starting [fromNow] ms after NOW and lasting
   * [lasts] ms, in Pacific time, with someone signed up.
   * @param {number} fromNow Ms from NOW to the start.
   * @param {Object} overrides Fields to change.
   * @param {number} lasts Length in ms.
   * @return {Object} The slot data.
   */
  function slot(fromNow, overrides = {}, lasts = 2 * HOUR) {
    return {
      labelEn: "Morning Seva",
      labelMr: "सकाळची सेवा",
      startAt: ts(NOW + fromNow),
      endAt: ts(NOW + fromNow + lasts),
      timezone: "America/Los_Angeles",
      capacity: 5,
      claimedCount: 2,
      ...overrides,
    };
  }

  const published = {
    status: "published",
    titleEn: "Prasad Seva",
    titleMr: "प्रसाद सेवा",
    groupId: "gajanan_maharaj_seattle",
  };

  describe("reminderTopic", () => {
    it("names one topic per slot", () => {
      expect(reminders.reminderTopic("sign1", "slotA"))
          .to.equal("signup_slot_sign1_slotA");
    });
  });

  describe("formatSlotWhen", () => {
    const format = (start, end, timezone = "America/Los_Angeles") =>
      reminders.formatSlotWhen({
        startAt: ts(Date.parse(start)),
        endAt: ts(Date.parse(end)),
        timezone,
      });

    it("shows a timed one-day slot's date and times with the zone", () => {
      expect(format("2026-10-10T16:00:00Z", "2026-10-10T18:00:00Z"))
          .to.equal("Sat, Oct 10, 9:00 AM – 11:00 AM PT");
    });

    it("uses India time for an India slot", () => {
      expect(format("2026-10-10T12:30:00Z", "2026-10-10T14:00:00Z",
          "Asia/Kolkata")).to.equal("Sat, Oct 10, 6:00 PM – 7:30 PM IST");
    });

    it("treats an unknown timezone as Pacific, like the app", () => {
      expect(format(
          "2026-10-10T16:00:00Z", "2026-10-10T18:00:00Z", "Mars/Base"))
          .to.equal("Sat, Oct 10, 9:00 AM – 11:00 AM PT");
    });

    it("follows daylight saving: the same wall time in winter", () => {
      expect(format("2026-12-05T17:00:00Z", "2026-12-05T19:00:00Z"))
          .to.equal("Sat, Dec 5, 9:00 AM – 11:00 AM PT");
    });

    it("shows just the date for an all-day slot", () => {
      expect(format("2026-10-10T07:00:00Z", "2026-10-11T06:59:00Z"))
          .to.equal("Sat, Oct 10");
    });

    it("shows a range of dates for an all-day slot over several days", () => {
      expect(format("2026-10-09T07:00:00Z", "2026-10-12T06:59:00Z"))
          .to.equal("Oct 9 – Oct 11");
    });

    it("shows both ends in full for a timed slot over midnight", () => {
      expect(format("2026-10-10T06:00:00Z", "2026-10-10T08:00:00Z"))
          .to.equal("Oct 9, 11:00 PM – Oct 10, 1:00 AM PT");
    });

    it("shows the years when the slot crosses New Year", () => {
      expect(format("2027-01-01T07:00:00Z", "2027-01-01T09:00:00Z"))
          .to.equal("Dec 31, 2026, 11:00 PM – Jan 1, 2027, 1:00 AM PT");
    });
  });

  describe("isAllDay", () => {
    it("is true only for 00:00 to 23:59 in the slot's own zone", () => {
      expect(reminders.isAllDay(slot(0, {
        startAt: ts(Date.parse("2026-10-10T07:00:00Z")),
        endAt: ts(Date.parse("2026-10-11T06:59:00Z")),
      }))).to.equal(true);
      expect(reminders.isAllDay(slot(0, {
        startAt: ts(Date.parse("2026-10-10T18:30:00Z")),
        endAt: ts(Date.parse("2026-10-11T18:29:00Z")),
        timezone: "Asia/Kolkata",
      }))).to.equal(true);
      expect(reminders.isAllDay(slot(HOUR))).to.equal(false);
    });

    it("is false when only the start or only the end is at the day's edge",
        () => {
          const allDay = (start, end) => reminders.isAllDay(slot(0, {
            startAt: ts(Date.parse(start)),
            endAt: ts(Date.parse(end)),
          }));

          // Starts 00:30, ends 23:59 (Pacific).
          expect(allDay("2026-10-10T07:30:00Z", "2026-10-11T06:59:00Z"))
              .to.equal(false);
          // Starts 00:00, ends 23:00.
          expect(allDay("2026-10-10T07:00:00Z", "2026-10-11T06:00:00Z"))
              .to.equal(false);
          // Starts 00:00, ends 23:30.
          expect(allDay("2026-10-10T07:00:00Z", "2026-10-11T06:30:00Z"))
              .to.equal(false);
        });
  });

  describe("dueReminders", () => {
    const due = (data, now = NOW) => reminders.dueReminders({slot: data, now});

    it("sends the day reminder from 24 hours out down to 23.5", () => {
      expect(due(slot(24 * HOUR))).to.deep.equal(["day"]);
      expect(due(slot(24 * HOUR - 1))).to.deep.equal(["day"]);
      expect(due(slot(23 * HOUR + 30 * MINUTE + 1))).to.deep.equal(["day"]);
    });

    it("does not send the day reminder too early or too late", () => {
      expect(due(slot(24 * HOUR + 1))).to.deep.equal([]);
      expect(due(slot(23 * HOUR + 30 * MINUTE))).to.deep.equal([]);
      expect(due(slot(5 * HOUR))).to.deep.equal([]);
    });

    it("sends the hour reminder from 60 minutes out down to 30", () => {
      expect(due(slot(HOUR))).to.deep.equal(["hour"]);
      expect(due(slot(30 * MINUTE + 1))).to.deep.equal(["hour"]);
    });

    it("does not send the hour reminder too early or too late", () => {
      expect(due(slot(HOUR + 1))).to.deep.equal([]);
      expect(due(slot(30 * MINUTE))).to.deep.equal([]);
      expect(due(slot(-MINUTE))).to.deep.equal([]);
      expect(due(slot(0))).to.deep.equal([]);
    });

    it("skips a reminder already sent for this start time", () => {
      const start = NOW + HOUR;
      expect(due(slot(HOUR, {reminders: {hour: start}})))
          .to.deep.equal([]);
      expect(due(slot(24 * HOUR, {reminders: {day: NOW + 24 * HOUR}})))
          .to.deep.equal([]);
    });

    it("sends again when the slot has moved since it was sent", () => {
      expect(due(slot(HOUR, {reminders: {hour: NOW + 5 * HOUR}})))
          .to.deep.equal(["hour"]);
    });

    it("keeps the two reminders' records apart", () => {
      expect(due(slot(HOUR, {reminders: {day: NOW + 23 * HOUR}})))
          .to.deep.equal(["hour"]);
    });

    it("sends nothing for a slot with no date and time", () => {
      expect(due(slot(HOUR, {startAt: null}))).to.deep.equal([]);
      expect(due(slot(HOUR, {endAt: null}))).to.deep.equal([]);
    });

    describe("an all-day slot", () => {
      // 00:00 to 23:59 Pacific on Oct 10; its day reminder is 9 AM on Oct 9
      // (16:00 UTC), not midnight.
      const midnight = Date.parse("2026-10-10T07:00:00Z");
      const nineAm = Date.parse("2026-10-09T16:00:00Z");
      const allDay = slot(0, {
        startAt: ts(midnight),
        endAt: ts(midnight + 24 * HOUR - MINUTE),
      });

      it("is reminded at 9 AM the day before", () => {
        expect(due(allDay, nineAm)).to.deep.equal(["day"]);
        expect(due(allDay, nineAm + 29 * MINUTE)).to.deep.equal(["day"]);
      });

      it("is not woken at midnight, nor reminded outside the window", () => {
        expect(due(allDay, midnight - 24 * HOUR)).to.deep.equal([]);
        expect(due(allDay, nineAm - 1)).to.deep.equal([]);
        expect(due(allDay, nineAm + 30 * MINUTE)).to.deep.equal([]);
      });

      it("never gets the hour reminder", () => {
        expect(due(allDay, midnight - HOUR)).to.deep.equal([]);
      });

      it("is reminded at 9 AM local even across a clock change", () => {
        // Sun Nov 1 2026 is when Pacific time falls back; the slot is Nov 2.
        const nov2 = Date.parse("2026-11-02T08:00:00Z"); // 00:00 PST
        const slotNov2 = slot(0, {
          startAt: ts(nov2),
          endAt: ts(nov2 + 24 * HOUR - MINUTE),
        });
        // 9 AM PST on Nov 1 is 17:00 UTC.
        expect(due(slotNov2, Date.parse("2026-11-01T17:00:00Z")))
            .to.deep.equal(["day"]);
      });

      it("uses its own zone: 9 AM in India", () => {
        const start = Date.parse("2026-10-09T18:30:00Z"); // 00:00 IST Oct 10
        const india = slot(0, {
          startAt: ts(start),
          endAt: ts(start + 24 * HOUR - MINUTE),
          timezone: "Asia/Kolkata",
        });
        // 9 AM IST on Oct 9 is 03:30 UTC.
        expect(due(india, Date.parse("2026-10-09T03:30:00Z")))
            .to.deep.equal(["day"]);
      });
    });
  });

  describe("isSendable", () => {
    it("is true for published and closed sign-ups, never draft", () => {
      expect(reminders.isSendable(published)).to.equal(true);
      expect(reminders.isSendable({...published, status: "closed"}))
          .to.equal(true);
      expect(reminders.isSendable({...published, status: "draft"}))
          .to.equal(false);
    });

    it("is false for a sign-up that does not exist", () => {
      expect(reminders.isSendable(null)).to.equal(false);
      expect(reminders.isSendable(undefined)).to.equal(false);
    });
  });

  describe("oneLine", () => {
    it("collapses line breaks and runs of spaces to single spaces", () => {
      expect(reminders.oneLine("  Slot\n\nfree\t for   all \r\n", 80))
          .to.equal("Slot free for all");
    });

    it("leaves text that fits alone", () => {
      expect(reminders.oneLine("Prasad Seva", 11)).to.equal("Prasad Seva");
    });

    it("cuts long text to the limit, ending in an ellipsis", () => {
      const out = reminders.oneLine("abcdefghij", 5);
      expect(out).to.equal("abcd…");
    });

    it("never cuts an emoji in two", () => {
      const out = reminders.oneLine("😀".repeat(5), 3);
      expect(out).to.equal("😀😀…");
      expect(out).to.not.match(/[\ud800-\udbff](?![\udc00-\udfff])/);
    });

    it("never cuts a Devanagari conjunct in two", () => {
      // "क्ष" is three code points but one letter to a reader.
      const out = reminders.oneLine("क्षक्षक्षक्ष", 3);
      expect(out).to.equal("क्षक्ष…");
    });
  });

  describe("buildReminderMessage", () => {
    const build = (kind, data = slot(HOUR), signup = published) =>
      reminders.buildReminderMessage({
        kind, signupId: "sign1", slotId: "slotA", slot: data, signup,
      });

    it("says the group, sign-up, slot, start and end", () => {
      const message = build("hour", slot(HOUR, {
        startAt: ts(Date.parse("2026-10-10T16:00:00Z")),
        endAt: ts(Date.parse("2026-10-10T18:00:00Z")),
      }));

      expect(message.notification.title)
          .to.equal("Reminder: Prasad Seva starts in 1 hour");
      expect(message.notification.body).to.equal([
        "Seattle GM Parivar - Prasad Seva",
        "Slot: Morning Seva",
        "Sat, Oct 10, 9:00 AM – 11:00 AM PT",
      ].join("\n"));
    });

    it("words the day reminder as tomorrow", () => {
      expect(build("day").notification.title)
          .to.equal("Reminder: Prasad Seva is tomorrow");
    });

    it("targets the slot's topic and carries what the app needs", () => {
      const message = build("day");

      expect(message.topic).to.equal("signup_slot_sign1_slotA");
      expect(message.data).to.deep.equal({
        type: "SIGNUP_REMINDER",
        signup_id: "sign1",
        slot_id: "slotA",
      });
    });

    it("uses the sign-up reminders channel at high priority", () => {
      const message = build("hour");

      expect(message.android.priority).to.equal("high");
      expect(message.android.notification.channelId)
          .to.equal("signup_reminders");
    });

    it("is a visible, high-priority alert on iPhones too", () => {
      const message = build("hour");

      expect(message.apns.headers["apns-push-type"]).to.equal("alert");
      expect(message.apns.headers["apns-priority"]).to.equal("10");
      expect(message.apns.payload.aps.alert).to.deep.equal(
          message.notification);
      expect(message.apns.payload.aps.sound).to.equal("default");
    });

    it("is English even when the sign-up has Marathi names", () => {
      const message = build("hour");

      expect(message.notification.title).to.not.match(/[ऀ-ॿ]/);
      expect(message.notification.body).to.not.match(/[ऀ-ॿ]/);
    });

    it("falls back to the Marathi names only when the English is blank", () => {
      const message = build("hour",
          slot(HOUR, {labelEn: ""}),
          {...published, titleEn: "  "});

      expect(message.notification.title)
          .to.equal("Reminder: प्रसाद सेवा starts in 1 hour");
      expect(message.notification.body).to.contain("Slot: सकाळची सेवा");
    });

    it("leaves the slot line out when the slot has no name", () => {
      const message = build("hour", slot(HOUR, {labelEn: "", labelMr: ""}));

      expect(message.notification.body).to.not.contain("Slot:");
      expect(message.notification.body.split("\n")).to.have.length(2);
    });

    it("calls an unnamed sign-up \"your sign-up\"", () => {
      const message = build("hour", slot(HOUR),
          {...published, titleEn: "", titleMr: ""});

      expect(message.notification.title)
          .to.equal("Reminder: your sign-up starts in 1 hour");
    });

    it("keeps admin-typed line breaks out of the message layout", () => {
      const message = build("hour", slot(HOUR, {labelEn: "A\nB"}));

      expect(message.notification.body).to.contain("Slot: A B");
      expect(message.notification.body.split("\n")).to.have.length(3);
    });

    it("leaves the group out when it is not known", () => {
      const message = build("hour", slot(HOUR), {...published, groupId: "x"});

      expect(message.notification.body.split("\n")[0]).to.equal("Prasad Seva");
    });

    it("keeps very long names short enough for a notification", () => {
      const long = "A".repeat(500);
      const message = build("hour", slot(HOUR, {labelEn: long}),
          {...published, titleEn: long});

      // Each name is cut to 80 characters (79 and an ellipsis).
      expect(message.notification.title)
          .to.equal(`Reminder: ${"A".repeat(79)}… starts in 1 hour`);
      expect(message.notification.body.split("\n")[1])
          .to.equal(`Slot: ${"A".repeat(79)}…`);
    });
  });

  describe("runSignupReminders", () => {
    const DELETE = {delete: true};
    const Timestamp = {fromMillis: (ms) => ({ms})};
    const FieldValue = {delete: () => DELETE};

    /**
     * An in-memory Firestore with just what the run uses: a slots
     * collection group query, sign-up documents with their entries, and
     * transactions.
     * @param {Object} data {signups: {id: data}, slots: {"sign/slot": data},
     *   entries: {"sign/slot": [entry data]}} - a slot with no `entries`
     *   key has one entry linked to a device.
     * @return {Object} The fake db, with `queries` and `signupReads`.
     */
    function fakeDb({signups, slots, entries = {}}) {
      // Firestore hands out copies, not the stored objects.
      const copy = (value) => {
        if (Array.isArray(value)) return value.map(copy);
        if (value && typeof value === "object") {
          return Object.fromEntries(
              Object.entries(value).map(([k, v]) => [k, copy(v)]));
        }
        return value;
      };
      const db = {
        queries: [],
        signupReads: [],
        transactionError: null,
      };
      const refFor = (key) => {
        const [signupId, slotId] = key.split("/");
        return {
          id: slotId,
          parent: {parent: {id: signupId}},
          key,
          update: async (fields) => {
            if (!(key in slots)) throw new Error("5 NOT_FOUND");
            applyUpdate(key, fields);
          },
        };
      };
      const applyUpdate = (key, fields) => {
        for (const [field, value] of Object.entries(fields)) {
          const [top, nested] = field.split(".");
          const data = slots[key];
          if (nested === undefined) {
            data[top] = value;
            continue;
          }
          data[top] = {...(data[top] || {})};
          if (value === DELETE) delete data[top][nested];
          else data[top][nested] = value;
        }
      };
      db.collectionGroup = (name) => {
        expect(name).to.equal("slots");
        const query = {name, wheres: []};
        db.queries.push(query);
        const chain = {
          where: (field, op, value) => {
            query.wheres.push([field, op, value.ms]);
            return chain;
          },
          get: async () => ({
            docs: Object.keys(slots)
                .filter((key) => {
                  const start = slots[key].startAt.toMillis();
                  return query.wheres.every(([, op, ms]) =>
                    op === ">" ? start > ms : start <= ms);
                })
                .map((key) => ({
                  id: key.split("/")[1],
                  ref: refFor(key),
                  data: () => copy(slots[key]),
                })),
          }),
        };
        return chain;
      };
      db.collection = (name) => {
        expect(name).to.equal("signups");
        return {
          doc: (id) => ({
            get: async () => {
              db.signupReads.push(id);
              return {
                exists: id in signups,
                data: () => signups[id],
              };
            },
            collection: (sub) => {
              expect(sub).to.equal("entries");
              return {
                where: (field, op, slotId) => {
                  expect([field, op]).to.deep.equal(["slotId", "=="]);
                  return {
                    get: async () => ({
                      docs: (entries[`${id}/${slotId}`] ||
                          [{deviceId: "device1"}])
                          .map((entry) => ({data: () => entry})),
                    }),
                  };
                },
              };
            },
          }),
        };
      };
      db.runTransaction = async (fn) => {
        if (db.transactionError) throw db.transactionError;
        return fn({
          get: async (ref) => ({
            exists: ref.key in slots,
            data: () => copy(slots[ref.key]),
          }),
          update: (ref, fields) => {
            if (!(ref.key in slots)) throw new Error("5 NOT_FOUND");
            applyUpdate(ref.key, fields);
          },
        });
      };
      return db;
    }

    const run = (db, messaging, now = NOW, extra = {}) =>
      reminders.runSignupReminders({
        db, messaging, now, Timestamp, FieldValue, ...extra,
      });

    /**
     * Makes some of the db's transactions fail, numbering them from 1 in the
     * order they are started.
     * @param {Object} db The fake db.
     * @param {number[]} numbers Which transactions to fail.
     * @return {{count: function(): number}} Reads how many were started.
     */
    function failTransactions(db, numbers) {
      const realRun = db.runTransaction;
      let count = 0;
      db.runTransaction = async (fn) => {
        count++;
        if (numbers.includes(count)) throw new Error("firestore blip");
        return realRun(fn);
      };
      return {count: () => count};
    }

    const okMessaging = () => ({send: sinon.stub().resolves("id")});

    /**
     * An error FCM answers with when it refuses a message outright, so
     * nothing was sent.
     * @param {string} code The Firebase Admin SDK error code.
     * @return {Error} The error.
     */
    const rejected = (code = "messaging/invalid-argument") =>
      Object.assign(new Error("rejected"), {code});

    /**
     * An error after which the message may or may not have been delivered.
     * @return {Error} The error.
     */
    const unsure = () =>
      Object.assign(new Error("timed out"), {code: "app/network-timeout"});

    it("sends a due reminder to the slot's topic, and records it", async () => {
      const slots = {"s1/a": slot(HOUR)};
      const db = fakeDb({signups: {s1: published}, slots});
      const messaging = okMessaging();

      const summary = await run(db, messaging);

      expect(messaging.send.calledOnce).to.equal(true);
      const message = messaging.send.firstCall.args[0];
      expect(message.topic).to.equal("signup_slot_s1_a");
      expect(message.notification.title).to.contain("starts in 1 hour");
      expect(slots["s1/a"].reminders).to.deep.equal({hour: NOW + HOUR});
      expect(summary.sent).to.equal(1);
    });

    it("looks only at slots starting within the next 24 hours", async () => {
      const db = fakeDb({signups: {}, slots: {}});

      await run(db, okMessaging());

      expect(db.queries).to.have.length(1);
      expect(db.queries[0].wheres).to.deep.equal([
        ["startAt", ">", NOW],
        ["startAt", "<=", NOW + 24 * HOUR],
      ]);
    });

    it("ignores a slot that has already started", async () => {
      const slots = {"s1/a": slot(-HOUR)};
      const db = fakeDb({signups: {s1: published}, slots});
      const messaging = okMessaging();

      const summary = await run(db, messaging);

      expect(summary.checked).to.equal(0);
      expect(messaging.send.called).to.equal(false);
    });

    it("never sends the same reminder twice for a start time", async () => {
      const slots = {"s1/a": slot(HOUR)};
      const db = fakeDb({signups: {s1: published}, slots});
      const messaging = okMessaging();

      await run(db, messaging);
      await run(db, messaging, NOW + 5 * MINUTE);

      expect(messaging.send.calledOnce).to.equal(true);
    });

    it("sends the day reminder and, later, the hour reminder", async () => {
      const slots = {"s1/a": slot(24 * HOUR)};
      const db = fakeDb({signups: {s1: published}, slots});
      const messaging = okMessaging();

      await run(db, messaging);
      await run(db, messaging, NOW + 23 * HOUR + 10 * MINUTE);

      const titles = messaging.send.getCalls()
          .map((call) => call.args[0].notification.title);
      expect(titles).to.deep.equal([
        "Reminder: Prasad Seva is tomorrow",
        "Reminder: Prasad Seva starts in 1 hour",
      ]);
      expect(slots["s1/a"].reminders).to.deep.equal({
        day: NOW + 24 * HOUR,
        hour: NOW + 24 * HOUR,
      });
    });

    it("sends again when an admin moves the slot", async () => {
      const slots = {"s1/a": slot(HOUR, {reminders: {hour: NOW + 4 * HOUR}})};
      const db = fakeDb({signups: {s1: published}, slots});
      const messaging = okMessaging();

      await run(db, messaging);

      expect(messaging.send.calledOnce).to.equal(true);
      expect(slots["s1/a"].reminders.hour).to.equal(NOW + HOUR);
    });

    describe("a successful send", () => {
      it("is recorded as sent, and its attempt is closed", async () => {
        const slots = {"s1/a": slot(HOUR)};
        const db = fakeDb({signups: {s1: published}, slots});

        await run(db, okMessaging());

        expect(slots["s1/a"].reminders).to.deep.equal({hour: NOW + HOUR});
        expect(slots["s1/a"].reminderAttempts).to.deep.equal({});
      });

      it("records the attempt before it sends", async () => {
        const slots = {"s1/a": slot(HOUR)};
        const db = fakeDb({signups: {s1: published}, slots});
        let during;
        const messaging = {
          send: sinon.stub().callsFake(async () => {
            during = slots["s1/a"].reminderAttempts;
            return "id";
          }),
        };

        await run(db, messaging, NOW);

        expect(during.hour).to.include({start: NOW + HOUR, at: NOW});
        expect(during.hour.id).to.be.a("string").with.length.above(10);
      });

      it("is never sent again, run after run", async () => {
        const slots = {"s1/a": slot(HOUR)};
        const db = fakeDb({signups: {s1: published}, slots});
        const messaging = okMessaging();

        await run(db, messaging);
        await run(db, messaging, NOW + 10 * MINUTE);
        await run(db, messaging, NOW + 20 * MINUTE);

        expect(messaging.send.calledOnce).to.equal(true);
      });

      it("is recorded on a second try if the first write fails", async () => {
        const slots = {"s1/a": slot(HOUR)};
        const db = fakeDb({signups: {s1: published}, slots});
        failTransactions(db, [2]); // 1 begins the attempt, 2 and 3 record
        const messaging = okMessaging();

        const summary = await run(db, messaging);
        await run(db, messaging, NOW + 7 * MINUTE); // past the attempt's life

        expect(summary).to.include({sent: 1, unrecorded: 0, failed: 0});
        expect(messaging.send.calledOnce).to.equal(true);
        expect(slots["s1/a"].reminders).to.deep.equal({hour: NOW + HOUR});
      });

      it("is reported, and sent again after the attempt expires, if it " +
          "can never be recorded", async () => {
        const slots = {"s1/a": slot(HOUR)};
        const db = fakeDb({signups: {s1: published}, slots});
        failTransactions(db, [2, 3]);
        const messaging = okMessaging();

        const summary = await run(db, messaging);

        expect(summary).to.include({sent: 1, unrecorded: 1, failed: 0});
        // Nothing says it was sent, so once the attempt expires it is tried
        // again: the one way a reminder can repeat, and it is logged.
        await run(db, messaging, NOW + 7 * MINUTE);
        expect(messaging.send.calledTwice).to.equal(true);
      });

      it("does not rewind a newer record when the slot has moved since",
          async () => {
            const slots = {"s1/a": slot(HOUR)};
            const db = fakeDb({signups: {s1: published}, slots});
            const messaging = {
              send: sinon.stub().callsFake(async () => {
                // While this run sends, an admin moves the slot and a later
                // run sends and records the reminder for the new time.
                slots["s1/a"] = {
                  ...slots["s1/a"],
                  startAt: ts(NOW + 2 * HOUR),
                  endAt: ts(NOW + 4 * HOUR),
                  reminders: {hour: NOW + 2 * HOUR},
                };
                return "id";
              }),
            };

            const summary = await run(db, messaging);

            expect(slots["s1/a"].reminders)
                .to.deep.equal({hour: NOW + 2 * HOUR});
            expect(summary.unrecorded).to.equal(0);
          });

      it("leaves another run's attempt alone, but still records its own " +
          "send", async () => {
        const slots = {"s1/a": slot(HOUR)};
        const db = fakeDb({signups: {s1: published}, slots});
        const other = {start: NOW + HOUR, at: NOW + 8 * MINUTE, id: "other"};
        const messaging = {
          send: sinon.stub().callsFake(async () => {
            slots["s1/a"] = {...slots["s1/a"], reminderAttempts: {hour: other}};
            return "id";
          }),
        };

        await run(db, messaging);

        expect(slots["s1/a"].reminders).to.deep.equal({hour: NOW + HOUR});
        expect(slots["s1/a"].reminderAttempts).to.deep.equal({hour: other});
      });

      it("is not an error when the slot was deleted while sending",
          async () => {
            const slots = {"s1/a": slot(HOUR)};
            const db = fakeDb({signups: {s1: published}, slots});
            const transactions = failTransactions(db, []);
            const messaging = {
              send: sinon.stub().callsFake(async () => {
                delete slots["s1/a"];
                return "id";
              }),
            };

            const summary = await run(db, messaging);

            expect(summary).to.include({sent: 1, unrecorded: 0, failed: 0});
            expect(transactions.count()).to.equal(2); // no pointless retry
          });
    });

    describe("a failed send", () => {
      const failures = {
        "a message FCM refused": () => rejected(),
        "a timeout, where delivery is unknown": () => unsure(),
        "an error with no code": () => new Error("boom"),
      };

      for (const [name, makeError] of Object.entries(failures)) {
        it(`is tried again on the next run: ${name}`, async () => {
          const slots = {"s1/a": slot(HOUR)};
          const db = fakeDb({signups: {s1: published}, slots});
          const messaging = {send: sinon.stub().rejects(makeError())};

          const summary = await run(db, messaging);

          expect(summary.failed).to.equal(1);
          expect(slots["s1/a"].reminders).to.equal(undefined);
          expect(slots["s1/a"].reminderAttempts).to.deep.equal({});
          messaging.send = sinon.stub().resolves("id");
          await run(db, messaging, NOW + 10 * MINUTE);
          expect(messaging.send.calledOnce).to.equal(true);
          expect(slots["s1/a"].reminders).to.deep.equal({hour: NOW + HOUR});
        });
      }

      it("gives up on a send that hangs, and still reminds the other slots",
          async () => {
            const slots = {"s1/a": slot(HOUR), "s1/b": slot(HOUR - MINUTE)};
            const db = fakeDb({signups: {s1: published}, slots});
            const messaging = {
              send: sinon.stub()
                  .onFirstCall().returns(new Promise(() => {}))
                  .onSecondCall().resolves("id"),
            };

            const summary = await run(db, messaging, NOW, {sendTimeout: 20});

            expect(summary).to.include({sent: 1, failed: 1});
            expect(slots["s1/a"].reminderAttempts).to.deep.equal({});
            expect(slots["s1/b"].reminders)
                .to.deep.equal({hour: NOW + HOUR - MINUTE});
          });

      it("leaves a newer attempt alone if the slot has moved since",
          async () => {
            const slots = {"s1/a": slot(HOUR)};
            const db = fakeDb({signups: {s1: published}, slots});
            const messaging = {
              send: sinon.stub().callsFake(async () => {
                // While the send is failing an admin moves the slot, and a
                // later run starts an attempt for the new time.
                slots["s1/a"] = {
                  ...slots["s1/a"],
                  reminderAttempts: {
                    hour: {start: NOW + 2 * HOUR, at: NOW + MINUTE},
                  },
                };
                throw rejected();
              }),
            };

            await run(db, messaging);

            expect(slots["s1/a"].reminderAttempts).to.deep.equal({
              hour: {start: NOW + 2 * HOUR, at: NOW + MINUTE},
            });
          });

      it("is not undone for a slot deleted meanwhile, and not retried",
          async () => {
            const slots = {"s1/a": slot(HOUR)};
            const db = fakeDb({signups: {s1: published}, slots});
            const realRun = db.runTransaction;
            let calls = 0;
            db.runTransaction = async (fn) => {
              calls++;
              return realRun(fn);
            };
            const messaging = {
              send: sinon.stub().callsFake(async () => {
                delete slots["s1/a"];
                throw rejected();
              }),
            };

            const summary = await run(db, messaging);

            expect(calls).to.equal(2); // the attempt, and one give-up
            expect(summary.failed).to.equal(1); // the send itself failed
          });

      it("leaves an attempt that another run took over for the same start",
          async () => {
            const slots = {"s1/a": slot(HOUR)};
            const db = fakeDb({signups: {s1: published}, slots});
            const takenOver = {hour: {start: NOW + HOUR, at: NOW + 8 * MINUTE}};
            const messaging = {
              send: sinon.stub().callsFake(async () => {
                // This run is slow; a later run has taken the reminder over.
                slots["s1/a"] = {...slots["s1/a"], reminderAttempts: takenOver};
                throw unsure();
              }),
            };

            await run(db, messaging);

            expect(slots["s1/a"].reminderAttempts).to.deep.equal(takenOver);
          });

      it("gives its attempt up on a second try if the first fails",
          async () => {
            const slots = {"s1/a": slot(HOUR)};
            const db = fakeDb({signups: {s1: published}, slots});
            const realRun = db.runTransaction;
            let calls = 0;
            db.runTransaction = async (fn) => {
              calls++;
              // 1: the attempt. 2: the first give-up, which fails.
              if (calls === 2) throw new Error("firestore blip");
              return realRun(fn);
            };
            const messaging = {send: sinon.stub().rejects(unsure())};

            await run(db, messaging);

            expect(calls).to.equal(3);
            expect(slots["s1/a"].reminderAttempts).to.deep.equal({});
          });

      it("is tried again once its attempt expires, if it cannot be given up",
          async () => {
            const slots = {"s1/a": slot(HOUR)};
            const db = fakeDb({signups: {s1: published}, slots});
            const realRun = db.runTransaction;
            let calls = 0;
            db.runTransaction = async (fn) => {
              calls++;
              if (calls > 1 && calls < 4) throw new Error("firestore down");
              return realRun(fn);
            };
            const messaging = {send: sinon.stub().rejects(unsure())};

            const summary = await run(db, messaging);
            messaging.send = sinon.stub().resolves("id");
            await run(db, messaging, NOW + 3 * MINUTE); // attempt still fresh
            expect(messaging.send.called).to.equal(false);
            await run(db, messaging, NOW + 10 * MINUTE); // attempt expired

            expect(summary.failed).to.equal(1);
            expect(messaging.send.calledOnce).to.equal(true);
          });
    });

    describe("while another run is sending", () => {
      const start = NOW + HOUR;

      it("waits for a recent attempt rather than send at the same time",
          async () => {
            const slots = {
              "s1/a": slot(HOUR, {
                reminderAttempts: {hour: {start, at: NOW - MINUTE}},
              }),
            };
            const messaging = okMessaging();

            await run(fakeDb({signups: {s1: published}, slots}), messaging);

            expect(messaging.send.called).to.equal(false);
          });

      it("still waits for an attempt that is almost as old as the function " +
          "may run (5 minutes)", async () => {
        const slots = {
          "s1/a": slot(HOUR, {
            reminderAttempts: {hour: {start, at: NOW - 5.5 * MINUTE}},
          }),
        };
        const messaging = okMessaging();

        await run(fakeDb({signups: {s1: published}, slots}), messaging);

        expect(messaging.send.called).to.equal(false);
      });

      it("takes over a dead attempt in time for the very next run (10 " +
          "minutes on)", async () => {
        const slots = {
          "s1/a": slot(HOUR, {
            reminderAttempts: {hour: {start, at: NOW - 9.5 * MINUTE}},
          }),
        };
        const messaging = okMessaging();

        await run(fakeDb({signups: {s1: published}, slots}), messaging);

        expect(messaging.send.calledOnce).to.equal(true);
      });

      it("treats an attempt as dead from exactly 6 minutes old", async () => {
        const make = (age) => ({
          "s1/a": slot(HOUR, {
            reminderAttempts: {hour: {start, at: NOW - age}},
          }),
        });
        const early = okMessaging();
        const exact = okMessaging();

        const db = (slots) => fakeDb({signups: {s1: published}, slots});
        await run(db(make(6 * MINUTE - 1)), early);
        await run(db(make(6 * MINUTE)), exact);

        expect(early.send.called).to.equal(false);
        expect(exact.send.calledOnce).to.equal(true);
      });

      it("takes over an attempt whose run died", async () => {
        const slots = {
          "s1/a": slot(HOUR, {
            reminderAttempts: {hour: {start, at: NOW - 7 * MINUTE}},
          }),
        };
        const messaging = okMessaging();

        await run(fakeDb({signups: {s1: published}, slots}), messaging);

        expect(messaging.send.calledOnce).to.equal(true);
        expect(slots["s1/a"].reminders).to.deep.equal({hour: start});
      });

      it("ignores an attempt made for another start time", async () => {
        const slots = {
          "s1/a": slot(HOUR, {
            reminderAttempts: {hour: {start: start + 5 * HOUR, at: NOW}},
          }),
        };
        const messaging = okMessaging();

        await run(fakeDb({signups: {s1: published}, slots}), messaging);

        expect(messaging.send.calledOnce).to.equal(true);
      });

      it("sends once when two runs start at the same moment", async () => {
        const slots = {"s1/a": slot(HOUR)};
        const db = fakeDb({signups: {s1: published}, slots});
        // Firestore transactions that touch the same document take turns.
        const realRun = db.runTransaction;
        let turn = Promise.resolve();
        db.runTransaction = (fn) => {
          const mine = turn.then(() => realRun(fn));
          turn = mine.catch(() => {});
          return mine;
        };
        const messaging = okMessaging();

        await Promise.all([run(db, messaging), run(db, messaging)]);

        expect(messaging.send.calledOnce).to.equal(true);
      });
    });

    describe("across a whole day of runs every 10 minutes", () => {
      // A new slot each time: the fake store changes what it is given.
      const thursdaySlot = () => slot(0, {
        startAt: ts(Date.parse("2026-10-10T16:00:00Z")),
        endAt: ts(Date.parse("2026-10-10T18:00:00Z")),
      });
      const START = Date.parse("2026-10-10T16:00:00Z");
      const titles = (messaging) => messaging.send.getCalls()
          .map((call) => call.args[0].notification.title);

      /**
       * Runs the schedule every 10 minutes across a slot's last 26 hours.
       * @param {Object} data The slot.
       * @param {Object} messaging What sends.
       * @return {Promise<Object>} The slots store.
       */
      async function everyTenMinutes(data, messaging) {
        const slots = {"s1/a": data};
        const db = fakeDb({signups: {s1: published}, slots});
        const start = data.startAt.toMillis();
        for (let t = start - 26 * HOUR; t <= start + HOUR; t += 10 * MINUTE) {
          await run(db, messaging, t);
        }
        return slots;
      }

      it("sends each reminder exactly once", async () => {
        const messaging = okMessaging();

        await everyTenMinutes(thursdaySlot(), messaging);

        expect(titles(messaging)).to.deep.equal([
          "Reminder: Prasad Seva is tomorrow",
          "Reminder: Prasad Seva starts in 1 hour",
        ]);
      });

      it("sends an all-day slot's reminder exactly once", async () => {
        const midnight = Date.parse("2026-10-10T07:00:00Z");
        const messaging = okMessaging();

        await everyTenMinutes(slot(0, {
          startAt: ts(midnight),
          endAt: ts(midnight + 24 * HOUR - MINUTE),
        }), messaging);

        expect(messaging.send.calledOnce).to.equal(true);
      });

      it("keeps trying a failing reminder, and sends it once it works",
          async () => {
            // The first two sends fail (one unclear, one refused); after
            // that FCM works again.
            const messaging = {
              send: sinon.stub()
                  .onCall(0).rejects(unsure())
                  .onCall(1).rejects(rejected())
                  .resolves("id"),
            };

            const slots = await everyTenMinutes(thursdaySlot(), messaging);

            // 2 failures + 1 success for the day reminder, 1 for the hour.
            expect(messaging.send.callCount).to.equal(4);
            expect(slots["s1/a"].reminders).to.deep.equal({
              day: START,
              hour: START,
            });
          });

      it("retries a reminder whose run died mid-send, once, after the " +
          "attempt expires", async () => {
        // A run records its attempt and then dies: nothing is sent or
        // recorded as sent.
        const start = START;
        const slots = {
          "s1/a": {
            ...thursdaySlot(),
            reminderAttempts: {day: {start, at: start - 24 * HOUR + MINUTE}},
          },
        };
        const db = fakeDb({signups: {s1: published}, slots});
        const messaging = okMessaging();

        for (let t = start - 24 * HOUR + 10 * MINUTE;
          t < start - 22 * HOUR; t += 10 * MINUTE) {
          await run(db, messaging, t);
        }

        expect(titles(messaging))
            .to.deep.equal(["Reminder: Prasad Seva is tomorrow"]);
      });
    });

    it("carries on with the other slots after one fails", async () => {
      const slots = {"s1/a": slot(HOUR), "s1/b": slot(HOUR - MINUTE)};
      const db = fakeDb({signups: {s1: published}, slots});
      const messaging = {
        send: sinon.stub()
            .onFirstCall().rejects(new Error("fcm down"))
            .onSecondCall().resolves("id"),
      };

      const summary = await run(db, messaging);

      expect(messaging.send.calledTwice).to.equal(true);
      expect(summary).to.include({sent: 1, failed: 1});
    });

    it("does not send for a slot edited since it was read", async () => {
      const slots = {"s1/a": slot(HOUR)};
      const db = fakeDb({signups: {s1: published}, slots});
      const realRun = db.runTransaction;
      db.runTransaction = async (fn) => {
        // An admin moves the slot between the query and the claim.
        slots["s1/a"] = {...slots["s1/a"], startAt: ts(NOW + 10 * HOUR)};
        return realRun(fn);
      };
      const messaging = okMessaging();

      await run(db, messaging);

      expect(messaging.send.called).to.equal(false);
      expect(slots["s1/a"].reminders).to.equal(undefined);
    });

    it("does not send what another run has just recorded", async () => {
      const slots = {"s1/a": slot(HOUR)};
      const db = fakeDb({signups: {s1: published}, slots});
      const realRun = db.runTransaction;
      db.runTransaction = async (fn) => {
        // Another run sends this reminder between the query and the claim.
        slots["s1/a"] = {...slots["s1/a"], reminders: {hour: NOW + HOUR}};
        return realRun(fn);
      };
      const messaging = okMessaging();

      await run(db, messaging);

      expect(messaging.send.called).to.equal(false);
    });

    it("does not send for a slot deleted since it was read", async () => {
      const slots = {"s1/a": slot(HOUR)};
      const db = fakeDb({signups: {s1: published}, slots});
      const realRun = db.runTransaction;
      db.runTransaction = async (fn) => {
        delete slots["s1/a"];
        return realRun(fn);
      };
      const messaging = okMessaging();

      const summary = await run(db, messaging);

      expect(messaging.send.called).to.equal(false);
      expect(summary).to.include({sent: 0, failed: 0}); // not an error
    });

    describe("skips a due slot", () => {
      const skipped = async ({signups, slots, entries}) => {
        const key = Object.keys(slots)[0];
        const db = fakeDb({signups, slots, entries});
        const messaging = okMessaging();
        const summary = await run(db, messaging);
        expect(messaging.send.called).to.equal(false);
        expect(summary).to.include({sent: 0, failed: 0});
        expect(slots[key].reminders).to.equal(undefined);
        return db;
      };

      it("of a draft sign-up", async () => {
        await skipped({
          signups: {s1: {...published, status: "draft"}},
          slots: {"s1/a": slot(HOUR)},
        });
      });

      it("of a sign-up that no longer exists", async () => {
        await skipped({signups: {}, slots: {"s1/a": slot(HOUR)}});
      });

      it("with no entries at all", async () => {
        await skipped({
          signups: {s1: published},
          slots: {"s1/a": slot(HOUR, {claimedCount: 5})},
          entries: {"s1/a": []},
        });
      });

      it("whose entries are not linked to any device", async () => {
        await skipped({
          signups: {s1: published},
          slots: {"s1/a": slot(HOUR)},
          entries: {"s1/a": [{name: "Asha"}, {deviceId: null}, {deviceId: ""}]},
        });
      });

      it("whose slot id cannot be part of a topic name", async () => {
        await skipped({
          signups: {s1: published},
          slots: {"s1/a b": slot(HOUR)},
        });
      });
    });

    it("sends for a slot whose counter was driven to 0 but has entries",
        async () => {
          // The rules let anyone nudge claimedCount by one per write, so it
          // cannot be what decides whether anyone is signed up.
          const slots = {"s1/a": slot(HOUR, {claimedCount: 0})};
          const db = fakeDb({signups: {s1: published}, slots});
          const messaging = okMessaging();

          await run(db, messaging);

          expect(messaging.send.calledOnce).to.equal(true);
        });

    it("sends when just one of the entries is linked to a device", async () => {
      const slots = {"s1/a": slot(HOUR)};
      const db = fakeDb({
        signups: {s1: published},
        slots,
        entries: {"s1/a": [{name: "Asha"}, {deviceId: "device9"}]},
      });
      const messaging = okMessaging();

      await run(db, messaging);

      expect(messaging.send.calledOnce).to.equal(true);
    });

    it("reads a sign-up only for a slot that is due, and only once",
        async () => {
          const slots = {
            "s1/a": slot(HOUR),
            "s1/b": slot(HOUR - MINUTE),
            "s2/c": slot(5 * HOUR),
          };
          const db = fakeDb({signups: {s1: published, s2: published}, slots});

          await run(db, okMessaging());

          expect(db.signupReads).to.deep.equal(["s1"]);
        });

    it("counts a transaction error as a failure and carries on", async () => {
      const slots = {"s1/a": slot(HOUR)};
      const db = fakeDb({signups: {s1: published}, slots});
      db.transactionError = new Error("contention");
      const messaging = okMessaging();

      const summary = await run(db, messaging);

      expect(messaging.send.called).to.equal(false);
      expect(summary.failed).to.equal(1);
    });
  });

  describe("sendSignupReminders", () => {
    it("is exported as a function that runs every 10 minutes", () => {
      const index = require("../index.js");

      expect(index.sendSignupReminders).to.be.a("function");
      expect(index.sendSignupReminders.__endpoint.scheduleTrigger.schedule)
          .to.equal("every 10 minutes");
    });

    it("runs one instance at a time", () => {
      const index = require("../index.js");

      expect(index.sendSignupReminders.__endpoint.maxInstances).to.equal(1);
    });

    it("is never retried by the platform, which could repeat a send", () => {
      const index = require("../index.js");

      const trigger = index.sendSignupReminders.__endpoint.scheduleTrigger;
      expect(trigger.retryConfig.retryCount).to.equal(0);
    });

    it("runs against the real Firestore and messaging services", async () => {
      const start = Date.now() + HOUR;
      const slotData = slot(0, {
        startAt: ts(start),
        endAt: ts(start + 2 * HOUR),
      });
      const updates = [];
      const ref = {
        parent: {parent: {id: "s1"}},
        update: async (fields) => updates.push(fields),
      };
      const slotDoc = {id: "a", ref, data: () => slotData};
      const db = {
        collectionGroup: () => ({
          where: () => ({
            where: () => ({get: async () => ({docs: [slotDoc]})}),
          }),
        }),
        collection: () => ({
          doc: () => ({
            get: async () => ({exists: true, data: () => published}),
            collection: () => ({
              where: () => ({
                get: async () => ({docs: [{data: () => ({deviceId: "d1"})}]}),
              }),
            }),
          }),
        }),
        runTransaction: async (fn) => fn({
          get: async () => ({
            exists: true,
            // What the slot holds once the attempt has been recorded.
            data: () => ({
              ...slotData,
              reminderAttempts: updates.length === 0 ?
                undefined :
                {hour: updates[0]["reminderAttempts.hour"]},
            }),
          }),
          update: (docRef, fields) => updates.push(fields),
        }),
      };
      const send = sinon.stub().resolves("id");
      // admin.firestore() and admin.messaging() both go through admin.app().
      if (admin.app.restore) admin.app.restore();
      const appStub = sinon.stub(admin, "app").returns({
        firestore: () => db,
        messaging: () => ({send}),
      });

      try {
        await require("../index.js").sendSignupReminders.run({});
      } finally {
        appStub.restore();
      }

      expect(send.calledOnce).to.equal(true);
      expect(send.firstCall.args[0].topic).to.equal("signup_slot_s1_a");
      // The attempt is recorded before the send, then the send is recorded.
      expect(updates).to.have.length(2);
      expect(Object.keys(updates[0])).to.deep.equal(["reminderAttempts.hour"]);
      expect(updates[0]["reminderAttempts.hour"].start).to.equal(start);
      expect(updates[1]["reminders.hour"]).to.equal(start);
      // ...and the attempt is closed with Firestore's real delete marker.
      expect(updates[1]["reminderAttempts.hour"].isEqual(
          admin.firestore.FieldValue.delete())).to.equal(true);
    });
  });
});

const {onCall, HttpsError} = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const logger = require("firebase-functions/logger");

const MIN_PHONE_DIGITS = 8;
const MAX_PHONE_LENGTH = 40;
const MAX_ID_LENGTH = 128;
const MAX_DEVICE_ID_LENGTH = 200;
const MAX_JOIN_CODE_LENGTH = 100;

// Every claim reads one sign-up's whole entries collection inside a
// transaction, so cap how many run at once.
const MAX_INSTANCES = 10;

/**
 * A phone number reduced to its digits (country code then number, no plus),
 * so "+1 (425) 555-1234", "+14255551234" and "14255551234" all compare equal.
 * Country code and number must then match exactly: "4255551234" is a
 * different number.
 * @param {*} value The stored or typed phone number.
 * @return {string} The digits, or "" if value is not text.
 */
function normalizePhone(value) {
  if (typeof value !== "string") return "";
  return value.replace(/\D/g, "");
}

/**
 * Whether the join code lets a claim through: always, unless the sign-up
 * requires one and it is missing or wrong.
 * @param {Object} signup The sign-up document's data.
 * @param {*} joinCode The code the devotee typed.
 * @return {boolean} True if the claim may go ahead.
 */
function joinCodeAccepted(signup, joinCode) {
  if (!signup.requiresJoinCode) return true;
  return typeof joinCode === "string" && joinCode !== "" &&
      joinCode === signup.joinCode;
}

/**
 * Decides what a claim does, without touching Firestore.
 * @param {Object} args The claim.
 * @param {Object} args.signup The sign-up document's data.
 * @param {Array<{id: string, data: Object}>} args.entries Its entries.
 * @param {string} args.phone The phone the devotee typed.
 * @param {string} args.deviceId The claiming device.
 * @param {*} args.joinCode The join code the devotee typed, if any.
 * @return {Object} {status: "INVALID_JOIN_CODE" | "NOT_FOUND" |
 *   "ALREADY_CLAIMED"}, or {status: "SUCCESS", count, entryIds} where
 *   entryIds are the entries that still need their deviceId set.
 */
function planClaim({signup, entries, phone, deviceId, joinCode}) {
  if (!joinCodeAccepted(signup, joinCode)) {
    return {status: "INVALID_JOIN_CODE"};
  }

  const wanted = normalizePhone(phone);
  const matches = wanted === "" ? [] :
    entries.filter((entry) => normalizePhone(entry.data.phone) === wanted);
  if (matches.length === 0) return {status: "NOT_FOUND"};

  // All or nothing: one entry held by someone else refuses the whole claim.
  const taken = matches.some(
      (entry) => entry.data.deviceId && entry.data.deviceId !== deviceId);
  if (taken) return {status: "ALREADY_CLAIMED"};

  return {
    status: "SUCCESS",
    count: matches.length,
    entryIds: matches
        .filter((entry) => entry.data.deviceId !== deviceId)
        .map((entry) => entry.id),
  };
}

/**
 * @param {*} value The value to check.
 * @param {number} maxLength The longest allowed length.
 * @return {boolean} True for a non-empty string within the limit.
 */
function isText(value, maxLength) {
  return typeof value === "string" && value.length > 0 &&
      value.length <= maxLength;
}

/**
 * Throws invalid-argument unless the request carries what a claim needs.
 * @param {Object} data The callable's request data.
 */
function validateClaimRequest(data) {
  const {signupId, phone, deviceId, joinCode} = data || {};
  const phoneDigits = typeof phone === "string" ?
    phone.replace(/\D/g, "").length : 0;
  const valid = isText(signupId, MAX_ID_LENGTH) && !signupId.includes("/") &&
      isText(phone, MAX_PHONE_LENGTH) && phoneDigits >= MIN_PHONE_DIGITS &&
      isText(deviceId, MAX_DEVICE_ID_LENGTH) &&
      (joinCode === undefined || joinCode === null ||
        (typeof joinCode === "string" &&
          joinCode.length <= MAX_JOIN_CODE_LENGTH));
  if (!valid) {
    throw new HttpsError("invalid-argument", "Missing or invalid fields.");
  }
}

/**
 * A devotee linking the entries made with their phone number to this device
 * ("Claim my sign up"). Entries are found by an exact phone match. If the
 * sign-up needs a join code it must be right. If any matching entry already
 * belongs to another device, nothing changes (ALREADY_CLAIMED) - an admin can
 * release an entry first. Runs in a transaction so two devices claiming the
 * same number at once can't both win.
 *
 * Note: sign-ups and their entries (join code, phones, device ids) are
 * publicly readable by the Firestore rules, so neither the join code nor the
 * phone number is a secret; they are friction, as everywhere else in the app.
 */
exports.claimSignupEntries = onCall({maxInstances: MAX_INSTANCES},
    (request) => claimSignupEntries(request.data));

/**
 * @param {Object} data The callable's request data.
 * @return {Promise<Object>} {status, count?} - see planClaim.
 */
async function claimSignupEntries(data) {
  validateClaimRequest(data);
  const {signupId, phone, deviceId, joinCode} = data;

  try {
    const db = admin.firestore();
    const signupRef = db.collection("signups").doc(signupId);
    const entriesRef = signupRef.collection("entries");

    const result = await db.runTransaction(async (transaction) => {
      const signupSnapshot = await transaction.get(signupRef);
      if (!signupSnapshot.exists) return {status: "NOT_FOUND"};
      const signup = signupSnapshot.data();
      if (!joinCodeAccepted(signup, joinCode)) {
        return {status: "INVALID_JOIN_CODE"};
      }

      const entriesSnapshot = await transaction.get(entriesRef);
      const entries = entriesSnapshot.docs.map(
          (doc) => ({id: doc.id, ref: doc.ref, data: doc.data()}));
      const plan = planClaim({signup, entries, phone, deviceId, joinCode});
      if (plan.status !== "SUCCESS") return {status: plan.status};

      const claimedAt = admin.firestore.FieldValue.serverTimestamp();
      for (const entry of entries) {
        if (plan.entryIds.includes(entry.id)) {
          transaction.update(entry.ref, {deviceId, claimedAt});
        }
      }
      return {status: "SUCCESS", count: plan.count};
    });
    logger.info(`Claim on ${signupId}: ${result.status}`);
    return result;
  } catch (error) {
    logger.error("Error in claimSignupEntries", error);
    throw new HttpsError("internal", "Could not claim entries.");
  }
}

exports.normalizePhone = normalizePhone;
exports.planClaim = planClaim;

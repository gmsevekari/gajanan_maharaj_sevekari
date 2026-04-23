const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");
const logger = require("firebase-functions/logger");
const { DateTime } = require("luxon");

/**
 * Auto-transition Group Namjap statuses based on dates
 */
exports.updateNamjapStatuses = onSchedule("0 * * * *", async (event) => {
  const db = admin.firestore();

  logger.info("Running Group Namjap status update.");

  const namjapRef = db.collection("group_namjap_events");

  // 1. Enrolling -> Ongoing (On start date)
  const enrollingQuery = await namjapRef.where("status", "==", "enrolling").get();
  for (const doc of enrollingQuery.docs) {
    const data = doc.data();
    if (!data.startDate) continue;

    const timezone = data.timezone || "America/Los_Angeles";
    const nowLocal = DateTime.now().setZone(timezone);
    const todayLocal = nowLocal.startOf("day");

    const startDate = DateTime.fromJSDate(data.startDate.toDate())
      .setZone(timezone)
      .startOf("day");

    if (todayLocal >= startDate) {
      await doc.ref.update({ status: "ongoing" });
      logger.info(`Auto-transitioned Namjap ${doc.id} to ongoing (TZ: ${timezone}, Time: ${nowLocal.toISO()}).`);
    }
  }

  // 2. Ongoing -> Completed (After end date)
  const ongoingQuery = await namjapRef.where("status", "==", "ongoing").get();
  for (const doc of ongoingQuery.docs) {
    const data = doc.data();
    if (!data.endDate) continue;

    const timezone = data.timezone || "America/Los_Angeles";
    const nowLocal = DateTime.now().setZone(timezone);
    const todayLocal = nowLocal.startOf("day");

    const endDate = DateTime.fromJSDate(data.endDate.toDate())
      .setZone(timezone)
      .startOf("day");

    if (todayLocal > endDate) {
      await doc.ref.update({ status: "completed" });
      logger.info(`Auto-transitioned Namjap ${doc.id} to completed (TZ: ${timezone}, Time: ${nowLocal.toISO()}).`);
    }
  }
});

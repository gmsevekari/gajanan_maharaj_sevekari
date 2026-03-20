const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
const logger = require("firebase-functions/logger");

admin.initializeApp();

exports.sendTempleNotification = onDocumentCreated(
  "notifications/{notificationId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      logger.error("No data associated with the event.");
      return;
    }

    const data = snapshot.data();

    // We only care about Temple Notifications for this trigger
    if (data.type !== "TEMPLE_NOTIFICATION") {
      logger.info("Ignoring non-temple notification type:", data.type);
      return;
    }

    const title = data.title || "Temple Notification";
    const body = data.body || "";

    const message = {
      // Cross-platform notification — displayed by the OS on both platforms.
      notification: {
        title: title,
        body: body,
      },
      // Extra data the app can read when the notification is tapped.
      data: {
        type: "TEMPLE_NOTIFICATION",
        notification_id: event.params.notificationId,
      },
      // Android: high-priority channel.
      android: {
        priority: "high",
        notification: {
          channelId: "temple_notifications",
          priority: "high",
          defaultSound: true,
        },
      },
      // iOS: plain alert banner.
      apns: {
        headers: {
          "apns-push-type": "alert",
          "apns-priority": "10",
        },
        payload: {
          aps: {
            alert: {
              title: title,
              body: body,
            },
            sound: "default",
            badge: 1,
          },
        },
      },
      topic: "temple_notifications",
    };

    logger.info("Sending FCM message:", JSON.stringify(message));

    try {
      const response = await admin.messaging().send(message);
      logger.info("Successfully sent Temple Notification. Response ID:", response);
    } catch (error) {
      logger.error("Error sending Temple Notification:", error);
    }
  },
);
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { DateTime } = require("luxon");

exports.updateParayanStatuses = onSchedule("0 * * * *", async (event) => {
  const db = admin.firestore();

  // Current time in Seattle
  const nowSeattle = DateTime.now().setZone("America/Los_Angeles");
  const todaySeattle = nowSeattle.startOf("day");
  const currentHour = nowSeattle.hour;

  logger.info(`Running Parayan status update. Seattle: ${nowSeattle.toISO()}`);

  const parayansRef = db.collection("parayan_events");

  // 1. Enrolling -> Allocated (6 PM the day BEFORE start date)
  const enrollingQuery = await parayansRef.where("status", "==", "enrolling").get();
  for (const doc of enrollingQuery.docs) {
    const data = doc.data();
    const startDate = DateTime.fromJSDate(data.startDate.toDate()).setZone("America/Los_Angeles").startOf("day");
    const dayBeforeStart = startDate.minus({ days: 1 });

    // If today is exactly the day before AND it's 6 PM (18:00) or later
    if (todaySeattle.equals(dayBeforeStart) && currentHour >= 18) {
      await doc.ref.update({ status: "allocated" });
      logger.info(`Auto-transitioned Parayan ${doc.id} to allocated (6 PM rule).`);
    }
  }

  // 2. Allocated -> Ongoing (On start date)
  const allocatedQuery = await parayansRef.where("status", "==", "allocated").get();
  for (const doc of allocatedQuery.docs) {
    const data = doc.data();
    const startDate = DateTime.fromJSDate(data.startDate.toDate()).setZone("America/Los_Angeles").startOf("day");

    if (todaySeattle >= startDate) {
      await doc.ref.update({ status: "ongoing" });
      logger.info(`Auto-transitioned Parayan ${doc.id} to ongoing (Start Date reached).`);
    }
  }

  // 3. Ongoing -> Completed (After end date)
  const ongoingQuery = await parayansRef.where("status", "==", "ongoing").get();
  for (const doc of ongoingQuery.docs) {
    const data = doc.data();
    const endDate = DateTime.fromJSDate(data.endDate.toDate()).setZone("America/Los_Angeles").startOf("day");

    if (todaySeattle > endDate) {
      await doc.ref.update({ status: "completed" });
      logger.info(`Auto-transitioned Parayan ${doc.id} to completed (End Date passed).`);
    }
  }
});

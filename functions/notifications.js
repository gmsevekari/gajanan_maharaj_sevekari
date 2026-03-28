const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");
const logger = require("firebase-functions/logger");
const { DateTime } = require("luxon");

/**
 * Handle general temple notifications via FCM topic
 */
exports.sendTempleNotification = onDocumentCreated(
  "notifications/{notificationId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      logger.error("No data associated with the event.");
      return;
    }

    const data = snapshot.data();
    if (data.type !== "TEMPLE_NOTIFICATION") {
      logger.info("Ignoring non-temple notification type:", data.type);
      return;
    }

    const title = data.title || "Temple Notification";
    const body = data.body || "";

    const message = {
      notification: { title, body },
      data: {
        type: "TEMPLE_NOTIFICATION",
        notification_id: event.params.notificationId,
      },
      android: {
        priority: "high",
        notification: {
          channelId: "temple_notifications",
          priority: "high",
          defaultSound: true,
        },
      },
      apns: {
        headers: {
          "apns-push-type": "alert",
          "apns-priority": "10",
        },
        payload: {
          aps: {
            alert: { title, body },
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

/**
 * Handle timed Parayan reminders
 */
exports.sendParayanReminders = onSchedule("0 * * * *", async (event) => {
  const db = admin.firestore();
  const nowSeattle = DateTime.now().setZone("America/Los_Angeles");
  const todaySeattle = nowSeattle.startOf("day");
  const currentHourString = nowSeattle.toFormat("HH:00");

  logger.info(`Running Parayan reminders check. Seattle: ${nowSeattle.toISO()}`);

  const ongoingQuery = await db.collection("parayan_events")
    .where("status", "==", "ongoing")
    .get();

  for (const doc of ongoingQuery.docs) {
    const data = doc.data();
    const reminderTimes = data.reminderTimes || [];
    if (!reminderTimes.includes(currentHourString)) continue;

    const startDate = DateTime.fromJSDate(data.startDate.toDate())
      .setZone("America/Los_Angeles")
      .startOf("day");

    const diffInDays = todaySeattle.diff(startDate, "days").days;
    const currentDay = Math.floor(diffInDays) + 1;

    if (currentDay < 1) continue;
    if (data.type === "oneDay" || data.type === "guruPushya") {
      if (currentDay !== 1) continue;
    } else if (data.type === "threeDay") {
      if (currentDay > 3) continue;
    }

    const topic = `parayan_${doc.id}_day${currentDay}`;
    const title = "Parayan Reminder";
    const eventName = data.title_en || data.title || "Parayan";
    const body = `Reminder for ${eventName}. Please read your assigned adhyays for Day ${currentDay}.`;

    const message = {
      notification: { title, body },
      data: {
        type: "PARAYAN_REMINDER",
        event_id: doc.id,
      },
      android: {
        priority: "high",
        notification: {
          channelId: "parayan_notifications",
          priority: "high",
          defaultSound: true,
        },
      },
      apns: {
        headers: {
          "apns-push-type": "alert",
          "apns-priority": "10",
        },
        payload: {
          aps: {
            alert: { title, body },
            sound: "default",
          },
        },
      },
      topic,
    };

    logger.info(`Sending reminder to topic: ${topic}`);

    try {
      await db.collection("notifications").add({
        title,
        body,
        timestamp: nowSeattle.toISO(),
        expires_at: admin.firestore.Timestamp.fromDate(
          nowSeattle.plus({ days: 2 }).toJSDate(),
        ),
        type: "PARAYAN_REMINDER",
        eventId: doc.id,
        day: currentDay,
      });

      await admin.messaging().send(message);

      const sentKey = `sentReminders.day${currentDay}_${currentHourString}`;
      await doc.ref.update({
        [sentKey]: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (error) {
      logger.error(`Error sending reminder for event ${doc.id}:`, error);
    }
  }
});

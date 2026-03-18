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

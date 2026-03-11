const {onDocumentCreated} = require("firebase-functions/v2/firestore");
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

      // Construct the FCM Payload (Data-Only for background reliability)
      // Note: In Data-only messages, all values must be strings.
      const payload = {
        data: {
          title: String(title),
          body: String(body),
          type: "TEMPLE_NOTIFICATION",
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        android: {
          priority: "high",
        },
        topic: "temple_notifications",
      };

      logger.info("Attempting to send FCM payload:", payload);

      try {
        const response = await admin.messaging().send(payload);
        logger.info("Successfully sent Temple Notification. Response ID:", response);
      } catch (error) {
        logger.error("Error sending Temple Notification:", error);
      }
    },
);

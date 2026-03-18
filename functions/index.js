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

    // Use explicit link/url field first, then fall back to extracting a URL
    // embedded in the body text (e.g. "Jai Gajanan https://tinyurl.com/...")
    let link = data.link || data.url || null;
    if (!link) {
      const urlMatch = body.match(/https?:\/\/[^\s]+/i);
      if (urlMatch) link = urlMatch[0];
    }
    // Treat empty string as no link
    if (!link || link.trim() === "") link = null;

    if (link) logger.info(`Detected link in notification: ${link}`);

    const message = {
      // Cross-platform notification — displayed by the OS on both platforms.
      // Android overrides with its own block below for channel config.
      // iOS uses the APNS block below for a plain banner (no action buttons).
      notification: {
        title: title,
        body: body,
      },
      // Extra data the app can read when the notification is tapped.
      data: {
        type: "TEMPLE_NOTIFICATION",
        ...(link ? { link: link } : {}),
      },
      // Android: high-priority channel with custom action buttons.
      android: {
        priority: "high",
        notification: {
          channelId: "temple_notifications_v3",
          priority: "high",
          defaultSound: true,
        },
      },
      // iOS: plain alert banner — no 'category' means no action buttons.
      // Tapping the banner calls onMessageOpenedApp which opens the
      // notifications screen. Simple and reliable.
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
            // No 'category' field → iOS shows no action buttons
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

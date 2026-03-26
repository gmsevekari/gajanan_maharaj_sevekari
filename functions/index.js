const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
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

  // (Removed: Enrolling -> Allocated transition - now handled manually by Admin in app)

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

exports.sendParayanReminders = onSchedule("0 * * * *", async (event) => {
  const db = admin.firestore();

  const nowSeattle = DateTime.now().setZone("America/Los_Angeles");
  const todaySeattle = nowSeattle.startOf("day");

  // Format current hour as HH:00 to match reminderTimes (e.g. "08:00", "20:00")
  const currentHourString = nowSeattle.toFormat("HH:00");

  logger.info(
    `Running Parayan reminders check. Seattle: ${nowSeattle.toISO()}, ` +
    `Hour: ${currentHourString}`,
  );

  const ongoingQuery = await db.collection("parayan_events")
    .where("status", "==", "ongoing")
    .get();

  for (const doc of ongoingQuery.docs) {
    const data = doc.data();

    const reminderTimes = data.reminderTimes || [];
    if (!reminderTimes.includes(currentHourString)) {
      continue;
    }

    const startDate = DateTime.fromJSDate(data.startDate.toDate())
      .setZone("America/Los_Angeles")
      .startOf("day");

    // Calculate current day (1-indexed)
    const diffInDays = todaySeattle.diff(startDate, "days").days;
    const currentDay = Math.floor(diffInDays) + 1;

    // Sanity check to ensure we don't send over-day reminders
    if (currentDay < 1) continue;
    if (data.type === "oneDay" || data.type === "guruPushya") {
      if (currentDay !== 1) continue;
    } else if (data.type === "threeDay") {
      if (currentDay > 3) continue;
    }

    const topic = `parayan_${doc.id}_day${currentDay}`;
    const title = "Parayan Reminder";
    const eventName = data.title_en || data.title || "Parayan";
    const body = `Reminder for ${eventName}. Please read your assigned ` +
      `adhyays for Day ${currentDay}.`;

    const message = {
      notification: {
        title: title,
        body: body,
      },
      data: {
        type: "PARAYAN_REMINDER",
        event_id: doc.id,
      },
      android: {
        priority: "high",
        notification: {
          // Use a distinct high-priority channel for Parayan Reminders
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
            alert: { title: title, body: body },
            sound: "default",
          },
        },
      },
      topic: topic,
    };

    logger.info(`Sending reminder to topic: ${topic}`);

    try {
      // 1. Record in notifications collection for user history FIRST
      // This ensures that if the user taps the notification immediately,
      // the record is already available in the app's history screen.
      await db.collection("notifications").add({
        title: title,
        body: body,
        timestamp: nowSeattle.toISO(),
        expires_at: admin.firestore.Timestamp.fromDate(
          nowSeattle.plus({ days: 30 }).toJSDate(),
        ),
        type: "PARAYAN_REMINDER",
        eventId: doc.id,
        day: currentDay,
      });

      // 2. Then send the FCM message
      await admin.messaging().send(message);

      logger.info(
        `Successfully sent reminder for event ${doc.id} day ${currentDay}`,
      );

      const sentKey = `sentReminders.day${currentDay}_${currentHourString}`;
      await doc.ref.update({
        [sentKey]: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (error) {
      logger.error(
        `Error sending reminder for event ${doc.id} on topic ${topic}:`,
        error,
      );
    }
  }
});

/**
 * Phase 4: Cloud Allocation & Data Flattening
 * This function will be the single target for Parayan adhyay assignment.
 */
exports.allocateParayanAdhyays = onCall(async (request) => {
  const { eventId } = request.data;
  const auth = request.auth;

  if (!auth) {
    throw new HttpsError("unauthenticated", "Admin authentication required.");
  }

  logger.info(`Starting allocation for event: ${eventId} by ${auth.uid}`);

  const db = admin.firestore();
  try {
    const eventRef = db.collection("parayan_events").doc(eventId);
    const eventDoc = await eventRef.get();

    if (!eventDoc.exists) {
      throw new HttpsError("not-found", "Parayan event not found.");
    }

    const eventData = eventDoc.data();
    const type = eventData.type; // 'oneDay', 'threeDay', etc.

    const participantsRef = eventRef.collection("participants");
    const snapshot = await participantsRef.get();

    if (snapshot.empty) {
      return { success: false, message: "No participants to allocate." };
    }

    // 1. Flatten and Sort
    // Since we've flattened the schema, each doc is a unique member.
    const allMembers = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));

    // Sort globally by joinedAt to maintain chronological order
    allMembers.sort((a, b) => {
      const timeA = a.joinedAt ? a.joinedAt.toMillis() : 0;
      const timeB = b.joinedAt ? b.joinedAt.toMillis() : 0;
      return timeA - timeB;
    });

    // 2. Allocate Adhyays
    const batch = db.batch();
    const now = admin.firestore.Timestamp.now();

    for (let i = 0; i < allMembers.length; i++) {
      const member = allMembers[i];
      let assigned = [];
      let completions = {};
      let groupNumber = 1;

      if (type === "oneDay" || type === "guruPushya") {
        const adhyay = (i % 21) + 1;
        assigned = [adhyay];
        completions["1"] = false;
        groupNumber = Math.floor(i / 21) + 1;
      } else if (type === "threeDay") {
        const groupSize = 7;
        const groupOffset = Math.floor(i / groupSize) % 3;
        const participantOffset = (i % groupSize) * 3;

        const day1 = ((groupOffset + participantOffset) % 21) + 1;
        const day2 = (day1 % 21) + 1;
        const day3 = (day2 % 21) + 1;

        assigned = [day1, day2, day3];
        completions = { "1": false, "2": false, "3": false };
        groupNumber = Math.floor(i / groupSize) + 1;
      } else {
        const adhyay = (i % 21) + 1;
        assigned = [adhyay];
        completions["1"] = false;
        groupNumber = Math.floor(i / 21) + 1;
      }

      batch.update(participantsRef.doc(member.id), {
        assignedAdhyays: assigned,
        completions: completions,
        globalIndex: i,
        groupNumber: groupNumber,
        allocatedAt: now,
      });
    }

    // 3. Update Event Status
    batch.update(eventRef, {
      status: "allocated",
      allocatedAt: now,
    });

    await batch.commit();

    logger.info(`Successfully allocated adhyays for ${allMembers.length} members in event ${eventId}`);
    return {
      success: true,
      count: allMembers.length,
    };
  } catch (error) {
    logger.error(`Error in allocateParayanAdhyays: ${error}`);
    throw new HttpsError("internal", error.message);
  }
});

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");
const logger = require("firebase-functions/logger");
const { DateTime } = require("luxon");

/**
 * Auto-transition Parayan statuses based on dates
 */
exports.updateParayanStatuses = onSchedule("0 * * * *", async (event) => {
  const db = admin.firestore();
  const nowSeattle = DateTime.now().setZone("America/Los_Angeles");
  const todaySeattle = nowSeattle.startOf("day");

  logger.info(`Running Parayan status update. Seattle: ${nowSeattle.toISO()}`);

  const parayansRef = db.collection("parayan_events");

  // 1. Allocated -> Ongoing (On start date)
  const allocatedQuery = await parayansRef.where("status", "==", "allocated").get();
  for (const doc of allocatedQuery.docs) {
    const data = doc.data();
    const startDate = DateTime.fromJSDate(data.startDate.toDate()).setZone("America/Los_Angeles").startOf("day");

    if (todaySeattle >= startDate) {
      await doc.ref.update({ status: "ongoing" });
      logger.info(`Auto-transitioned Parayan ${doc.id} to ongoing (Start Date reached).`);
    }
  }

  // 2. Ongoing -> Completed (After end date)
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

/**
 * Phase 4: Cloud Allocation & Data Flattening
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
    const type = eventData.type;

    const participantsRef = eventRef.collection("participants");
    const snapshot = await participantsRef.get();

    if (snapshot.empty) {
      return { success: false, message: "No participants to allocate." };
    }

    const allMembers = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));

    allMembers.sort((a, b) => {
      const timeA = a.joinedAt ? a.joinedAt.toMillis() : 0;
      const timeB = b.joinedAt ? b.joinedAt.toMillis() : 0;
      return timeA - timeB;
    });

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

    batch.update(eventRef, {
      status: "allocated",
      allocatedAt: now,
    });

    await batch.commit();

    logger.info(`Successfully allocated adhyays for ${allMembers.length} members in event ${eventId}`);
    return { success: true, count: allMembers.length };
  } catch (error) {
    logger.error(`Error in allocateParayanAdhyays: ${error}`);
    throw new HttpsError("internal", error.message);
  }
});

/**
 * Admin Adding Participants (Incremental Allocation)
 */
exports.adminAddParticipants = onCall(async (request) => {
  const { eventId, groups } = request.data;
  const auth = request.auth;

  if (!auth) {
    throw new HttpsError("unauthenticated", "Admin authentication required.");
  }

  const db = admin.firestore();

  return db.runTransaction(async (transaction) => {
    const eventRef = db.collection("parayan_events").doc(eventId);
    const eventDoc = await transaction.get(eventRef);

    if (!eventDoc.exists) {
      throw new HttpsError("not-found", "Parayan event not found.");
    }

    const eventData = eventDoc.data();
    const type = eventData.type;
    const isAllocatedOrOngoing = eventData.status === "allocated" || eventData.status === "ongoing";

    const participantsRef = eventRef.collection("participants");
    const snapshot = await transaction.get(participantsRef);
    let nextIndex = snapshot.size;

    const now = admin.firestore.Timestamp.now();
    const results = [];

    for (const group of groups) {
      const { phone, names } = group;

      for (const name of names) {
        let assigned = [];
        let completions = {};
        let groupNumber = null;

        if (isAllocatedOrOngoing) {
          if (type === "oneDay" || type === "guruPushya") {
            const adhyay = (nextIndex % 21) + 1;
            assigned = [adhyay];
            completions["1"] = false;
            groupNumber = Math.floor(nextIndex / 21) + 1;
          } else if (type === "threeDay") {
            const grpSize = 7;
            const groupOffset = Math.floor(nextIndex / grpSize) % 3;
            const participantOffset = (nextIndex / grpSize) * 3;

            const day1 = ((groupOffset + participantOffset) % 21) + 1;
            const day2 = (day1 % 21) + 1;
            const day3 = (day2 % 21) + 1;

            assigned = [day1, day2, day3];
            completions = { "1": false, "2": false, "3": false };
            groupNumber = Math.floor(nextIndex / grpSize) + 1;
          } else {
            const adhyay = (nextIndex % 21) + 1;
            assigned = [adhyay];
            completions["1"] = false;
            groupNumber = Math.floor(nextIndex / 21) + 1;
          }
        }

        const sanitizedPhone = phone.replace(/[^\d+]/g, "");
        const sanitizedName = name.replace(/\s+/g, "_");
        const docId = `ADMIN_${sanitizedPhone}_${sanitizedName}_${Date.now()}`;
        const memberRef = participantsRef.doc(docId);

        const memberData = {
          name: name,
          memberName: name,
          phone: phone,
          deviceId: "ADMIN_MANUAL",
          joinedAt: now,
          assignedAdhyays: assigned,
          completions: completions,
          globalIndex: isAllocatedOrOngoing ? nextIndex : null,
          groupNumber: groupNumber,
        };

        transaction.set(memberRef, memberData);
        results.push({ name: name, index: nextIndex });
        nextIndex++;
      }
    }

    logger.info(`Admin added ${results.length} participants to event ${eventId}`);
    return { success: true, count: results.length };
  });
});

/**
 * Phase 1: Secure Claim Flow
 */
exports.claimParayanAllocation = onCall(async (request) => {
  const { eventId, phone, deviceId, overwrite = false } = request.data;

  if (!eventId || !phone || !deviceId) {
    throw new HttpsError("invalid-argument", "Missing required fields.");
  }

  const db = admin.firestore();
  const sanitizedInputPhone = phone.replace(/[^\d+]/g, "");
  logger.info(`Claim request for event: ${eventId}, phone: ${sanitizedInputPhone}, device: ${deviceId}`);

  try {
    const participantsRef = db.collection("parayan_events").doc(eventId).collection("participants");

    // Standardized lookup: the phone number is expected to be in +<CountryCode><10_Digit_Number> format
    const snapshot = await participantsRef.where("phone", "==", sanitizedInputPhone).get();

    if (snapshot.empty) {
      return { status: "NOT_FOUND", message: "No participant found with this phone number." };
    }

    const participants = [];
    let conflictFound = false;

    snapshot.forEach(doc => {
      const data = doc.data();
      // Check for conflict: another device already linked
      if (data.deviceId && data.deviceId !== "ADMIN_MANUAL" && data.deviceId !== deviceId) {
        conflictFound = true;
      }
      participants.push({ id: doc.id, ...data });
    });

    if (conflictFound && !overwrite) {
      return {
        status: "CONFLICT",
        message: "This phone number is already linked to another device.",
        count: participants.length
      };
    }

    // Perform updates
    const batch = db.batch();
    const now = admin.firestore.Timestamp.now();
    participants.forEach(p => {
      batch.update(participantsRef.doc(p.id), {
        deviceId: deviceId,
        claimedAt: now
      });
    });

    await batch.commit();

    return {
      status: "SUCCESS",
      participants: participants.map(p => ({
        name: p.name,
        assignedAdhyays: p.assignedAdhyays || []
      }))
    };

  } catch (error) {
    logger.error(`Error in claimParayanAllocation: ${error}`);
    throw new HttpsError("internal", error.message);
  }
});

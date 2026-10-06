// Automated verification of the signups/slots/entries security rules
// against the Firebase emulator. Covers the Phase 6.2 manual checklist from
// docs/signup-signups-tasks.md, plus the finer-grained behaviors the rules
// actually implement (exact +/-1 claimedCount bound, entry field validation).
'use strict';

const assert = require('node:assert/strict');
const { test, before, after, beforeEach } = require('node:test');
const fs = require('node:fs');
const path = require('node:path');
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');
const {
  doc,
  getDoc,
  setDoc,
  updateDoc,
  deleteDoc,
  deleteField,
  Timestamp,
} = require('firebase/firestore');

const PROJECT_ID = 'demo-signup-signups-rules-test';
const RULES_PATH = path.resolve(__dirname, '..', 'firestore.rules');

let testEnv;

// A slot's schedule: UTC instants plus the zone its times were entered in.
// This one is 6-7:30 PM Pacific daylight time on 2026-07-01.
function schedule(overrides = {}) {
  return {
    startAt: Timestamp.fromDate(new Date('2026-07-02T01:00:00Z')),
    endAt: Timestamp.fromDate(new Date('2026-07-02T02:30:00Z')),
    timezone: 'America/Los_Angeles',
    ...overrides,
  };
}

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: fs.readFileSync(RULES_PATH, 'utf8'),
      host: '127.0.0.1',
      port: 8080,
    },
  });
});

after(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, 'admin_allowlist/admin@test.com'), {
      roles: ['super_admin'],
    });
    await setDoc(doc(db, 'signups/signup1'), {
      titleEn: 'Prasad Seva',
      status: 'published',
    });
    await setDoc(doc(db, 'signups/signup1/slots/slot1'), {
      labelEn: 'Monday cooking',
      capacity: 5,
      claimedCount: 2,
      ...schedule(),
    });
    await setDoc(doc(db, 'signups/signup1/slots/fullSlot'), {
      labelEn: 'Full slot',
      capacity: 5,
      claimedCount: 5,
      ...schedule(),
    });
    await setDoc(doc(db, 'signups/signup1/slots/emptySlot'), {
      labelEn: 'Empty slot',
      capacity: 5,
      claimedCount: 0,
      ...schedule(),
    });
    await setDoc(doc(db, 'signups/signup1/entries/withDevice'), {
      slotId: 'slot1',
      name: 'Jane Devotee',
      deviceId: 'device_abc',
      joinedAt: Timestamp.now(),
    });
    // Matches SignupEntry.toMap()'s real shape for an admin-added entry:
    // deviceId is always a present key, explicitly null, never omitted.
    // Not a shape the app writes, but a document with no deviceId key must be
    // treated like one with a null deviceId.
    await setDoc(doc(db, 'signups/signup1/entries/noDeviceKey'), {
      slotId: 'slot1',
      name: 'Legacy Devotee',
      joinedAt: Timestamp.now(),
    });
    await setDoc(doc(db, 'signups/signup1/entries/noDevice'), {
      slotId: 'slot1',
      name: 'Admin-added Devotee',
      deviceId: null,
      joinedAt: Timestamp.now(),
    });
  });
});

function unauthedDb() {
  return testEnv.unauthenticatedContext().firestore();
}

function adminDb() {
  return testEnv
    .authenticatedContext('admin-uid', {
      email: 'admin@test.com',
      email_verified: true,
    })
    .firestore();
}

// --- signups document ---

test('non-admin can read a signup signup', async () => {
  await assertSucceeds(getDoc(doc(unauthedDb(), 'signups/signup1')));
});

test('non-admin cannot create a signup signup', async () => {
  await assertFails(
    setDoc(doc(unauthedDb(), 'signups/signup2'), { titleEn: 'Hack' }),
  );
});

test('admin can create a signup signup', async () => {
  await assertSucceeds(
    setDoc(doc(adminDb(), 'signups/signup2'), { titleEn: 'New Signup' }),
  );
});

// --- slots subcollection ---

test('non-admin can read a slot', async () => {
  await assertSucceeds(
    getDoc(doc(unauthedDb(), 'signups/signup1/slots/slot1')),
  );
});

test('non-admin cannot create a slot', async () => {
  await assertFails(
    setDoc(doc(unauthedDb(), 'signups/signup1/slots/slot2'), {
      labelEn: 'Injected slot',
      capacity: 1,
      claimedCount: 0,
    }),
  );
});

test('non-admin cannot delete a slot', async () => {
  await assertFails(
    deleteDoc(doc(unauthedDb(), 'signups/signup1/slots/slot1')),
  );
});

test('admin can create a slot', async () => {
  await assertSucceeds(
    setDoc(doc(adminDb(), 'signups/signup1/slots/slot2'), {
      labelEn: 'Admin slot',
      capacity: 1,
      claimedCount: 0,
    }),
  );
});

test('admin can create a slot with a start, end and timezone', async () => {
  await assertSucceeds(
    setDoc(doc(adminDb(), 'signups/signup1/slots/scheduled'), {
      labelEn: 'Scheduled slot',
      capacity: 1,
      claimedCount: 0,
      ...schedule({ timezone: 'Asia/Kolkata' }),
    }),
  );
});

test('non-admin cannot create a slot with a start, end and timezone', async () => {
  await assertFails(
    setDoc(doc(unauthedDb(), 'signups/signup1/slots/scheduled'), {
      labelEn: 'Injected slot',
      capacity: 1,
      claimedCount: 0,
      ...schedule(),
    }),
  );
});

test('admin can delete a slot', async () => {
  await assertSucceeds(
    deleteDoc(doc(adminDb(), 'signups/signup1/slots/slot1')),
  );
});

test('non-admin can increment claimedCount by exactly 1 within capacity', async () => {
  await assertSucceeds(
    updateDoc(doc(unauthedDb(), 'signups/signup1/slots/slot1'), {
      claimedCount: 3,
    }),
  );
});

test('non-admin can decrement claimedCount by exactly 1', async () => {
  await assertSucceeds(
    updateDoc(doc(unauthedDb(), 'signups/signup1/slots/slot1'), {
      claimedCount: 1,
    }),
  );
});

test('non-admin cannot jump claimedCount by more than 1 in one write', async () => {
  await assertFails(
    updateDoc(doc(unauthedDb(), 'signups/signup1/slots/slot1'), {
      claimedCount: 4,
    }),
  );
});

test('non-admin cannot push claimedCount above capacity', async () => {
  await assertFails(
    updateDoc(doc(unauthedDb(), 'signups/signup1/slots/fullSlot'), {
      claimedCount: 6,
    }),
  );
});

test('non-admin cannot push claimedCount below zero', async () => {
  await assertFails(
    updateDoc(doc(unauthedDb(), 'signups/signup1/slots/emptySlot'), {
      claimedCount: -1,
    }),
  );
});

test('non-admin cannot modify capacity', async () => {
  await assertFails(
    updateDoc(doc(unauthedDb(), 'signups/signup1/slots/slot1'), {
      capacity: 100,
    }),
  );
});

test('non-admin cannot modify label or schedule fields', async () => {
  await assertFails(
    updateDoc(doc(unauthedDb(), 'signups/signup1/slots/slot1'), {
      labelEn: 'Hacked label',
    }),
  );
});

test('non-admin cannot change a slot\'s start, end or timezone', async () => {
  for (const change of [
    { startAt: Timestamp.fromDate(new Date('2026-07-03T01:00:00Z')) },
    { endAt: Timestamp.fromDate(new Date('2026-07-03T02:30:00Z')) },
    { timezone: 'Asia/Kolkata' },
  ]) {
    await assertFails(
      updateDoc(doc(unauthedDb(), 'signups/signup1/slots/slot1'), change),
    );
    // Not even next to an otherwise valid claimedCount change.
    await assertFails(
      updateDoc(doc(unauthedDb(), 'signups/signup1/slots/slot1'), {
        claimedCount: 3,
        ...change,
      }),
    );
  }
});

test('non-admin claimedCount change leaves the schedule fields untouched', async () => {
  const ref = doc(unauthedDb(), 'signups/signup1/slots/slot1');
  await assertSucceeds(updateDoc(ref, { claimedCount: 3 }));

  const slot = (await getDoc(ref)).data();
  assert.equal(slot.claimedCount, 3);
  assert.equal(slot.timezone, 'America/Los_Angeles');
  assert.deepEqual(slot.startAt, schedule().startAt);
  assert.deepEqual(slot.endAt, schedule().endAt);
});

test('non-admin cannot smuggle a capacity change alongside a valid claimedCount change', async () => {
  await assertFails(
    updateDoc(doc(unauthedDb(), 'signups/signup1/slots/slot1'), {
      claimedCount: 3,
      capacity: 100,
    }),
  );
});

test('admin can freely modify capacity, label, and claimedCount', async () => {
  await assertSucceeds(
    updateDoc(doc(adminDb(), 'signups/signup1/slots/slot1'), {
      capacity: 10,
      labelEn: 'Admin edited label',
      claimedCount: 9,
    }),
  );
});

test('admin can reschedule a slot', async () => {
  await assertSucceeds(
    updateDoc(doc(adminDb(), 'signups/signup1/slots/slot1'), {
      startAt: Timestamp.fromDate(new Date('2026-07-03T01:00:00Z')),
      endAt: Timestamp.fromDate(new Date('2026-07-04T06:59:00Z')),
      timezone: 'Asia/Kolkata',
    }),
  );
});

// --- entries subcollection ---

test('non-admin can read entries', async () => {
  await assertSucceeds(
    getDoc(doc(unauthedDb(), 'signups/signup1/entries/withDevice')),
  );
});

test('non-admin can create a valid entry', async () => {
  await assertSucceeds(
    setDoc(doc(unauthedDb(), 'signups/signup1/entries/newEntry'), {
      slotId: 'slot1',
      name: 'New Devotee',
      deviceId: 'device_xyz',
      joinedAt: Timestamp.now(),
    }),
  );
});

test('non-admin cannot create an entry missing a required field', async () => {
  await assertFails(
    setDoc(doc(unauthedDb(), 'signups/signup1/entries/badEntry'), {
      slotId: 'slot1',
      joinedAt: Timestamp.now(),
      // missing 'name'
    }),
  );
});

test('non-admin cannot create an entry with an unexpected field', async () => {
  await assertFails(
    setDoc(doc(unauthedDb(), 'signups/signup1/entries/badEntry'), {
      slotId: 'slot1',
      name: 'Devotee',
      joinedAt: Timestamp.now(),
      isAdmin: true,
    }),
  );
});

test('non-admin cannot create an entry with an oversized name', async () => {
  await assertFails(
    setDoc(doc(unauthedDb(), 'signups/signup1/entries/badEntry'), {
      slotId: 'slot1',
      name: 'x'.repeat(100),
      joinedAt: Timestamp.now(),
    }),
  );
});

test('non-admin cannot create an entry with a negative pledge amount', async () => {
  await assertFails(
    setDoc(doc(unauthedDb(), 'signups/signup1/entries/badEntry'), {
      slotId: 'slot1',
      name: 'Devotee',
      pledgeAmount: -5,
      joinedAt: Timestamp.now(),
    }),
  );
});

test('non-admin cannot create an entry with an excessive pledge amount', async () => {
  await assertFails(
    setDoc(doc(unauthedDb(), 'signups/signup1/entries/badEntry'), {
      slotId: 'slot1',
      name: 'Devotee',
      pledgeAmount: 1000001,
      joinedAt: Timestamp.now(),
    }),
  );
});

const withDeviceRef = () =>
  doc(unauthedDb(), 'signups/signup1/entries/withDevice');
const noDeviceRef = () => doc(unauthedDb(), 'signups/signup1/entries/noDevice');

test('non-admin can edit the name, phone, email, pledge and note of an entry that has a deviceId', async () => {
  await assertSucceeds(
    updateDoc(withDeviceRef(), {
      name: 'Jane Edited',
      phone: '+14255551234',
      email: 'jane@example.com',
      pledgeAmount: 25,
      note: 'Bringing sweets',
    }),
  );

  const entry = (await getDoc(withDeviceRef())).data();
  assert.equal(entry.name, 'Jane Edited');
  assert.equal(entry.deviceId, 'device_abc');
  assert.equal(entry.slotId, 'slot1');
});

test('non-admin can clear an entry\'s phone, email, pledge and note', async () => {
  await assertSucceeds(
    updateDoc(withDeviceRef(), {
      phone: null,
      email: null,
      pledgeAmount: null,
      note: null,
    }),
  );
});

test('non-admin cannot edit an entry that has no deviceId', async () => {
  await assertFails(updateDoc(noDeviceRef(), { name: 'Edited Name' }));
});

test('non-admin cannot edit an entry that has no deviceId key at all', async () => {
  await assertFails(
    updateDoc(doc(unauthedDb(), 'signups/signup1/entries/noDeviceKey'), {
      name: 'Edited Name',
    }),
  );
});

test('non-admin can edit a pledge of exactly 0', async () => {
  await assertSucceeds(updateDoc(withDeviceRef(), { pledgeAmount: 0 }));
});

test('non-admin cannot set a NaN pledge', async () => {
  await assertFails(updateDoc(withDeviceRef(), { pledgeAmount: NaN }));
});

test('non-admin cannot delete the name or deviceId field of an entry', async () => {
  await assertFails(updateDoc(withDeviceRef(), { name: deleteField() }));
  await assertFails(updateDoc(withDeviceRef(), { deviceId: deleteField() }));
});

test('non-admin cannot change an entry\'s deviceId, slotId or joinedAt', async () => {
  for (const change of [
    { deviceId: 'device_thief' },
    { deviceId: null },
    { slotId: 'emptySlot' },
    { joinedAt: Timestamp.fromDate(new Date('2020-01-01T00:00:00Z')) },
  ]) {
    await assertFails(updateDoc(withDeviceRef(), change));
    // Not even next to an otherwise valid edit.
    await assertFails(updateDoc(withDeviceRef(), { name: 'Jane', ...change }));
  }
});

test('non-admin cannot add an unexpected field to an entry', async () => {
  await assertFails(updateDoc(withDeviceRef(), { isAdmin: true }));
});

test('non-admin cannot edit an entry into an invalid one', async () => {
  for (const change of [
    { name: '' },
    { name: 'x'.repeat(100) },
    { name: 42 },
    { phone: 'x'.repeat(30) },
    { phone: 12345 },
    { email: 'x'.repeat(200) },
    { email: 12345 },
    { pledgeAmount: -5 },
    { pledgeAmount: 1000001 },
    { pledgeAmount: '25' },
    { note: 'x'.repeat(500) },
    { note: 12345 },
  ]) {
    await assertFails(updateDoc(withDeviceRef(), change));
  }
});

test('non-admin can edit an entry to the largest allowed values', async () => {
  await assertSucceeds(
    updateDoc(withDeviceRef(), {
      name: 'x'.repeat(99),
      phone: '1'.repeat(29),
      email: 'x'.repeat(199),
      pledgeAmount: 1000000,
      note: 'x'.repeat(499),
    }),
  );
});

test('admin can update an entry', async () => {
  await assertSucceeds(
    updateDoc(doc(adminDb(), 'signups/signup1/entries/withDevice'), {
      name: 'Admin Edited Name',
    }),
  );
});

test('admin can change any field of an entry, including its slot and device', async () => {
  const ref = doc(adminDb(), 'signups/signup1/entries/withDevice');
  await assertSucceeds(
    updateDoc(ref, {
      slotId: 'emptySlot',
      deviceId: 'device_new',
      joinedAt: Timestamp.fromDate(new Date('2020-01-01T00:00:00Z')),
    }),
  );
  await assertSucceeds(updateDoc(ref, { deviceId: null }));
});

test('admin can edit an entry that has no deviceId', async () => {
  await assertSucceeds(
    updateDoc(doc(adminDb(), 'signups/signup1/entries/noDevice'), {
      name: 'Edited By Admin',
    }),
  );
});

test('non-admin can delete an entry that has a deviceId', async () => {
  await assertSucceeds(
    deleteDoc(doc(unauthedDb(), 'signups/signup1/entries/withDevice')),
  );
});

test('non-admin cannot delete an entry that has no deviceId', async () => {
  await assertFails(
    deleteDoc(doc(unauthedDb(), 'signups/signup1/entries/noDevice')),
  );
});

test('admin can delete any entry regardless of deviceId', async () => {
  await assertSucceeds(
    deleteDoc(doc(adminDb(), 'signups/signup1/entries/noDevice')),
  );
});

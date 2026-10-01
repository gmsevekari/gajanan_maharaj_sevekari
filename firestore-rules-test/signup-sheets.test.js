// Automated verification of the signup_sheets/slots/entries security rules
// against the Firebase emulator. Covers the Phase 6.2 manual checklist from
// docs/signup-sheets-tasks.md, plus the finer-grained behaviors the rules
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
  Timestamp,
} = require('firebase/firestore');

const PROJECT_ID = 'demo-signup-sheets-rules-test';
const RULES_PATH = path.resolve(__dirname, '..', 'firestore.rules');

let testEnv;

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
    await setDoc(doc(db, 'signup_sheets/sheet1'), {
      titleEn: 'Prasad Seva',
      status: 'published',
    });
    await setDoc(doc(db, 'signup_sheets/sheet1/slots/slot1'), {
      labelEn: 'Monday cooking',
      capacity: 5,
      claimedCount: 2,
    });
    await setDoc(doc(db, 'signup_sheets/sheet1/slots/fullSlot'), {
      labelEn: 'Full slot',
      capacity: 5,
      claimedCount: 5,
    });
    await setDoc(doc(db, 'signup_sheets/sheet1/slots/emptySlot'), {
      labelEn: 'Empty slot',
      capacity: 5,
      claimedCount: 0,
    });
    await setDoc(doc(db, 'signup_sheets/sheet1/entries/withDevice'), {
      slotId: 'slot1',
      name: 'Jane Devotee',
      deviceId: 'device_abc',
      joinedAt: Timestamp.now(),
    });
    // Matches SignupEntry.toMap()'s real shape for an admin-added entry:
    // deviceId is always a present key, explicitly null, never omitted.
    await setDoc(doc(db, 'signup_sheets/sheet1/entries/noDevice'), {
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

// --- signup_sheets document ---

test('non-admin can read a signup sheet', async () => {
  await assertSucceeds(getDoc(doc(unauthedDb(), 'signup_sheets/sheet1')));
});

test('non-admin cannot create a signup sheet', async () => {
  await assertFails(
    setDoc(doc(unauthedDb(), 'signup_sheets/sheet2'), { titleEn: 'Hack' }),
  );
});

test('admin can create a signup sheet', async () => {
  await assertSucceeds(
    setDoc(doc(adminDb(), 'signup_sheets/sheet2'), { titleEn: 'New Sheet' }),
  );
});

// --- slots subcollection ---

test('non-admin can read a slot', async () => {
  await assertSucceeds(
    getDoc(doc(unauthedDb(), 'signup_sheets/sheet1/slots/slot1')),
  );
});

test('non-admin cannot create a slot', async () => {
  await assertFails(
    setDoc(doc(unauthedDb(), 'signup_sheets/sheet1/slots/slot2'), {
      labelEn: 'Injected slot',
      capacity: 1,
      claimedCount: 0,
    }),
  );
});

test('non-admin cannot delete a slot', async () => {
  await assertFails(
    deleteDoc(doc(unauthedDb(), 'signup_sheets/sheet1/slots/slot1')),
  );
});

test('admin can create a slot', async () => {
  await assertSucceeds(
    setDoc(doc(adminDb(), 'signup_sheets/sheet1/slots/slot2'), {
      labelEn: 'Admin slot',
      capacity: 1,
      claimedCount: 0,
    }),
  );
});

test('admin can delete a slot', async () => {
  await assertSucceeds(
    deleteDoc(doc(adminDb(), 'signup_sheets/sheet1/slots/slot1')),
  );
});

test('non-admin can increment claimedCount by exactly 1 within capacity', async () => {
  await assertSucceeds(
    updateDoc(doc(unauthedDb(), 'signup_sheets/sheet1/slots/slot1'), {
      claimedCount: 3,
    }),
  );
});

test('non-admin can decrement claimedCount by exactly 1', async () => {
  await assertSucceeds(
    updateDoc(doc(unauthedDb(), 'signup_sheets/sheet1/slots/slot1'), {
      claimedCount: 1,
    }),
  );
});

test('non-admin cannot jump claimedCount by more than 1 in one write', async () => {
  await assertFails(
    updateDoc(doc(unauthedDb(), 'signup_sheets/sheet1/slots/slot1'), {
      claimedCount: 4,
    }),
  );
});

test('non-admin cannot push claimedCount above capacity', async () => {
  await assertFails(
    updateDoc(doc(unauthedDb(), 'signup_sheets/sheet1/slots/fullSlot'), {
      claimedCount: 6,
    }),
  );
});

test('non-admin cannot push claimedCount below zero', async () => {
  await assertFails(
    updateDoc(doc(unauthedDb(), 'signup_sheets/sheet1/slots/emptySlot'), {
      claimedCount: -1,
    }),
  );
});

test('non-admin cannot modify capacity', async () => {
  await assertFails(
    updateDoc(doc(unauthedDb(), 'signup_sheets/sheet1/slots/slot1'), {
      capacity: 100,
    }),
  );
});

test('non-admin cannot modify label or date fields', async () => {
  await assertFails(
    updateDoc(doc(unauthedDb(), 'signup_sheets/sheet1/slots/slot1'), {
      labelEn: 'Hacked label',
    }),
  );
});

test('non-admin cannot smuggle a capacity change alongside a valid claimedCount change', async () => {
  await assertFails(
    updateDoc(doc(unauthedDb(), 'signup_sheets/sheet1/slots/slot1'), {
      claimedCount: 3,
      capacity: 100,
    }),
  );
});

test('admin can freely modify capacity, label, and claimedCount', async () => {
  await assertSucceeds(
    updateDoc(doc(adminDb(), 'signup_sheets/sheet1/slots/slot1'), {
      capacity: 10,
      labelEn: 'Admin edited label',
      claimedCount: 9,
    }),
  );
});

// --- entries subcollection ---

test('non-admin can read entries', async () => {
  await assertSucceeds(
    getDoc(doc(unauthedDb(), 'signup_sheets/sheet1/entries/withDevice')),
  );
});

test('non-admin can create a valid entry', async () => {
  await assertSucceeds(
    setDoc(doc(unauthedDb(), 'signup_sheets/sheet1/entries/newEntry'), {
      slotId: 'slot1',
      name: 'New Devotee',
      deviceId: 'device_xyz',
      joinedAt: Timestamp.now(),
    }),
  );
});

test('non-admin cannot create an entry missing a required field', async () => {
  await assertFails(
    setDoc(doc(unauthedDb(), 'signup_sheets/sheet1/entries/badEntry'), {
      slotId: 'slot1',
      joinedAt: Timestamp.now(),
      // missing 'name'
    }),
  );
});

test('non-admin cannot create an entry with an unexpected field', async () => {
  await assertFails(
    setDoc(doc(unauthedDb(), 'signup_sheets/sheet1/entries/badEntry'), {
      slotId: 'slot1',
      name: 'Devotee',
      joinedAt: Timestamp.now(),
      isAdmin: true,
    }),
  );
});

test('non-admin cannot create an entry with an oversized name', async () => {
  await assertFails(
    setDoc(doc(unauthedDb(), 'signup_sheets/sheet1/entries/badEntry'), {
      slotId: 'slot1',
      name: 'x'.repeat(100),
      joinedAt: Timestamp.now(),
    }),
  );
});

test('non-admin cannot create an entry with a negative pledge amount', async () => {
  await assertFails(
    setDoc(doc(unauthedDb(), 'signup_sheets/sheet1/entries/badEntry'), {
      slotId: 'slot1',
      name: 'Devotee',
      pledgeAmount: -5,
      joinedAt: Timestamp.now(),
    }),
  );
});

test('non-admin cannot create an entry with an excessive pledge amount', async () => {
  await assertFails(
    setDoc(doc(unauthedDb(), 'signup_sheets/sheet1/entries/badEntry'), {
      slotId: 'slot1',
      name: 'Devotee',
      pledgeAmount: 1000001,
      joinedAt: Timestamp.now(),
    }),
  );
});

test('non-admin cannot update an entry', async () => {
  await assertFails(
    updateDoc(doc(unauthedDb(), 'signup_sheets/sheet1/entries/withDevice'), {
      name: 'Edited Name',
    }),
  );
});

test('admin can update an entry', async () => {
  await assertSucceeds(
    updateDoc(doc(adminDb(), 'signup_sheets/sheet1/entries/withDevice'), {
      name: 'Admin Edited Name',
    }),
  );
});

test('non-admin can delete an entry that has a deviceId', async () => {
  await assertSucceeds(
    deleteDoc(doc(unauthedDb(), 'signup_sheets/sheet1/entries/withDevice')),
  );
});

test('non-admin cannot delete an entry that has no deviceId', async () => {
  await assertFails(
    deleteDoc(doc(unauthedDb(), 'signup_sheets/sheet1/entries/noDevice')),
  );
});

test('admin can delete any entry regardless of deviceId', async () => {
  await assertSucceeds(
    deleteDoc(doc(adminDb(), 'signup_sheets/sheet1/entries/noDevice')),
  );
});

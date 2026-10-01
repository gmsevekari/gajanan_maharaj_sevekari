// Automated verification of storage.rules for Sign-Up Sheets header
// images. Needs BOTH the Storage and Firestore emulators running, since
// storage.rules's isAdmin() does a cross-service firestore.exists() read
// against admin_allowlist (Storage Rules v2), exactly like the real rule.
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
const { doc, setDoc } = require('firebase/firestore');
const { ref, uploadBytes, getBytes, deleteObject } = require('firebase/storage');

const PROJECT_ID = 'demo-signup-sheets-rules-test';
const STORAGE_RULES_PATH = path.resolve(__dirname, '..', 'storage.rules');
const FIRESTORE_RULES_PATH = path.resolve(__dirname, '..', 'firestore.rules');

const ONE_MB = 1024 * 1024;

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: fs.readFileSync(FIRESTORE_RULES_PATH, 'utf8'),
      host: '127.0.0.1',
      port: 8080,
    },
    storage: {
      rules: fs.readFileSync(STORAGE_RULES_PATH, 'utf8'),
      host: '127.0.0.1',
      port: 9199,
    },
  });
});

after(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'admin_allowlist/admin@test.com'), {
      roles: ['super_admin'],
    });
    await uploadBytes(
      ref(context.storage(), 'signup_sheets/sheet1/header'),
      new Uint8Array([1, 2, 3]),
      { contentType: 'image/jpeg' },
    );
  });
});

function unauthedStorage() {
  return testEnv.unauthenticatedContext().storage();
}

function adminStorage() {
  return testEnv
    .authenticatedContext('admin-uid', {
      email: 'admin@test.com',
      email_verified: true,
    })
    .storage();
}

test('anyone can read a header image', async () => {
  await assertSucceeds(
    getBytes(ref(unauthedStorage(), 'signup_sheets/sheet1/header')),
  );
});

test('non-admin cannot upload a header image', async () => {
  await assertFails(
    uploadBytes(
      ref(unauthedStorage(), 'signup_sheets/sheet2/header'),
      new Uint8Array([1, 2, 3]),
      { contentType: 'image/jpeg' },
    ),
  );
});

test('admin can upload a small image under the size limit', async () => {
  await assertSucceeds(
    uploadBytes(
      ref(adminStorage(), 'signup_sheets/sheet2/header'),
      new Uint8Array(ONE_MB),
      { contentType: 'image/jpeg' },
    ),
  );
});

test('admin cannot upload a file at or over the 2 MB limit', async () => {
  await assertFails(
    uploadBytes(
      ref(adminStorage(), 'signup_sheets/sheet2/header'),
      new Uint8Array(2 * ONE_MB),
      { contentType: 'image/jpeg' },
    ),
  );
});

test('admin cannot upload a non-image content type', async () => {
  await assertFails(
    uploadBytes(
      ref(adminStorage(), 'signup_sheets/sheet2/header'),
      new Uint8Array(ONE_MB),
      { contentType: 'application/pdf' },
    ),
  );
});

test('non-admin cannot delete a header image', async () => {
  await assertFails(
    deleteObject(ref(unauthedStorage(), 'signup_sheets/sheet1/header')),
  );
});

test('admin can delete a header image', async () => {
  await assertSucceeds(
    deleteObject(ref(adminStorage(), 'signup_sheets/sheet1/header')),
  );
});

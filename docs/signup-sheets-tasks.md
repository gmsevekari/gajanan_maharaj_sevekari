# Sign-Up Sheets — Task Breakdown

Status: **draft — pending review**
Builds on: `docs/signup-sheets-requirements.md`, `docs/signup-sheets-design.md`

Each task is sized to roughly one TDD cycle (failing test → minimal
implementation → checkpoint commit), matching how `ParticipantContactActions`
was built in this repo. File paths follow existing conventions:
`lib/models/` for data models, `lib/providers/` for services,
`lib/signups/` for devotee screens, `lib/admin/signups/` for admin screens
(mirroring the Vaari admin layout under `lib/admin/vaari/`), tests
mirroring each under `test/unit/`, `test/widget/`, `test/admin/`.

**One design addition made while breaking this down** (flagging since it
changes the §3 service API surface in the design doc): `createSheetWithSlots`
— a single batched write for sheet + all its slots at creation time.
Without it, creating a sheet with dozens of slots via individual `addSlot()`
calls risks a partial write if the app dies mid-loop, the same failure mode
`ParayanService.createEventWithParticipants` already exists to avoid for
Parayan. See Phase 2, task 2.5.

---

## Phase 1 — Models

- [x] 1.1 `test/unit/models/signup_slot_test.dart` (RED): `fromMap`/`toMap`
      round-trip; `claimedCount` defaults to 0; optional `date` and
      `suggestedAmount` handle null.
- [x] 1.2 `lib/models/signup_slot.dart` (GREEN): implement `SignupSlot`.
- [x] 1.3 `test/unit/models/signup_entry_test.dart` (RED): `fromMap`/`toMap`
      round-trip; optional `phone`/`email`/`pledgeAmount`/`note`/`deviceId`
      all handle null.
- [x] 1.4 `lib/models/signup_entry.dart` (GREEN): implement `SignupEntry`.
- [x] 1.5 `test/unit/models/signup_sheet_test.dart` (RED): `fromMap`/`toMap`
      round-trip; `status` values (`draft`/`published`/`closed`);
      `requiresJoinCode` + `joinCode` pairing (joinCode null when false);
      optional `startDate`/`endDate`.
- [x] 1.6 `lib/models/signup_sheet.dart` (GREEN): implement `SignupSheet`.
- [x] 1.7 `flutter analyze` + `dart format` on all six files; confirm 100%
      coverage (these are small value objects, should be trivial to hit).
- [x] 1.8 Commit: `test: add failing tests for SignupSheet/Slot/Entry models`,
      then `feat: implement SignupSheet/Slot/Entry models`.

## Phase 2 — Service layer (`SignupService`)

The largest, highest-risk phase — the transactional claim logic is the one
piece of this feature that's genuinely hard to get wrong quietly. Broken
into sub-slices, each its own RED→GREEN commit pair against
`FakeFirebaseFirestore`, following `test/unit/providers/parayan_service_test.dart`'s
conventions.

**2a. Sheet CRUD**
- [x] 2.1 Failing tests: `createSheet`, `getSheetById`, `getActiveSheets
      (groupId)` (status == published only), `getAllSheets(groupId)` (all
      statuses, admin use), `updateSheet`, `updateSheetStatus`.
- [x] 2.2 Implement in `lib/providers/signup_service.dart`.

**2b. Slot CRUD**
- [x] 2.3 Failing tests: `addSlot`, `updateSlot`, `deleteSlot`,
      `reorderSlots` (batched `sortOrder` writes — note the 500-operation
      Firestore batch limit if a sheet ever approaches that many slots;
      chunk if so, but don't over-build for it now), `getSlots(sheetId)`
      (ordered by `sortOrder`).
- [x] 2.4 Implement.

**2c. Batched sheet+slots creation (new, see note above)**
- [x] 2.5 Failing tests: `createSheetWithSlots(sheet, slots)` — one batch
      write creates the sheet doc and every slot doc together; a slot list
      that fails mid-validation leaves nothing written (no partial sheet).
- [x] 2.6 Implement (`WriteBatch`, mirroring
      `ParayanService.createEventWithParticipants`).

**2d. Transactional claim / cancel — the critical path**
- [x] 2.7 Failing tests for `claimSlot`:
  - Happy path creates the entry and increments the slot's `claimedCount`.
  - Rejects with `{'success': false, 'error': 'slot_full'}` when
    `claimedCount >= capacity`, and does **not** create an entry.
  - When `sheet.requiresJoinCode` is true, rejects a missing/wrong
    `joinCode` with its own error code, without touching `claimedCount`.
  - Succeeds regardless of `joinCode` when `requiresJoinCode` is false.
  - Race-condition case: fire two concurrent `claimSlot` calls at a slot
    with `capacity: 1`; assert exactly one succeeds and `claimedCount`
    ends at 1, not 2. (Note when writing this: confirm
    `fake_cloud_firestore`'s transaction emulation actually serializes
    concurrent transactions realistically — if it doesn't model
    contention, document that gap in the test's comment rather than
    claiming false confidence, and note manual/emulator verification is
    still needed before this ships.)
- [x] 2.8 Implement `claimSlot` using `runTransaction`.
- [x] 2.9 Failing tests for `cancelEntry` / `adminRemoveEntry`: deletes the
      entry, decrements `claimedCount`, and `claimedCount` never goes
      below 0 even if called twice.
- [x] 2.10 Implement both.

**2e. Duplicate sheet**
- [x] 2.11 Failing tests for `duplicateSheet`: new sheet copies title/
      description/`requiresJoinCode` fields, status resets to `draft`, a
      fresh `joinCode` is generated if `requiresJoinCode`, every slot is
      copied with `claimedCount` reset to 0, and **no entries are copied**.
- [x] 2.12 Implement (batch copy of the `slots` subcollection).

**2f. Entry queries + admin manual entry**
- [x] 2.13 Failing tests: `getAllEntries(sheetId)`,
      `getEntriesByDevice(sheetId, deviceId)` ("my signups"),
      `adminAddEntry(...)` (bypasses `joinCode` check — admin-initiated).
- [x] 2.14 Implement.

- [x] 2.15 `flutter analyze` + `dart format`; coverage check (95%+,
      branch coverage on every `claimSlot`/`cancelEntry` error path).
      Actual: 164/165 lines (99.4%) — the one gap is the untestable
      `?? FirebaseFirestore.instance` constructor fallback, same
      precedented gap as `ParayanService`/`GroupNamjapService`.
- [x] 2.16 Commit each sub-slice (2a–2f) separately as it lands — expect
      roughly 10-12 commits for this phase given the complexity, matching
      this repo's granular-commit habit rather than one large PR-sized
      commit.
      Actual: 10 commits (5 RED/GREEN pairs: 2a sheet CRUD, 2b slot CRUD,
      2c createSheetWithSlots, 2d claimSlot/cancelEntry, 2e/2f
      duplicateSheet+adminAddEntry folded together).

      **Confirmed the fake_cloud_firestore contention caveat**: its
      `runTransaction` is a non-locking `_DummyTransaction` passthrough
      (verified in package source). The "race condition" test only proves
      the capacity check is correct when calls happen sequentially — it
      cannot prove real concurrent-transaction safety. Manual/emulator
      verification is still needed before Phase 2 ships to production.

- [x] 2.17 `/sk-review-code` run (flutter-dart-code-reviewer,
      code-reviewer, security-reviewer in parallel). Findings and
      resolution:
      - **[HIGH, fixed]** `updateSheet`/`updateSlot` passed a nullable
        `id` straight to `.doc()`, which auto-generates a *new* random-id
        document instead of throwing — silently wrote a stray duplicate
        doc instead of updating. Both now throw `ArgumentError` up front.
      - **[MEDIUM, fixed — user chose "add the same slot_full guard"]**
        `adminAddEntry` had no capacity check, unlike `claimSlot`. Now
        transactional with the same `slot_full` rejection; return type
        changed `Future<String>` → `Future<Map<String, dynamic>>` to
        carry the result, matching `claimSlot`'s shape.
      - **[MEDIUM, fixed — user chose "fix both now"]** `updateSlot`'s
        full `.set()` could clobber a concurrently-transacted
        `claimedCount`; now a partial `.update()` excluding
        `claimedCount`. `deleteSlot` had no guard against orphaning
        claimed entries; now throws `StateError` if `claimedCount > 0`.
      - **[MEDIUM, deferred]** `_generateJoinCode()` is now a 5th copy of
        an algorithm already duplicated across 4 admin create screens
        (e.g. `lib/admin/vaari/admin_vaari_create_screen.dart:61`).
        Extracting a shared `lib/utils/` helper touches files outside
        this feature's scope — not done without being asked.
      - **[MEDIUM, informational]** `adminAddEntry`/`adminRemoveEntry`
        have no auth check in this layer (client-trust model, same as
        `GroupNamjapService.joinEvent`) — noted as a design input for
        Phase 6 Firestore rules, not fixable at this layer yet.
      - **[LOW, fixed]** Two branch-coverage gaps closed: `claimSlot`'s
        sheet-missing half of its `not_found` check, and `cancelEntry`
        after its slot was already removed some other way.
      - **[LOW, informational]** `cancelEntry`/`adminRemoveEntry` take a
        bare `entryId` with no ownership check — same Phase 6 rules note.
      - Follow-up commits: `474dfd0`/`2b57755` (null-id guard),
        `bace5cd`/`5d9e18f` (capacity guard + stale-overwrite fix +
        orphan guard), `483a7c6` (coverage-only tests).

## Phase 3 — Admin create/edit screen — COMPLETE

- [x] 3.1 Add route constants to `lib/utils/routes.dart`:
      `adminCreateSignupSheet` (and `adminSignupSheetsDashboard`,
      `adminSignupSheetDetail` if not already added when Phase 4 starts).
      Actual: only `adminCreateSignupSheet` added, as scoped — the other
      two are still Phase 4's job.
- [x] 3.2 Failing widget tests for `AdminCreateSignupSheetScreen`: renders
      title/description EN+MR fields, `requiresJoinCode` toggle, an empty
      slot list with an "Add Slot" action; validates required fields
      (title, at least one slot, each slot's label + capacity); adding/
      removing/reordering slot rows updates the list; submit calls
      `createSheetWithSlots` with the right shape; join code is only
      generated when the toggle is on.
- [x] 3.3 Implement `lib/admin/signups/admin_create_signup_sheet_screen.dart`.
      Caught and fixed one bug during TDD: the first pass forgot to
      actually call `generateJoinCode()` in `_submit`, so the "join code
      only generated when toggled on" test failed on the first run — fixed
      before commit, not shipped broken.
- [x] 3.4 If the per-slot row widget grows past ~50 lines inline, extract
      `SlotFormRow` (`lib/admin/signups/widgets/slot_form_row.dart`) —
      per this repo's function/file-size conventions — with its own tests.
      Actual: extracted from the start (clearly would have exceeded 50
      lines inline). No separate SlotFormRow-only test file — it's a
      purely presentational StatelessWidget fully exercised through the
      parent screen's tests (100% line coverage confirmed on both files),
      so a redundant standalone test file was skipped.
- [x] 3.5 l10n: add EN/MR strings for every label/button/validation
      message introduced by this screen (add alongside the screen, not
      deferred to Phase 7 — matches how `ParticipantContactActions` added
      its own `sendTextTooltip` key in the same commit as the widget).
- [x] 3.6 `flutter analyze` + `dart format`; commit test → implement →
      (refactor, if 3.4 applies).
      Actual: 2 commits (`40f9dc6` test, `8e0e0a9` feat — SlotFormRow
      landed in the same feat commit as the screen since it was extracted
      from the start rather than refactored out afterward). 100% line
      coverage on both new files, `flutter analyze` clean, full suite
      (737 tests) green.

## Phase 4 — Admin dashboard + detail screen

- [x] 4.1 Failing tests + implement `AdminSignupSheetsDashboard`
      (`lib/admin/signups/admin_signup_sheets_dashboard.dart`): lists
      `getAllSheets(groupId)`, status filter chips (draft/published/
      closed), tap → detail, FAB → create screen.
      Actual: 100% line coverage on `AdminSignupSheetsDashboard`, 11 widget
      tests, status filter chips, FAB to create sheet, and card navigation
      with arguments.
- [ ] 4.2 Failing tests + implement `AdminSignupSheetDetailScreen`
      overview section (`lib/admin/signups/admin_signup_sheet_detail_screen.dart`):
      sheet info, publish/close status toggle, share button (deep link +
      join code, same WhatsApp/native-share call as Vaari/Parayan),
      **Duplicate** button (calls `duplicateSheet`, navigates to the new
      draft).
- [ ] 4.3 Failing tests + implement the entries section: list entries
      grouped by `slotId` (via `getSlots` + `getAllEntries`, joined
      client-side), fill bars per slot ("42 / 50"), manually add/edit/
      remove an entry (reusing the admin entry-edit dialog pattern from
      `AdminParayanDetailScreen._showParticipantEditDialog`), and
      `ParticipantContactActions` for texting/WhatsApp-ing a devotee
      directly from their entry row.
- [ ] 4.4 Failing tests + implement export/share summary image, reusing
      the `ScreenshotController` + export-card pattern from
      `VaariExportCard`.
- [ ] 4.5 l10n additions alongside each sub-screen (not deferred).
- [ ] 4.6 **Build this screen test-first from the start** — unlike
      `AdminParayanDetailScreen`, which has zero test coverage today (a
      known gap already tracked separately), this new screen should not
      repeat that gap.
- [ ] 4.7 `flutter analyze` + `dart format`; commit per sub-piece (4.1–4.4
      independently) — expect 4-6 commits for this phase.

## Phase 5 — Devotee list + detail + claim dialog

- [ ] 5.1 Wire the group-selection indirection at whatever entry point is
      decided in Phase 7's open items — reusing `GajananMaharajGroupScreen`
      + `GroupScreenConfig` + `GroupSelectionProvider`, no new UI.
- [ ] 5.2 Failing tests + implement `SignupSheetsListScreen`
      (`lib/signups/signup_sheets_list_screen.dart`): lists
      `getActiveSheets(groupId)`.
- [ ] 5.3 Failing tests + implement `SignupSheetDetailScreen`
      (`lib/signups/signup_sheet_detail_screen.dart`): slots with live
      fill status from the `slots` stream, tap an open slot to claim, "My
      Signups" section from `getEntriesByDevice`, cancel action per entry.
- [ ] 5.4 Failing tests + implement `ClaimSlotDialog`
      (`lib/signups/widgets/claim_slot_dialog.dart`): name/phone/email/
      optional note/optional pledge amount (donation slots)/join code
      field (only when `sheet.requiresJoinCode`); reuses the
      confirm-before-submit pattern from `AddStepsDialog` — show what was
      entered, require an explicit Yes before calling `claimSlot`. Cover
      the `slot_full` and bad-join-code error paths with a visible message,
      not a silent failure (this is a user-initiated action with real
      stakes — unlike the WhatsApp/SMS launch's accepted silent no-op).
- [ ] 5.5 l10n additions alongside each sub-screen.
- [ ] 5.6 `flutter analyze` + `dart format`; commit per sub-piece.

## Phase 6 — Firestore rules

- [x] 6.1 Add the `signup_sheets` / `slots` / `entries` rules block to
      `firestore.rules` exactly as drafted in the design doc (§7),
      including the field-restricted `claimedCount` update rule.
      Actual: also resolved the two Phase 2 review items deferred here
      (adminAddEntry/adminRemoveEntry auth gate, cancelEntry entry-
      ownership check) — see design doc §7's "Revised during Phase 6
      design" note. Committed in `81b39e3`. Validated with
      `firebase deploy --only firestore:rules --dry-run` (compiles).
- [ ] 6.2 Manual verification checklist (no automated rules test suite
      exists in this project today, same as Vaari/Parayan) — **not yet
      run against a live/emulated project, still pending**:
  - Non-admin can create/read entries.
  - Non-admin can increment/decrement `claimedCount` within `[0, capacity]`.
  - Non-admin **cannot** write `claimedCount` above `capacity`.
  - Non-admin **cannot** modify `capacity`, `label`, `date`, or any other
    slot field.
  - Non-admin **cannot** delete an entry that has no `deviceId` set.
  - Admin can do all of the above freely.
- [ ] 6.3 **Confirm before deploying** — `firebase deploy --only
      firestore:rules` changes the live production database's access
      rules; treat this as an explicit go/no-go checkpoint, not something
      to run automatically at the end of a coding session.

## Phase 7 — Routing, navigation entry points, deep links

- [ ] 7.1 Resolve the three open items still sitting in
      `docs/signup-sheets-design.md`: devotee entry point, admin entry
      point, slot ordering (sortOrder vs. date) on the devotee screen.
      This phase is blocked on those answers.
- [ ] 7.2 Wire the chosen devotee entry point → group-selection
      indirection (5.1) → `SignupSheetsListScreen`.
- [ ] 7.3 Wire the chosen admin entry point → `AdminSignupSheetsDashboard`.
- [ ] 7.4 Deep link handling in `lib/main.dart`'s `_handleDeepLink` — add
      a `signup` case alongside the existing `vaari`/`parayan`/`namjap`
      cases, so a shared join-code link opens directly to
      `SignupSheetDetailScreen`.
- [ ] 7.5 Final l10n audit: grep for any hardcoded strings that slipped
      through phases 3–5 instead of being added incrementally.
- [ ] 7.6 Full regression pass: `flutter test`, `flutter analyze` across
      the whole touched surface.

## Phase 8 — Explicitly deferred

Not part of this build. Only when you separately ask:
- Retiring the external-link `SignupsScreen` (`lib/signups/signups_screen.dart`)
  and pointing its entry point at the new native list instead.

---

*Leave comments inline and let me know when it's ready to start Phase 1.*

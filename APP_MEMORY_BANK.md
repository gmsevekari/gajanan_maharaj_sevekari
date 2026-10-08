# App Memory Bank: Gajanan Maharaj Sevekari

This document summarizes the key architectural patterns, design principles, and technical details of the "Gajanan Maharaj Sevekari" Flutter application.

---

### 1. Core Assistant Directives (Lessons Learned)

-   **Configuration is King:** The app's architecture must always prioritize being configuration-driven. Any logic that can be moved from hardcoded Dart into a JSON file should be. This includes feature flags, content types, and UI titles.
-   **`.arb` File Precision is Crucial:** When using `.arb` files for localization, I must be extremely careful. Missing placeholder definitions (e.g., `@sankalpGenerated`) or mismatched placeholder types (e.g., `int` vs. `String`) will cause the `flutter gen-l10n` code generation to fail. I must also remember that this command needs to be run (`flutter pub get` or `flutter gen-l10n`) after any `.arb` file changes.
-   **Cross-Platform Packages Require Conditional Logic:** A package that works on mobile might not work on web (e.g., `youtube_player_flutter`). The solution was to use a platform-specific package for web (`youtube_player_iframe`) and wrap both in a `CrossPlatformYoutubePlayer` widget that uses `kIsWeb` to determine which player to render.
-   **Use `flutter run -d chrome` for Web Testing:** When implementing web-specific features (like the 'Download App' banner), I must use `flutter run -d chrome` and the browser's developer tools to simulate mobile devices and test platform-specific logic locally before deployment.
-   **PWA Icons are Separate:** The `flutter_launcher_icons` package does not handle the progressive web app (PWA) icons. These must be manually created (including maskable versions) and placed in the `web/icons/` directory, and the `manifest.json` must be configured to reference them.
-   **Fixing Stale CocoaPods Config:** A common Xcode error, "CocoaPods did not set the base configuration," can be resolved by replacing the optional `#include?` with a direct `#include` for the `Pods-Runner.xcconfig` file in both `Debug.xcconfig` and `Release.xcconfig`.
-   **Clean Flutter SDK for Upgrades:** The `flutter upgrade` command can fail if the Flutter SDK directory itself has local changes. This can be resolved by navigating to the SDK directory and running `git stash` to clean the repository before attempting the upgrade again.
-   **Check All Targets:** When making project-level changes (like Bundle ID), I must remember to check all targets, including `Runner` and `RunnerTests` in Xcode.
-   **Holistic Firebase Configuration:** Updating Firebase requires changing the bundle ID in three places for iOS: the Xcode project (`Runner` and `RunnerTests`), the `GoogleService-Info.plist`, and the `firebase_options.dart` file.
-   **The `Podfile` Sledgehammer:** For stubborn iOS dependency errors related to deployment targets, the most robust solution is a `post_install` script that forcefully sets the `IPHONEOS_DEPLOYMENT_TARGET` for both each individual pod `target` and the overall `pods_project`.
-   **Standard Plugin Registration (iOS):** For iOS, standard Flutter plugin registration via `GeneratedPluginRegistrant.register(with: self)` in `AppDelegate.swift` is the default. However, if using the `FlutterImplicitEngineDelegate` (often for background tasks), registration may be handled via the `didInitializeImplicitFlutterEngine` callback to avoid redundancy.

---

### 2. Project Overview & Core Philosophy

-   **App Name:** `gajanan_maharaj_sevekari`
-   **Purpose:** A devotional app for followers of Indian saints, starting with Gajanan Maharaj, Datta Maharaj, and Sai Baba.
-   **Core Principles:** The app is lightweight, prioritizes an **offline-first approach** for text content, and is almost entirely **configuration-driven**.
-   **Data Contract Philosophy:** The app now follows a **strict data contract**. Content JSON files are expected to have mandatory keys (like `title_mr`, `content_en`). Missing keys will now cause errors during testing, enforcing data quality, rather than failing silently with defaults. The redundant `image` key within individual content JSONs was removed to enforce a single source of truth (the main config files).

### 3. Key Features & Modules

-   **Multi-Deity Architecture:** The app is built to support multiple deities, each with their own configuration file defining their specific content and features.
-   **Region-Specific Features:** The visibility of certain dashboard cards (e.g., "Donations," "Signups") and favorite items is controlled by a `regions` array in the JSON configuration. An empty array means the feature is global; otherwise, it only appears if the user's device region matches a code in the list.
-   **Download App Banner:** A theme-aware banner is displayed at the bottom of the home screen, but only when the app is running on the web. It detects the user's platform (iOS/Android) and redirects them to the appropriate app store to encourage native app installation.
-   **Dynamic "About" Screen:** The title of the "About" screen is now configurable per-deity via an `about_title_key` in the deity's JSON file (e.g., "About Maharaj" vs. "About Baba").
-   **Naamjap (Chanting) Module:**
    -   **Unified Tracking:** Tab 1 (Mala Counting) and Tab 2 (Time-based Jap) share a unified chant counting aesthetic, pulling colors dynamically from `Theme.of(context)` down to the dialog modals.
    -   **Timer Persistence:** The Time-based Jap tab (Tab 2) persists user-selected Hours and Minutes between sessions using `SharedPreferences`.
    -   **Numeral Localization (`_formatNumber`):** Flutter defaults to casting format modifiers like `Duration` and `SnackBar` numerical `{count}` payload variables as raw base-10 integers. These must be explicitly wrapped in `_formatNumber(context)` on both UI dropdowns and `.arb` file parameter payloads (typed properly as `String` in the `.arb`) to ensure characters translate gracefully to Hindi/Marathi glyphs.
    -   **UI Refinement:** To support varied device sizes, the counting tiles on the 1st tab use reduced vertical padding and font sizes.
    -   **User Awareness:** A persistent reminder message encourages users to keep their screen on during chanting to prevent the device from sleeping and interrupting the count/timer.
-   **Temple Notifications & Admin Module:**
    -   **FCM Integration:** The app uses Firebase Cloud Messaging for broadcasting temple-wide alerts (e.g., Palkhi updates) via the `temple_notifications` topic.
    -   **Admin System:** A secure admin login and dashboard allow moderators to draft and send push notifications directly from the app.
    -   **Local Notifications:** Uses `flutter_local_notifications` to provide a consistent experience for foreground messages across Android and iOS, including custom actions like "Mark as Read" or "Open Link".
    -   **Notification History:** The `UserNotificationsScreen` provides a persistent archive of all received temple notifications, automatically clearing unread badges when opened.
-   **Typo Reporting Feature:**
    -   **Crowdsourced Accuracy:** Users can report typos or content errors in any text-based content (stotras, bhajans, etc.) to ensure the digital library remains accurate and high-quality.
    -   **Trigger Mechanism:** Reports can be initiated by long-pressing specific text in `ContentDetailScreen` (which pre-fills the "Incorrect Text" field) or by tapping the flag icon in the AppBar.
    -   **Data Captured:** `TypoReport` model includes `contentPath`, `contentTitle`, `deityId`, `typoText`, `suggestedCorrection`, and `deviceId` for audit trailing.
    -   **Admin Review Module:** Reports are sent to the `typo_reports` Firestore collection and appear in the `AdminTypoReportsScreen`. Admins can view, verify, and dismiss reports once the underlying JSON content is fixed.
    -   **FCM Alerts for Admins:** Admins with the appropriate permissions can toggle "Typo Notifications" in their dashboard. This subscribes them to the `admin_typo_reports` FCM topic, receiving real-time alerts whenever a new report is submitted.
-   **Parayan (Group Scripture Reading) Module:**
    -   **Overview:** Parayan is a community-driven scripture reading event where participants are assigned specific chapters (adhyays) of a holy text. The app manages the entire lifecycle: event creation → enrollment → allocation → tracking → completion.
    -   **Event Types (`ParayanType` enum):**
        -   `oneDay` — Single-day parayan with 21 adhyays per group.
        -   `threeDay` — Multi-day parayan with 7 adhyays per group (per day).
        -   `guruPushya` — Special occasion parayan, behaves like 1-day structurally.
    -   **Event Lifecycle (`ParayanEvent.status`):**
        -   `upcoming` → `enrolling` → `allocated` → `ongoing` → `completed`.
        -   Transitioning to `allocated` triggers the `allocateParayanAdhyays` Cloud Function that assigns adhyays to participants.
        -   Transitioning to `completed` unsubscribes devices from reminder topics.
    -   **Data Models:**
        -   `ParayanEvent` (`lib/models/parayan_event.dart`): Firestore collection `parayan_events`. Contains bilingual titles/descriptions, type, start/end dates, status, `reminderTimes` list (e.g., `["20:00", "21:00"]`), and `sentReminders` map for tracking which reminders have been dispatched.
        -   `ParayanMember` (`lib/models/parayan_participant.dart`): Stored in `parayan_events/{eventId}/participants` subcollection. **Flattened format** with top-level fields: `memberName`, `name` (backward compat), `assignedAdhyays` (List<int>), `completions` (Map<String, bool> keyed by day index), `deviceId`, `phone`, `globalIndex`, `groupNumber`, `joinedAt`.
        -   `ParayanHousehold`: A logical grouping of members from the same device. `fromFirestore` detects both flattened (new) and nested `members` map (legacy) formats.
    -   **Firestore Document Structure (Current — Flattened):**
        -   Doc ID: `{deviceId}_{memberName}` (spaces replaced with underscores).
        -   Top-level fields: `memberName`, `name`, `assignedAdhyays`, `completions`, `joinedAt`, `deviceId`, `phone`, `globalIndex`, `groupNumber`.
        -   **Important:** The old nested household format (doc ID = device ID only, with a `members` map) is NOT supported by `getAllParticipants()` or `getParticipantsByDevice()`. Use only the flattened format.
    -   **Service Layer (`ParayanService` — `lib/providers/parayan_service.dart`):**
        -   `enrollParticipants()`: Creates/updates flattened member docs. Queries existing docs by `deviceId` to handle edits/deletions. Max 5 members per household.
        -   `getAllParticipants(eventId)`: Returns a stream of all members, ordered by `joinedAt`. Used by the public allocation table.
        -   `getParticipantsByDevice(eventId, deviceId)`: Returns members for a specific device. Used by the "My Allocation" tab.
        -   `getHousehold(eventId, deviceId)`: Fetches all member docs for a device and wraps them in a `ParayanHousehold`. Used for edit mode in signup.
        -   `updateMemberCompletion()`: Updates `completions.$dayIndex` in Firestore. Handles FCM topic unsubscribe when all household members complete a day.
        -   `allocateAdhyays(eventId)`: Calls the `allocateParayanAdhyays` Cloud Function.
        -   `adminAddParticipants()`: Calls the `adminAddParticipants` Cloud Function for bulk admin additions.
    -   **User-Facing Screens (`lib/parayan/`):**
        -   `ParayanListScreen`: Two tabs — Upcoming and Completed. Shows all events from Firestore with calendar export action.
        -   `ParayanDetailScreen`: The main event page. Shows event info header, participant count, Join/Edit button (disabled on web via `kIsWeb`). Has a dynamic `TabController` that shows 1 tab (Allocation) if not registered, or 2 tabs (Allocation + My Allocation) if registered. Registration is detected via a live stream on `getParticipantsByDevice`.
        -   `AdhyaysAllocationTab`: Public table of all participants with their assigned adhyay numbers. Uses a `Table` widget with alternating row colors. For 1-day events, shows `Name | Adhyay#`. For 3-day events, shows `Name | Day1 | Day2 | Day3`.
        -   `MyAllocationTab`: Shows only the current device's members. Each member gets a card with checkboxes per day to mark completion. Tapping the adhyay number navigates to the `ContentDetailScreen` to read the actual chapter text.
        -   `ParayanSignupScreen`: Form with dynamic name fields (add/remove, max 5), phone with country code selector (`+1`, `+91`, etc.), and validation (Unicode regex `\p{L}\p{M}\p{Nd}\s`, duplicate name check within household). Supports both new enrollment and edit mode (pre-fills from `existingEnrollment`). Returns `true` on success, `{'deleted': true}` on deletion.
    -   **Admin Screens (`lib/admin/`):**
        -   `ParayanCoordinationDashboard`: Lists all events grouped by Active/Completed with live participant counts. Entry point for creating new events and managing existing ones.
        -   `CreateParayanScreen`: Form for creating a new `ParayanEvent` with bilingual title/description, type picker, date/time pickers, and reminder time configuration.
        -   `ParayanAdminDetailScreen`: The main admin management screen. Two tabs — "Overview" (allocation table with status controls and export) and "Members" (filterable participant cards with all/completed/pending filters). Features:
            -   Status progression buttons (e.g., "Start Enrollment" → "Allocate" → "Mark Ongoing" → "Complete").
            -   Export functionality using `screenshot` package to capture group allocation cards as PNG images for sharing via `share_plus`.
            -   1-Day export: `_buildExportableGroupCard` — one group per image with serial number column, centered adhyays, group+date in same row, "Jai Gajanan" footer.
            -   3-Day export: `_buildExportableThreeDayBatchCard` — up to 3 groups per image with a unified grid, actual dates as column headers, and group separator rows.
            -   Manual ping button to trigger reminder Cloud Functions.
            -   Admin add participants screen for bulk manual additions.
        -   `ParayanAdminAddParticipantsScreen`: Allows admins to manually add participants via Cloud Function, bypassing the normal signup flow.
    -   **Notification Integration:**
        -   On enrollment, the app subscribes the device to per-event, per-day FCM topics (e.g., `parayan_{eventId}_day1_reminder`).
        -   On completion of all household members for a day, the device unsubscribes from that day's topic.
        -   Topic subscription respects the user's `parayanRemindersPrefKey` preference in `SharedPreferences`.
        -   Event completion unsubscribes from all event topics via `NotificationServiceHelper.unsubscribeFromEventTopics`.
-   **Sign-Ups (`signups/{id}` with `slots` and `entries` subcollections):**
    -   **Models:** `Signup`, `SignupSlot` (`lib/models/signup_slot.dart`: `startAt`/`endAt` UTC instants plus a per-slot `timezone`, shown in the slot's own zone, PT/IST only), `SignupEntry` (`lib/models/signup_entry.dart`: `slotId`, `name`, `phone` (stored as digits only, country code then number, no `+`: `joinPhone`/`splitPhone` in `phone_utils.dart`; older entries may still have a `+` or no country code), `email`, `deviceId`, `pledgeAmount`, `note`, `joinedAt`; `max*` constants mirror the Firestore rule limits). An admin-added entry has `deviceId == null`; an empty `deviceId` also counts as "no device".
    -   **Service:** `SignupService` (`lib/providers/signup_service.dart`): `claimSlot` / `adminAddEntry` (capacity transaction, duplicate guard), `cancelEntry`, `updateEntry` (admin; never writes `slotId`, `deviceId` or `joinedAt`), `updateOwnEntry` (devotee; writes only name/phone/email/pledge/note and only checks a phone/email for duplicates in the slot when it *changed*), `claimMyEntries` (calls the Cloud Function below), `releaseEntryDevice` (admin).
    -   **My Sign Ups (`lib/signups/my_signups_screen.dart`):** Upcoming/Past tabs of the device's entries (`getEntriesByDevice`).
        -   **Edit** (Upcoming only) opens the shared `SignupEntryEditDialog` (`lib/signups/widgets/`, also used by admins) with `requirePhone: true` and `showContactActions: false`. `onSave` returns an error string, which keeps the dialog open with the input.
        -   **Claim My Sign Up** button above the tabs opens `ClaimMySignupDialog`: country code + phone, plus the join code only when the sign-up `requiresJoinCode`. Refusals (not found, already claimed, wrong join code, failure) show inline; the dialog can't be dismissed mid-claim.
    -   **Cloud Function `claimSignupEntries` (`functions/signups.js`):** links entries to a device. Phone must match **exactly** as digits only (country code + number; a plus, spaces and dashes are ignored; no tolerance for a missing country code). Join code checked server-side. If **any** matching entry belongs to a different device the whole claim is refused (`ALREADY_CLAIMED`) and nothing is written. Runs in a transaction; returns only `status` (`SUCCESS` + `count`, `NOT_FOUND`, `ALREADY_CLAIMED`, `INVALID_JOIN_CODE`); sets `deviceId` and `claimedAt`. Capped at 10 instances.
    -   **Admin "Release Device Link"** (in the admin edit dialog, only for entries with a non-empty `deviceId`) clears `deviceId` and `claimedAt` so the devotee can claim the entry again from another device.
    -   **Firestore rules for `entries`:** `create` is validated (`isValidEntryDetails`); a non-admin may `update` only `name`, `phone`, `email`, `pledgeAmount`, `note`, and only on an entry with a non-empty `deviceId`; `slotId`, `deviceId`, `joinedAt` are admin/function-only. `delete` is allowed for any entry with a `deviceId`. Rules tests: `firestore-rules-test/signups.test.js` (run with `firebase emulators:exec --only firestore`).
    -   **Admin editing (sign-up details page and Slots page; no rules or functions involved, admins can already write):**
        -   **Edit sign-up** (`AdminEditSignupScreen`, from the Edit button on the overview card): English/Marathi title and description, and the join-code switch. `SignupService.updateSignupDetails` writes **only the fields that changed** and decides a join-code change in a transaction against the live document: switching on keeps a code another admin already made (a code left over from before it was switched off is replaced), switching off clears it. The header image, status and group are edited elsewhere on the details page; `updateSignup` (whole-document `set`) is unused by the UI on purpose.
        -   **Edit / Add slot** (`AdminEditSlotScreen`, `.add` for a new one; FAB and per-card Edit on `AdminSignupSlotsScreen`): label, capacity, suggested amount, dates/times, timezone. It reuses `SlotFormRow`; `slotScheduleInputFromInstants` turns a saved slot back into form input, and an untouched schedule keeps its exact saved instants and timezone. `SignupService.updateSlot` is a transaction that refuses a capacity below the live `claimedCount` (`SlotCapacityBelowClaimedException`) and never writes `claimedCount`, `sortOrder` or `createdAt`. A new slot goes after every existing one, in the last slot's timezone (or the group's default).
        -   **Delete slot** (button on each card): confirms, and is refused when anyone has signed up. `SignupService.deleteSlot` checks both the slot's `claimedCount` (in the delete transaction) and the entries actually on the slot, because the counter can drift from the entries (`SlotHasClaimedEntriesException`).
        -   The Slots page lists slots by date (`SignupSlot.compareByStart`, then id), like the Entries page.
        -   **Delete sign-up** is on the overview card, beside Edit (`SignupOverviewCard.onDelete`, key `deleteSignupButton`); it opens a "Delete Sign Up?" confirm (Cancel / red Delete) before `SignupService.deleteSignup`. The actions grid below is Duplicate, Share, Export Summary, Export Sign Ups.
        -   **Export Sign Ups** (`_exportSignupEntries` in `AdminSignupDetailScreen`): `showExportSlotsDialog` lists the **upcoming** slots (not past, soonest first, undated last; all ticked, with Select all), then `SignupEntriesExportCard` (the devotee `SignupEntriesTable`: Date / Title / Name only, never phone/email/pledge/note) for the ticked slots is rendered **off-tree** with `ScreenshotController.captureFromLongWidget` and shared as `signup_entries_<id>.png`. `paginateSignupExport` (`signup_entries_export_pages.dart`) splits a long list into several images (whole slots per page, estimated height <= 3600 dp, labelled "Part n of m", all shared in one share sheet) and picks each page's pixel ratio (2, down to 1 for one very long slot) to stay under an 8000 px texture. An off-tree widget has no app theme/localizations, so `SignupEntriesExportCard.scoped(context, card)` re-supplies the theme, English localizations and content language, and pins text scale to 1 (the image is measured once and drawn once; a different scale between the two would cut it off). Tests inject `entriesExportCapture`. Known limit: one slot with well over ~120 entries still exceeds the texture limit (a slot is never split) and the export reports a failure.
        -   `UnsavedChangesGuard` (`lib/admin/signups/widgets/`) asks "Discard changes?" when leaving an edit screen with unsaved changes (back button and Android back; not the iOS edge swipe).
    -   **Sign-up slot reminders (a push 1 day and 1 hour before a slot a devotee signed up for; design: `docs/signup-reminders-plan.md`):**
        -   **Sending (`functions/signupReminders.js`, `sendSignupReminders`, every 10 min, `maxInstances: 1`, `retryCount: 0`, 300 s timeout):** a collection-group query on `slots.startAt` for the next 24 h, then per slot: the **day** reminder is due 24 h to 23.5 h before the start and the **hour** reminder 60 to 30 min before (windows are wider than the schedule so a missed run is covered; narrow enough that a late sign-up gets no "tomorrow" push). An **all-day** slot (00:00-23:59 in its zone) gets only the day reminder, at **9 AM the day before** in the slot's zone, never at midnight. Only **published/closed** sign-ups. A slot is skipped unless an **entry on it has a `deviceId`** (read from the entries; never use `claimedCount` as "someone signed up": the rules let anyone nudge it +-1, so it can be driven to 0). The sign-up and entries are read only for a slot that is actually due.
        -   **Message:** always **English** whatever the app language (`titleEn`/`labelEn`, falling back to Marathi only if blank), three short lines: `<group> - <sign-up>`, `Slot: <slot>`, then one line with start and end in the slot's zone (`Sat, Oct 10, 9:00 AM - 11:00 AM PT`; `PT`/`IST`). Group names come from `functions/groups.js`, which a test keeps equal to `resources/config/app_config.json` (the server can't read the bundled asset): add a group in both. Data `{type: SIGNUP_REMINDER, signup_id, slot_id}`, Android channel `signup_reminders`, `apns` alert block. Nothing personal is ever in it, and it is **not** written to the global `notifications` inbox (every user would see it).
        -   **One successful send per reminder:** two records on the slot document, written with the Admin SDK only (the rules reject any non-admin write): `reminderAttempts.<day|hour>` = `{start, at, id}` ("being sent") and `reminders.<day|hour>` = the `startAt` ms it was sent for. A transaction records the attempt first (refused if already sent, the slot moved, or another run's attempt is under 6 min old); a failed or 60 s-timed-out send gives the attempt up so the next run retries; a success writes `reminders` (in a transaction, only while the slot still starts at that time) and closes the attempt; a run killed mid-send leaves an attempt that expires after 6 min and is retried. Moving a slot's time re-arms both reminders. `SignupService.updateSlot` is a partial `update` and `duplicateSignup` goes through the model, so neither copies or wipes these records (tests pin that). **Residual duplicate cases** (FCM has no idempotency key): the push was accepted but the reply lost; the function died after FCM accepted it but before recording; recording failed twice (counted in the run's `unrecorded` and logged). The retry budget is the reminder's 30-minute window, about 3 runs.
        -   **Subscribing (`lib/notifications/signup_reminder_subscriptions.dart`):** topic `signup_slot_<signupId>_<slotId>` (`NotificationConstants.getSignupSlotReminderTopic`, same vector as the server's test). A device is on a slot's topic exactly while an entry on it is linked to its `deviceId`, the slot has a schedule and isn't over. An entry an admin adds (`adminAddEntry`, no `deviceId`) never subscribes the admin's phone. `syncSignup(signupId)` runs after claiming a slot, after "Claim My Sign Up", after cancelling and when My Sign Ups opens; `syncAll()` runs 5 s after start-up from `NotificationServiceHelper.processOnStartup` and finds **every entry linked to the device** with one collection-group query (so entries from before the feature, or before a reinstall, are found), renews valid subscriptions, lets go of ended ones and retries failed unsubscriptions. Everything it believes is read from the **server** (`SignupService.fetchEntriesByDevice`/`fetchSlots`/`fetchEntriesForDevice`, `Source.server`), never the cache; if the server can't be reached it changes nothing. All public methods run one at a time across the app (one shared queue); prefs `signup_reminder_wanted` and `signup_reminder_stale` (a topic goes on the stale list *before* it is unsubscribed); an unreadable store is discarded and rebuilt. Known limit: an entry an admin removes or unlinks keeps that device subscribed until it next opens My Sign Ups or restarts.
        -   **Showing it (`notification_channels.dart`, `notification_routing.dart`, `notification_manager.dart`):** only the `signup_reminders` Android channel is created (at start-up, last, not awaited); the other channels the server names (`temple_notifications`, `parayan_notifications`, `admin_notifications`) are still **not** created (see Known Follow-ups). When the app shows a push itself, sign-up reminders use that channel (`NotificationChannels.detailsFor`) and a payload `signup:<id>`. Tapping a sign-up reminder opens `Routes.signupDetail` with `{'signupId'}` (system-shown pushes via `onMessageOpenedApp`/`getInitialMessage`, app-shown via the payload; `setPendingTarget` keeps the pending route and its arguments together for the splash screen); everything else still opens the inbox.
        -   **Controls:** "Sign-up Reminders" switch in Notification Settings (`signup_reminders_pref`, default on; the choice is saved at once, then `SignupReminderSubscriptions.setEnabled`), separate from the parayan switch. A one-time hint (`SignupReminderPermissionHint`) after signing up or claiming when notifications are blocked or never asked about, with Allow / Open Settings; worded in English like the screens it appears on.
        -   **Rules and indexes (deploy before releasing the app):** `match /{path=**}/entries/{entryId}` allows a collection-group **read** only (entries were already publicly readable one sign-up at a time); indexes `slots.startAt` and `entries.deviceId` (collection-group) in `firestore.indexes.json`. Order: indexes first (wait until Enabled), then rules, then `firebase deploy --only functions:sendSignupReminders`. Without the rule/index the app falls back to re-checking only the sign-ups it already knows. The file is kept equal to `firebase firestore:indexes`, so deploys no longer offer to delete console-made indexes and the notifications/audit-log TTL policies.
    -   **Trust model:** devotees aren't authenticated, so rules can only see "the entry has a device", not which one. `signups/*` (including `joinCode`) and entries (phone, email, `deviceId`) are publicly readable, so the join code and phone number are friction, not secrets.
-   **Generic List & Detail Screens:**
    -   `ContentListScreen`: A single, powerful, reusable screen that displays lists of content (stotras, bhajans, aartis, etc.). It is driven entirely by configuration.
    -   `ContentDetailScreen`: A highly reusable screen for displaying text and video content. It now uses a strict data contract and expects `title` and `content` keys to be present in the JSON.

### 4. Technical Stack & Architecture

-   **Framework:** Flutter.
-   **State Management:** `provider` package.
-   **Localization:** The project uses the standard Flutter internationalization approach with `.arb` (Application Resource Bundle) files.
    -   **Source Files:** `lib/l10n/app_en.arb` (English) and `lib/l10n/app_mr.arb` (Marathi).
    -   **Configuration:** A `l10n.yaml` file in the project root configures the code generation, specifying the input directory and template file.
    -   **Code Generation:** Running `flutter pub get` or `flutter gen-l10n` generates the necessary `AppLocalizations` class.
-   **Video Playback:**
    -   A custom `CrossPlatformYoutubePlayer` widget was created in `lib/shared/` to handle platform differences.
    -   It uses `youtube_player_flutter` for the native experience on Android/iOS.
    -   It uses `youtube_player_iframe` for web compatibility.
-   **Deep Linking:**
    -   Uses the `app_links` package for cross-platform support (Universal Links on iOS, App Links on Android).
    -   A centralized `DeepLinkManager` (`lib/utils/deeplink_manager.dart`) handles the parsing, deduplication, and pending navigation logic.
-   **Flexible Data Models (`app_config.dart`):**
    -   **Centralized `ContentType` Logic:** A `ContentTypeExtension.fromString()` method on the `ContentType` enum provides a single, central place to convert the `contentType` string from the JSON into the correct Dart enum, removing duplicated logic from UI screens.
    -   **Flexible Aarti Structure:** The `NityopasanaConfig` can handle two different JSON structures for `aartis`: a category-based list (for Gajanan Maharaj) and a direct, flat list of files (for Datta Maharaj).
    -   **Optional Sections:** The `DeityConfig` uses nullable properties (`DonationInfo?`, `SignupInfo?`) to gracefully handle deities that do not have these sections in their JSON, preventing crashes.

### 5. Build & Deployment

-   **Git Configuration**:
    -   The `.firebaserc` file is committed to the repository to ensure all developers deploy to the correct Firebase project.
    -   The `.firebase/` directory is added to `.gitignore` to prevent local user credentials and cache from being committed.
-   **Web Deployment**:
    -   The `web/index.html` file has been updated to use the modern `_flutter.loader.load()` initialization script, resolving deprecation warnings.
    -   A `sitemap.xml` is maintained in the `web/` directory for SEO, with URLs generated from the app's content structure.
    -   The `web/manifest.json` file is configured with the app's name, description, theme colors, and icons to ensure a correct PWA installation experience.
-   **Android Signing:**
    -   A private `upload-keystore.jks` is used for signing.
    -   Passwords are read from a `key.properties` file, which is ignored by git.
    -   The `android/app/build.gradle.kts` (Kotlin DSL) is configured to use these properties for release builds.
-   **iOS Configuration:**
    -   The iOS deployment target is set to **15.0**.
    -   The `ios/Podfile` contains a `post_install` script to enforce the deployment target across all pod libraries and the main pod project, resolving version conflicts.
    -   The `PRODUCT_BUNDLE_IDENTIFIER` is set to `com.gajanan.maharaj.sevekari` for the main `Runner` target and `com.gajanan.maharaj.sevekari.RunnerTests` for the test target.
-   **Firebase Cloud Functions:**
    -   Node.js functions (v2) handle triggered notifications on Firestore document creation.
    -   APNS payloads are configured with `contentAvailable: true` and specific background priority headers to ensure reliable delivery to backgrounded iOS devices.
    -   **Deploy order for sign-up changes:** `firebase deploy --only firestore:rules`, then `firebase deploy --only functions:claimSignupEntries`, then ship the app build; without them Edit / Claim show an error message. Function tests: `cd functions && npm test` (mocha + sinon, `test/signups.test.js`).

---

### 6. Multi-Theme Preset System

-   **Architecture:** The app supports multiple color palettes (Saffron, Maroon, Sandalwood, Indigo, Tulsi, Kumkum, Lotus, Peacock, Custom) via a `ThemePreset` enum and a `getTheme(ThemePreset preset, bool isDark)` factory method in `AppTheme`.
-   **Expanded Palette:**
    -   **Tulsi:** Green (#2E7D32)
    -   **Kumkum:** Dark Red (#E53935)
    -   **Lotus:** Pink (#E91E90)
    -   **Peacock:** Deep Teal/Blue (#00897B)
-   **Color-Tinted Dark Mode:** Dark modes are no longer flat black/grey. They are algorithmically "tinted" based on the primary color of the theme (e.g., a deep green-black for Tulsi). This is achieved via `_deriveThemeColors` using HSL transformations to maintain consistent vibrant aesthetics across all presets.
-   **Dynamic Custom Theme Generator:** Users can select any base color from a picker. The `AppTheme` then derives a complete `ThemeData` (MaterialColor swatch, surface colors, shadows, etc.) on the fly, allowing for unlimited personalization while maintaining the app's structural styling.
-   **Preserve-and-Clone Pattern:** The original `lightTheme` and `darkTheme` (Saffron/Orange) remain the byte-for-byte source of truth. All other themes are clones with swapped indices.
-   **State Persistence:** `ThemeProvider` manages both `ThemeMode` and `ThemePreset`, persisting the selected preset (and custom color hex) to `SharedPreferences`.

### 7. Parayan Management & Export

-   **Editable Signups:** Participants can now edit their enrollment (add/remove names, change phone) as long as the event status is `enrolling`. Once the status moves to `allocated` or higher, edits are disabled to prevent data inconsistency with assignments.
-   **Responsive Allocation Table:** The allocation table in `ParayanDetailScreen` was refactored from `DataTable` (which has fixed size limits) to a `Table` widget with `FlexColumnWidth`. This ensures the table spans the full screen width and scales gracefully on tablets and landscape orientations.
-   **1-Day Export Card (`_buildExportableGroupCard`):** Includes a localized serial number column, centered adhyays, and a space-saving header where group labels and dates share a single row.
-   **3-Day Export Card:** Up to 3 groups are batched into a single grid image for easier sharing on platforms like WhatsApp.

### 8. Admin Dashboard & RBAC

-   **Role-Based Access Control (RBAC):** The admin dashboard is now protected by a role-based system.
-   **Firestore Source:** The `admin_allowlist` collection defines permissions per email.
-   **Dynamic Module Filtering:** Modules (Temple Notifications, Parayan Coordination, Typo Reports) are only visible if the logged-in admin has the required role (e.g., `temple_admin`, `parayan_coordinator`).
-   **Audit Logging:** Critical admin actions (sending notifications, starting allocations) are logged via `AdminAuditService` for accountability.

### 9. Deep Linking & App Initialization

-   **Stability Improvements:** To fix race conditions where deep links were missed during cold boots, the initialization sequence in `main.dart` was made strictly sequential.
-   **Readiness Signaling:** The `App` widget now waits for a "readiness signal" from core providers before attempting to process the initial deep link, ensuring the navigation stack is fully mounted and ready to receive the destination route.
-   **Universal/App Links:** Supports `gmsevekari.com` deep links for navigating directly to specific Parayan events or temple alerts.

### 10. Remote App Update Mechanism

-   **Update Logic (`UpdateService`):** distinguish between `forced` (mandatory) and `recommended` updates using `pub_semver`. `forced` updates lock the UI until the user upgrades.
-   **Web Behavior:** Explicitly skipped via `!kIsWeb` as web users always receive the latest bundle.
-   **Deployment UI:** `UpdateDialog` uses themed, left-aligned version containers with localized Marathi numerals for consistency.

---

### 11. Critical Bug Fixes & Gotchas (Lessons Learned)

-   **Flutter `Color` API Breaking Change (`_createMaterialColor`):** In Flutter 3.27+, `Color.r`, `.g`, `.b` return **normalized doubles** (0.0–1.0). **CRITICAL:** Multiplying by 255 and rounding is mandatory before using these values as integer channel inputs; otherwise, themes will render as pure black.
-   **Firestore Document Format Consistency:** Enrollment documents must use the **flattened format**. Nested maps are deprecated and unsupported by the current query architecture.
-   **Deep Link Race Conditions:** Never attempt to navigate based on an incoming link during the first frame of `main()`. Always wait for the `MaterialApp` to be fully built and providers to be initialized.
-   **Never write `deviceId` from an admin edit:** a devotee's claim and an admin's release both change `deviceId`; an admin form opened earlier would silently undo them. `SignupService.updateEntry` therefore drops `deviceId` and `joinedAt` from its write.
-   **Admin edits must be field-level, never a form snapshot:** a screen opened earlier holds stale values. Send only the fields the admin changed (`updateSignupDetails`) and keep owner-controlled fields out of the write (`updateSlot` skips `claimedCount`, `sortOrder`, `createdAt`; `updateEntry` skips `deviceId`, `joinedAt`). A guard that depends on a counter (`claimedCount`) should also check the real documents, since the rules don't tie them together.
-   **Widget tests with fake Firestore:** read seeded documents with `get()` in a test that pumps a widget afterwards. A leftover `snapshots().first` stream (e.g. `SignupService.getSignupById(id).first`) can make `pumpWidget` never return, and the fake's snapshot stream can lag a transaction.
-   **Keep input limits in step with the rules:** Firestore rejects name ≥ 100, email ≥ 200, note ≥ 500, phone ≥ 30 characters and pledges outside 0–1,000,000. Use `SignupEntry.maxNameLength` etc. and `parsePledgeAmount` (rejects NaN/Infinity) so a form never passes input the rules will refuse.
-   **Never use a client-writable counter as server-side truth:** the rules let anyone change a slot's `claimedCount` by +-1, so it can be driven to 0. The reminder function checks the entries (`deviceId`) instead.
-   **Decide from the server, not the cache:** a Firestore `snapshots().first` or default `get()` can return an empty cached copy that looks like "no entries". Anything that unsubscribes or deletes on the strength of a read (sign-up reminder subscriptions) must use `Source.server` and change nothing if it can't be reached.
-   **At-least-once-until-success sending needs two records:** a single "sent" marker written before the send loses the reminder if the run dies; one written after allows duplicates. Record an *attempt* (with an expiry), then *sent*; give the attempt up on failure. See the sign-up reminders entry.
-   **Mutation-check weak spots in tests that stub time or Firestore:** a fake store that hands out live objects, applies transactions instantly or ignores `NOT_FOUND` hides real races; copy on read and throw like the real thing (see the reminder tests).
-   **Adding a `testWidgets` to a file of plain `test`s initialises the test binding** and can change unrelated tests in that file (e.g. platform locale lookups); put widget tests in their own file.
-   **`??` vs `.isEmpty`:** Always remember that `??` only catches `null`. Firestore fields that exist but are empty (`""`) will bypass null-coalescing fallbacks. Use `.trim().isEmpty` checks for robust UI text handling.

### 12. Known Follow-ups (not done yet)

-   **Create the existing Android notification channels.** The server names `temple_notifications`, `parayan_notifications` and `admin_notifications`, but the app only creates `signup_reminders`. Until the others are created, parayan and admin pushes that arrive while the app is closed are shown under Android's default channel, and the foreground handler (`NotificationChannels.detailsFor`) shows everything except sign-up reminders under `temple_notifications`. Fix: create all channels at start-up and pick the channel from the message.
-   **Stop writing parayan reminders to the global `notifications` collection.** `sendParayanReminders` (`functions/notifications.js`) adds a document there for every reminder, and `UserNotificationsScreen` lists every document in it to every user, including people not enrolled in that parayan. Fix: make the inbox per-user (or filter by enrolment) and stop the global write.

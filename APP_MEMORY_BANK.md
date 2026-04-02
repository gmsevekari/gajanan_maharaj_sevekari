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

---

### 6. Multi-Theme Preset System

-   **Architecture:** The app supports multiple color palettes (Saffron, Maroon, Sandalwood, Indigo) via a `ThemePreset` enum and a `getTheme(ThemePreset preset, bool isDark)` factory method in `AppTheme`.
-   **Preserve-and-Clone Pattern:** The original `lightTheme` and `darkTheme` (Saffron/Orange) are kept **byte-for-byte untouched** as static fields. For the `saffron` preset, `getTheme()` returns these originals directly. For other presets, it creates a **structurally identical** `ThemeData` copy, swapping only the color constants (primary swatch, card background, borders, shadows, icons, buttons).
-   **AppColors Extension:** Theme-scoped custom colors are accessed via `theme.appColors.primarySwatch`, `theme.appColors.surface`, etc. The `AppColors` class extends `ThemeExtension<AppColors>` and is injected into every `ThemeData` via `extensions`.
-   **State Persistence:** `ThemeProvider` manages both `ThemeMode` (light/dark/system) and `ThemePreset`, persisting the selected preset to `SharedPreferences` under the key `theme_preset`.
-   **Main Entry Point:** `main.dart` calls `AppTheme.getTheme(themeProvider.themePreset, false/true)` to inject the appropriate `ThemeData` into `MaterialApp.theme` and `MaterialApp.darkTheme`.
-   **Theme Selection UI:** `theme_selection_screen.dart` has two sections: (1) Light/Dark/System mode picker (existing), and (2) a Color Palette grid with circular swatch previews for each preset.
-   **Localization Keys:** `colorPalette`, `themeSaffron`, `themeMaroon`, `themeSandalwood`, `themeIndigo` are registered in both `app_en.arb` and `app_mr.arb`.

### 7. Parayan Export Screenshot Layout

-   **1-Day Export Card (`_buildExportableGroupCard`):** The export snapshot for 1-day parayana now includes:
    -   A **serial number (#)** column as the first column, starting at 1 per group (localized via `_formatNumberInternal` for Marathi numerals).
    -   **Centered adhyay numbers** using `textAlign: TextAlign.center`.
    -   **Group label and date on the same row** — group pill on the left, date label on the right — saving vertical space.
    -   Increased bottom padding (`EdgeInsets.fromLTRB(24, 24, 24, 32)`) and a trailing `SizedBox(height: 8)` after the "Jai Gajanan" footer to prevent clipping during screenshot capture.
-   **Container width** was increased from `400` to `420` to accommodate the new serial number column.

---

### 8. Critical Bug Fixes & Gotchas (Lessons Learned)

-   **Flutter `Color` API Breaking Change (`_createMaterialColor`):** In newer Flutter versions (3.27+), `Color.r`, `.g`, `.b` return **normalized doubles** (0.0–1.0), NOT integers (0–255). Code using `color.r.toInt()` will silently produce `0` for all channels, making every generated `MaterialColor` swatch shade pure black. The fix is `(color.r * 255).round()`. This caused non-saffron theme text and selected cards to appear completely black.
-   **Firestore Document Format Consistency:** Enrollment documents in the `participants` subcollection MUST use the **flattened format** with top-level `memberName`, `name`, `assignedAdhyays`, `completions`, and `deviceId` fields. The old nested `members` map format (where the doc ID was the device ID and member names were map keys) is **not supported** by `getAllParticipants()` or `getParticipantsByDevice()`. If stale household-format documents are found in Firestore, they should be migrated/fixed directly in the Firestore console rather than adding backward-compatibility code.
-   **Null-Coalesce (`??`) Does Not Catch Empty Strings:** Dart's `??` operator only falls through on `null`. If a Firestore field contains `""` (empty string), `data['memberName'] ?? data['name'] ?? fallback` will stop at the empty string and never reach the fallback. Keep this in mind when debugging "missing" display text — the field might exist but be empty.

---

### 9. Remote App Update Mechanism

-   **Overview:** The app includes a remote-controlled update check that runs on `HomeScreen` startup. It distinguishes between `forced` (mandatory) and `recommended` updates based on version comparisons stored in Firestore.
-   **Firestore Schema (`app_config/version`):**
    -   The document contains platform-specific maps (`android`, `ios`).
    -   Fields: `latest_version` (String), `min_version` (String), `store_url` (String).
-   **Update Logic (`UpdateService`):**
    -   Uses `pub_semver` for robust version comparison.
    -   `forced`: If `currentVersion < minVersion`. The dialog blocks usage and closes the app on back-press via `SystemNavigator.pop()`.
    -   `recommended`: If `currentVersion < latestVersion`. The dialog offers "Update Now" or "Later".
-   **UI & Localization:**
    -   `UpdateDialog`: Displays both current and available versions in a left-aligned, themed container.
    -   **Numeral Localization:** Version strings are converted to Marathi/Hindi digits (using `toMarathiNumerals`) when the app locale is Marathi to maintain visual consistency.
-   **Web Behavior:** The update check is explicitly skipped on Web platforms using `!kIsWeb` in `HomeScreen`. This is because web users always receive the latest code upon refresh, and app store redirects are not applicable.
-   **Manual Deployment Script:** A Python utility (`scripts/update_remote_version.py`) is provided to safely update the Firestore version document using the Firebase Admin SDK.

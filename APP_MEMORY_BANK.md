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
-   **`??` vs `.isEmpty`:** Always remember that `??` only catches `null`. Firestore fields that exist but are empty (`""`) will bypass null-coalescing fallbacks. Use `.trim().isEmpty` checks for robust UI text handling.

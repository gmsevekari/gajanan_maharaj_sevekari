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
    -   **Graceful Audio Limits:** The audio loops (`audioplayers`) rely on a dedicated `_isTimeUp` boolean and synchronous native `stop()` calls to ensure background buffering never bypasses Dart's logic when a target or timer concludes.
    -   **Numeral Localization (`_formatNumber`):** Flutter defaults to casting format modifiers like `Duration` and `SnackBar` numerical `{count}` payload variables as raw base-10 integers. These must be explicitly wrapped in `_formatNumber(context)` on both UI dropdowns and `.arb` file parameter payloads (typed properly as `String` in the `.arb`) to ensure characters translate gracefully to Hindi/Marathi glyphs.
    -   **UI Refinement:** To support varied device sizes, the counting tiles on the 1st tab use reduced vertical padding and font sizes.
    -   **User Awareness:** A persistent reminder message encourages users to keep their screen on during chanting to prevent the device from sleeping and interrupting the count/timer.
-   **Temple Notifications & Admin Module:**
    -   **FCM Integration:** The app uses Firebase Cloud Messaging for broadcasting temple-wide alerts (e.g., Palkhi updates) via the `temple_notifications` topic.
    -   **Admin System:** A secure admin login and dashboard allow moderators to draft and send push notifications directly from the app.
    -   **Local Notifications:** Uses `flutter_local_notifications` to provide a consistent experience for foreground messages across Android and iOS, including custom actions like "Mark as Read" or "Open Link".
    -   **Notification History:** The `UserNotificationsScreen` provides a persistent archive of all received temple notifications, automatically clearing unread badges when opened.
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
-   **Flexible Data Models (`app_config.dart`):
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

# App Memory Bank: Gajanan Maharaj Sevekari

This document summarizes the key architectural patterns, design principles, and technical details of the "Gajanan Maharaj Sevekari" Flutter application.

---

### 1. Core Assistant Directives (Lessons Learned)

-   **Configuration is King:** The app's architecture must always prioritize being configuration-driven. Any logic that can be moved from hardcoded Dart into a JSON file should be. This includes feature flags, content types, and UI titles.
-   **Verify File Paths and Formats:** I must not assume file locations or formats. I incorrectly assumed the project used `.arb` files and the Groovy-based `build.gradle`, leading to significant errors. I must verify the exact file structure (`app_localizations.dart`, `build.gradle.kts`) before acting.
-   **`.arb` File Precision is Crucial:** When using `.arb` files for localization, I must be extremely careful. Missing placeholder definitions or mismatched types (e.g., `int` vs. `String`) will cause the `flutter gen-l10n` code generation to fail. I must also remember that this command needs to be run manually (`flutter pub get` or `flutter gen-l10n`) after any `.arb` file changes.
-   **Check All Targets:** When making project-level changes (like Bundle ID), I must remember to check all targets, including `Runner` and `RunnerTests` in Xcode.
-   **Holistic Firebase Configuration:** Updating Firebase requires changing the bundle ID in three places for iOS: the Xcode project (`Runner` and `RunnerTests`), the `GoogleService-Info.plist`, and the `firebase_options.dart` file.
-   **The `Podfile` Sledgehammer:** For stubborn iOS dependency errors related to deployment targets, the most robust solution is a `post_install` script that forcefully sets the `IPHONEOS_DEPLOYMENT_TARGET` for both each individual pod `target` and the overall `pods_project`.

---

### 2. Project Overview & Core Philosophy

-   **App Name:** `gajanan_maharaj_sevekari`
-   **Purpose:** A devotional app for followers of Indian saints, starting with Gajanan Maharaj, Datta Maharaj, and Sai Baba.
-   **Core Principles:** The app is lightweight, prioritizes an **offline-first approach** for text content, and is almost entirely **configuration-driven**.
-   **Data Contract Philosophy:** The app now follows a **strict data contract**. Content JSON files are expected to have mandatory keys (like `title_mr`, `content_en`). Missing keys will now cause errors during testing, enforcing data quality, rather than failing silently with defaults.

### 3. Key Features & Modules

-   **Multi-Deity Architecture:** The app is built to support multiple deities, each with their own configuration file defining their specific content and features.
-   **Region-Specific Features:** The visibility of certain dashboard cards (e.g., "Donations," "Signups") and favorite items is controlled by a `regions` array in the JSON configuration. An empty array means the feature is global; otherwise, it only appears if the user's device region matches a code in the list.
-   **Dynamic "About" Screen:** The title of the "About" screen is now configurable per-deity via an `about_title_key` in the deity's JSON file (e.g., "About Maharaj" vs. "About Baba").
-   **Generic List & Detail Screens:**
    -   `ContentListScreen`: A single, powerful, reusable screen that displays lists of content (stotras, bhajans, aartis, etc.). It is driven entirely by configuration.
    -   `ContentDetailScreen`: A highly reusable screen for displaying text and video content. It now uses a strict data contract and expects `title` and `content` keys to be present in the JSON.

### 4. Technical Stack & Architecture

-   **Framework:** Flutter.
-   **State Management:** `provider` package.
-   **Localization:** The project uses the standard Flutter internationalization approach with `.arb` (Application Resource Bundle) files.
    -   **Source Files:** `lib/l10n/app_en.arb` (English) and `lib/l10n/app_mr.arb` (Marathi).
    -   **Configuration:** A `l10n.yaml` file in the project root configures the code generation.
    -   **Code Generation:** Running `flutter pub get` or `flutter gen-l10n` generates the necessary `AppLocalizations` class.
-   **Flexible Data Models (`app_config.dart`):
    -   **Centralized `ContentType` Logic:** A `ContentTypeExtension.fromString()` method on the `ContentType` enum provides a single, central place to convert the `contentType` string from the JSON into the correct Dart enum, removing duplicated logic from UI screens.
    -   **Flexible Aarti Structure:** The `NityopasanaConfig` can handle two different JSON structures for `aartis`: a category-based list (for Gajanan Maharaj) and a direct, flat list of files (for Datta Maharaj).
    -   **Optional Sections:** The `DeityConfig` uses nullable properties (`DonationInfo?`, `SignupInfo?`) to gracefully handle deities that do not have these sections in their JSON, preventing crashes.

### 5. Build & Deployment

-   **Android Signing:**
    -   A private `upload-keystore.jks` is used for signing.
    -   Passwords are read from a `key.properties` file, which is ignored by git.
    -   The `android/app/build.gradle.kts` (Kotlin DSL) is configured to use these properties for release builds.
-   **iOS Configuration:**
    -   The iOS deployment target is set to **15.0**.
    -   The `ios/Podfile` contains a `post_install` script to enforce the deployment target across all pod libraries and the main pod project, resolving version conflicts.
    -   The `PRODUCT_BUNDLE_IDENTIFIER` is set to `com.gajanan.maharaj.sevekari` for the main `Runner` target and `com.gajanan.maharaj.sevekari.RunnerTests` for the test target.

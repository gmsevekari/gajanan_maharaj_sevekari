# App Memory Bank: Gajanan Maharaj Sevekari

This document summarizes the key architectural patterns, design principles, and technical details of the "Gajanan Maharaj Sevekari" Flutter application.

---

### 1. Core Assistant Directives (Lessons Learned)

-   **Explicit Configuration Over Implicit Logic:** My attempts to guess resource paths using logic in the code (e.g., deriving `grantha` from `granth`) were flawed and led to bugs. The final, superior architecture, as guided by the user, makes the configuration the single source of truth. **Explicitly defining resource directory paths in the JSON is always better than implicit logic in the code.**
-   **Do Not Overwrite User Changes:** I must be extremely careful not to overwrite user-added content, especially in data lists or localization files. My process must be to add to, not replace, user data.
-   **Verify API and Class Names:** I must not assume class names or parameters. If I am unsure, I must verify them through documentation or by analyzing the existing, working code.
-   **Acknowledge and Correct Failures:** When a fix fails, I must acknowledge the specific failure, explain the root cause, and propose a new, definitive solution rather than repeating the same failed approach.
-   **Verify API Usage Carefully:** Static vs. instance methods can cause build errors. Double-checking the implementation is crucial.
-   **Handle URI Encoding:** When creating `mailto` links, `Uri`'s `queryParameters` map may encode spaces as `+`. It's safer to manually build the query string and encode components using `Uri.encodeComponent`.

---

### 2. Project Overview & Core Philosophy

-   **App Name:** `gajanan_maharaj_sevekari`
-   **Purpose:** A devotional app for followers of the saint Gajanan Maharaj.
-   **Target Audience:** Devotees, with a specific focus on being **user-friendly for the elderly** (implying large fonts and simple navigation).
-   **Core Principles:** The app is lightweight, prioritizes an **offline-first approach** for most content, and is now almost entirely **configuration-driven**.

### 3. Key Features & Modules

-   **`HomeScreen`:** The main dashboard with a two-column `Wrap` layout for centered, 3D-effect cards.
-   **`NityopasanaScreen`:** A hub for daily devotional content. It is **fully configuration-driven**, dynamically building its grid from the `nityopasana.order` array in the deity's JSON config.
-   **`FavoritesScreen`:** A screen for user-favorite content, now **fully configuration-driven** by a global `resources/config/favorites.json` file.
-   **Generic List & Detail Screens (Core Components):**
    -   **`ContentListScreen`:** A powerful, generic, and reusable screen that has replaced the old, specific screens (`GranthScreen`, `BhajanScreen`, `StotraScreen`, `SundayPrarthanaScreen`). It is driven entirely by the JSON configuration, accepting a parent content object to build its list.
    -   **`ContentDetailScreen`:** A highly reusable component for displaying any JSON-based content. It features a custom segmented control (Read/Listen), font size controls, and an embedded YouTube player. The banner image now uses `fit: BoxFit.cover` to ensure it fills the card area correctly.
-   **`SettingsScreen`:** Provides options for Language, Theme, Font, and a "Contact Us" card that launches the user's email client.
-   **`EventCalendarScreen`:** Fetches and displays events from Firestore for the next 30 days.

### 4. Technical Stack & Architecture

-   **Framework:** Flutter.
-   **State Management:** The `provider` package is used for app-wide state, including `ThemeProvider`, `FontProvider`, `LocaleProvider`, and the crucial **`AppConfigProvider`**.
-   **`AppConfigProvider`:** This provider is responsible for loading the entire app's configuration from multiple JSON files at startup, including the root `app_config.json`, deity-specific configs, and the global `favorites.json`.
-   **Navigation:** Named routes are defined in `lib/utils/routes.dart`. Dynamic navigation to content screens is now handled within the UI based on the loaded configuration.
-   **Backend:** Firebase is used, specifically **Firestore** for fetching upcoming events.
-   **Key Dependencies:** `youtube_player_flutter`, `share_plus`, `url_launcher`, `provider`, `cloud_firestore`, `table_calendar`.
-   **Localization:** Handled manually in `lib/l10n/app_localizations.dart`.

### 5. Design & UI/UX Principles

-   **Centralized Theming (`app_theme.dart`):** Defines a consistent look and feel for `AppBar`, `Card`, and `ElevatedButton` across the app.
-   **Card Styles:** Utilizes a standard card style from `CardThemeData` and a special 3D effect card on the `HomeScreen`.
-   **UI Consistency:** Standardized elements like the "Share" button and navigation controls are used across different screens.

### 6. Data & Content Structure

-   **Configuration-Driven Model:** The app's content structure is defined almost entirely in JSON, promoting flexibility and maintainability.
    -   **`app_config.json`:** The root file, pointing to all other configuration files.
    -   **Deity Configs (e.g., `gajanan_maharaj.json`):** Defines the content, order, and resource paths for a specific deity.
    -   **`favorites.json`:** A global file defining the structure and content of the `FavoritesScreen`.
-   **Explicit Pathing (The DRY Principle):** To avoid ambiguity and bugs, resource paths are defined explicitly. Parent content objects (e.g., `granth`, `stotras`) specify a default `textResourceDirectory` and `imageResourceDirectory`. This reduces repetition while maintaining clarity.
-   **Per-Item Overrides:** The `ContentItem` model allows for an optional, per-item override of the `textResourceDirectory` and `imageResourceDirectory`, providing maximum flexibility for special cases (e.g., loading `gajanan_maharaj_bavanni.json` from its original deity folder within the favorites list).
-   **Content Files:** Text content and YouTube video IDs are stored in local JSON files within the `resources/texts/` directory.
-   **Image Assets:** All images are stored locally in the `resources/images/` directory and must be declared in `pubspec.yaml`.

```
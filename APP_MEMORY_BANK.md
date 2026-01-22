# App Memory Bank: Gajanan Maharaj Sevekari

This document summarizes the key architectural patterns, design principles, and technical details of the "Gajanan Maharaj Sevekari" Flutter application.

---

### 1. Core Assistant Directives (Lessons Learned)

-   **Do Not Overwrite User Changes:** I must be extremely careful not to overwrite user-added content, especially in data lists or localization files. My process must be to add to, not replace, user data.
-   **Verify API and Class Names:** I must not assume class names or parameters (e.g., `CardTheme` vs. `CardThemeData`, `showFullscreenButton`). If I am unsure, I must verify them through documentation or by analyzing the existing, working code.
-   **Acknowledge and Correct Failures:** When a fix fails, I must acknowledge the specific failure, explain the root cause, and propose a new, definitive solution rather than repeating the same failed approach.
-   **Verify API Usage Carefully:** Static vs. instance methods can cause build errors. For example, `Share.share()` is a static method, but other APIs might require an instance. Double-checking the implementation is crucial.
-   **Handle URI Encoding:** When creating `mailto` links, `Uri`'s `queryParameters` map may encode spaces as `+`. For better cross-client compatibility, it's safer to manually build the query string and encode components using `Uri.encodeComponent`.

---

### 2. Project Overview & Core Philosophy

-   **App Name:** `gajanan_maharaj_sevekari`
-   **Purpose:** A devotional app for followers of the saint Gajanan Maharaj.
-   **Target Audience:** Devotees, with a specific focus on being **user-friendly for the elderly**. This implies a need for large, clear fonts and simple, intuitive navigation.
-   **Core Principles:** The app is intended to be lightweight and prioritizes an **offline-first approach** for most of its content (texts, local images).

### 3. Key Features & Modules

-   **`HomeScreen`:** The main dashboard.
    -   It features a **`Wrap` layout** to display cards in a two-column grid.
    -   The `Wrap` widget is used with `alignment: WrapAlignment.center` to ensure that if there's an odd number of cards, the last one is automatically centered.
-   **`NityopasanaScreen`:** A secondary screen created to group daily devotional content (`Granth`, `Stotra`, `Bhajan`, `Aarti`, `Namavali`), decluttering the `HomeScreen`. It uses the same `Wrap` layout as the `HomeScreen` for consistency.
-   **`FavoritesScreen`:** A new screen to house a collection of user-favorite content. It uses the **Standard Card** style.
    -   **`SundayPrarthanaScreen`:** A sub-screen of `FavoritesScreen` that lists a specific collection of stotras for Sunday prayer. It also uses the **Standard Card** style for each item in its list.
-   **`ContentDetailScreen` (Generic):**
    -   This screen was refactored to be a single, generic component, replacing older, specific screens like `AartiDetailScreen`, `BhajanDetailScreen`, `StotraDetailScreen`, and `GranthAdhyayDetailScreen`.
    -   **Reusable by Design:** It accepts a direct `assetPath` in its constructor, removing internal logic and making it a highly reusable component for displaying any JSON-based content.
    -   **UI:** A key UI component is a **custom segmented control** for "Read" and "Listen" tabs. Tab switching is **tap-only**; swipe gestures are disabled. The "Read" tab includes floating action buttons for adjusting font size.
    -   **Navigation:** Features a consistent `AppBar` with **Home** and **Settings** buttons. It includes **Previous/Next** arrows for sequence navigation, and preserves the selected tab (Read/Listen) between items.
    -   **Listen Tab:** Embeds a YouTube video using `youtube_player_flutter`. It includes a "Share" button with a consistent, custom style.
-   **`SettingsScreen`:**
    -   Provides options for Language, Theme, Font, etc.
    -   **Contact Us:** Includes a localized "Contact Us" card that launches the user's email client with a pre-filled recipient (`gajananmaharajseattle@gmail.com`) and a correctly formatted subject line.
-   **`EventCalendarScreen`:**
    -   Fetches events from a Firestore `events` collection, sorted by `start_time`.
    -   Displays events from the user-selected date for the **next 30 days**.

### 4. Technical Stack & Architecture

-   **Framework:** Flutter.
-   **State Management:** The `provider` package is used for app-wide state, managing `ThemeProvider`, `FontProvider`, and `LocaleProvider`.
-   **Navigation:** Named routes are defined in `lib/utils/routes.dart`.
-   **Backend:** Firebase is used, specifically **Firestore** for fetching upcoming events.
-   **Key Dependencies:**
    -   `youtube_player_flutter`: For embedding YouTube videos.
    -   `share_plus`: For native sharing. The static `Share.share()` method is used for simplicity, though it is marked as deprecated.
    -   `url_launcher`: For opening external links (social media, email).
    -   `provider`: For app-wide state management.
    -   `cloud_firestore`: For reading event data.
    -   `table_calendar`: For the event calendar UI.
-   **Localization:**
    -   Localization is handled manually in `lib/l10n/app_localizations.dart` using `Map` structures for English (`en`) and Marathi (`mr`).
    -   New keys like `contactUs` are added directly to this file. The project **does not** use `.arb` files.

### 5. Design & UI/UX Principles

-   **Color Theme:**
    -   **Light Mode:** `AppBar` is orange. `Card` background is `Colors.orange[50]`.
    -   **Dark Mode:** `AppBar` is orange. `Card` background is a dark brown-black: `const Color(0xFF0A0805)`.
-   **Centralized Theming (`app_theme.dart`):**
    -   **`AppBarTheme`:** Centralized to define `backgroundColor` and `foregroundColor`. The `titleTextStyle` is intentionally omitted to allow the `AppBar` to inherit the globally selected font from the main theme's `textTheme`.
    -   **`CardThemeData`:** The single source of truth for all standard card styles, defining `color`, `elevation`, `shadowColor`, and a standard `shape` with an orange border.
    -   **`ElevatedButtonThemeData`:** Centralized to define a consistent style for all elevated buttons.
-   **Card Styles:**
    -   **Standard Card:** Most list items use a standard `Card` widget that respects the centralized `CardThemeData`.
    -   **3D Effect Card (`HomeScreen`):** Home screen cards have a special 3D effect created by wrapping the `Card` in a `Container` with a `BoxShadow`.
-   **UI Consistency:**
    -   Similar UI elements, such as the "Share" button in `ContentDetailScreen` and `NamavaliScreen`, are styled identically using a custom widget structure for a polished user experience.

### 6. Data & Content Structure

-   **Text Content:** Most devotional text is stored in local **JSON files** in the `resources/texts/` directory. These files contain keys for English and Marathi versions (e.g., `title_en`, `aarti_mr`).
-   **Video Content:** YouTube video IDs are stored in the same JSON files alongside the text using the key `"youtube_video_id"`.
-   **Image Assets:** All images are stored locally in the `resources/images/` directory and must be declared in `pubspec.yaml` to be accessible.

# App Memory Bank: Gajanan Maharaj Sevekari

This document summarizes the key architectural patterns, design principles, and technical details of the "Gajanan Maharaj Sevekari" Flutter application.

---

### 1. Core Assistant Directives (Lessons Learned)

-   **Do Not Overwrite User Changes:** I must be extremely careful not to overwrite user-added content, especially in data lists or localization files. My process must be to add to, not replace, user data.
-   **Verify API and Class Names:** I must not assume class names or parameters (e.g., `CardTheme` vs. `CardThemeData`, `showFullscreenButton`). If I am unsure, I must verify them through documentation or by analyzing the existing, working code.
-   **Acknowledge and Correct Failures:** When a fix fails, I must acknowledge the specific failure, explain the root cause, and propose a new, definitive solution rather than repeating the same failed approach.

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
-   **Detail Screens (`GranthAdhyayDetailScreen`, `AartiDetailScreen`, etc.):**
    -   A key UI component is a **custom segmented control** for "Read" and "Listen" tabs, built with styled `Container` and `GestureDetector` widgets. It does **not** use the default `TabBar` in the `AppBar`.
    -   Tab switching is **tap-only**; swipe gestures are disabled using `physics: const NeverScrollableScrollPhysics()` on the `TabBarView`.
    -   The "Read" tab includes floating action buttons for adjusting font size.
    -   **Navigation:** All detail screens feature a consistent `AppBar` with a **Home** and **Settings** button in the `actions`. Screens that are part of a sequence (Granth, Aarti, etc.) also include **Previous/Next** arrows for easy navigation. Long titles are handled by allowing the title to wrap to a new line, facilitated by a `PreferredSize` widget on the `AppBar`.
-   **`GranthAdhyayDetailScreen`:** This is the most feature-rich detail screen.
    -   It displays a chapter-specific image at the top of both the "Read" and "Listen" tabs.
    -   The "Listen" tab embeds a YouTube video using the `youtube_player_flutter` package. **Fullscreen functionality is explicitly disabled** due to persistent state management issues, providing a more stable user experience.
    -   It preserves the selected tab (Read/Listen) when navigating to the next or previous chapter.
-   **`EventCalendarScreen`:**
    -   Fetches events from a Firestore `events` collection.
    -   The query is sorted by `start_time` to ensure chronological order.
    -   The event list displays all events from the user-selected date for the **next 30 days**.

### 4. Technical Stack & Architecture

-   **Framework:** Flutter.
-   **State Management:** The `provider` package is used for app-wide state, specifically for `ThemeProvider` and `LocaleProvider`.
-   **Navigation:** Named routes are defined in a dedicated `lib/utils/routes.dart` file and registered in `main.dart`. The `Navigator.pushNamedAndRemoveUntil` method is used for the Home button to clear the navigation stack.
-   **Backend:** Firebase is used, specifically **Firestore** for fetching upcoming events for the `HomeScreen` and `EventCalendarScreen`.
-   **Key Dependencies:**
    -   `youtube_player_flutter`: For embedding YouTube videos.
    -   `share_plus`: For native sharing functionality.
    -   `url_launcher`: For opening external links (like social media).
    -   `provider`: For app-wide state management.
    -   `cloud_firestore`: For reading event data.
    -   `table_calendar`: For the event calendar UI.
-   **Localization:**
    -   Localization is handled manually in `lib/l10n/app_localizations.dart` using `Map` structures for English (`en`) and Marathi (`mr`).
    -   The project **does not** use `.arb` files.

### 5. Design & UI/UX Principles

-   **Color Theme:**
    -   **Light Mode:** Primary color is `Colors.orange`, with `AppBar`s and other key elements using this color. The main background is a light cream/beige. Card backgrounds are a light orange (`Colors.orange[50]`).
    -   **Dark Mode:** The `scaffoldBackgroundColor` is `const Color(0xFF121212)`. Cards also have a `Colors.black` background, creating a high-contrast look. The primary orange color is used for accents, borders, and interactive elements.
-   **Card Styles:**
    -   **Standard Card:** This is the default style for all list-item cards. It is a `Card` widget with `elevation: 4.0`, a theme-aware background color, and a `RoundedRectangleBorder` with `side: BorderSide(color: Colors.orange.withAlpha(128), width: 1)`. It is used in screens like `aarti_list_screen`, `favorites_screen`, and `sunday_prarthana_screen`.
    -   **3D Effect Card (`HomeScreen`):** The grid cards on the home screen have a special 3D effect created by wrapping the `Card` in a `Container` that has a `BoxShadow` with an orange color and a `(0, 4)` offset. The card itself has its elevation set to `0`.
    -   **Event Cards (`EventCalendarScreen`):** A standard `Card` whose `color` and `shape` are dynamically changed to show a highlighted state (`Colors.orange[200]` with a thicker border) when an event is selected in the calendar.
    -   **Namavali List:** This screen uses `ListTile`s with `Divider`s, not cards, for a cleaner, list-based presentation.
-   **Text and Icons:**
    -   Most text and icons on cards use `theme.colorScheme.primary` or `theme.colorScheme.secondary` to ensure they adapt correctly to both light and dark themes.

### 6. Data & Content Structure

-   **Text Content:** Most devotional text is stored in local **JSON files** located in the `resources/texts/` directory. These JSON files contain keys for English and Marathi versions (e.g., `title_en`, `title_mr`, `aarti_en`, `aarti_mr`). The `sunday_prarthana` stotras are in a dedicated sub-directory: `resources/texts/stotras/sunday_prarthana/`.
-   **Video Content:** YouTube video IDs are stored in the same JSON files alongside the text using the key `"youtube_video_id"`.
-   **Image Assets:** All images are stored locally in the `resources/images/` directory and must be declared in `pubspec.yaml` to be accessible.

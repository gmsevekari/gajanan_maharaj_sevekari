# Gajanan Maharaj Sevekari - App Guidelines

These are the strict, **app-specific** coding rules and architectural guidelines that **MUST** be natively applied to all code within the Gajanan Maharaj Sevekari repository. 

*Note: For general Flutter/Dart guidelines (Immutability, Null Safety, API Gotchas), refer to the global `rules/dart/coding-standards.md`.*

## 1. Architecture & Configuration
- **Configuration is King:** If a piece of text, a feature flag, a region restriction, or an asset path can be placed into a JSON configuration document (`lib/config/...`) rather than deeply hardcoded into a Dart Widget, it **must** be stored in the JSON. The app's core philosophy is strict configuration-driven malleability.
- **JSON Configuration Localization:** Any user-visible text stored in local configurations (e.g., `favorites.json`, `app_config.json`) must use suffix-based bilingual keys (e.g., `name_en` and `name_mr`) rather than a single hardcoded string. The Dart models resolving these JSONs must ingest both and display the correct one via `Localizations.localeOf(context).languageCode`.
- **Localization Files:** Any static string exposed to the UI must be registered as a key within BOTH `app_en.arb` and `app_mr.arb`. Do not hardcode raw English text into UI Widgets.
- **Run the Code Generator:** After modifying any `.arb` file, you **must** immediately run `flutter gen-l10n` to update the `AppLocalizations` binding classes before referencing the new keys in the Dart codebase.

## 2. Theming & AppColors
- **AppColors Extension (`theme.appColors`):** The app defines a custom `AppColors` `ThemeExtension` in `lib/app_theme.dart` that provides semantic color tokens beyond what `ColorScheme` offers. Access it via `theme.appColors.<property>`. Available properties include:
  - `primarySwatch` — The theme's primary `MaterialColor` (use `primarySwatch[600]` for specific shades).
  - `success`, `warning`, `error` — Semantic status colors.
  - `surface`, `surfaceSubtle` — Card/container backgrounds.
  - `secondaryText` — Muted text color.
  - `divider`, `tableHeader` — Table/list styling.
  - `disabledBackground`, `disabledText` — Disabled state colors.
  - `brandAccent`, `onPrimarySubtle` — Brand-specific accent and subtle on-primary text.
- **Multi-Theme Awareness:** Ensure widgets render correctly in all theme presets (Saffron, Maroon, Sandalwood, Indigo). When adding a new semantic color need, add it to the `AppColors` class in `lib/app_theme.dart`, provide values for BOTH the original `lightTheme`/`darkTheme` `extensions` blocks AND the `getTheme()` factory's per-preset switch cases.
- **Original Theme Preservation:** The `lightTheme` and `darkTheme` static fields in `lib/app_theme.dart` are marked `DO NOT MODIFY`. They are the Saffron (Orange) source of truth. To add a new theme preset, add a new `ThemePreset` enum value and extend the `switch` statement in `getTheme()`.
- **MaterialColor Swatch Generation:** When creating `MaterialColor` objects from a `Color`, use the `_createMaterialColor` method in `lib/app_theme.dart` which correctly handles Flutter's normalized channel values.

## 3. Localization & Ecosystem
- **Numeral Localization:** Flutter defaults to natively casting variables like numerical `Duration` counters or dynamic `SnackBar` inputs back to base-10 English integer Strings, regardless of the active Locale. For any numeral that must display in Hindi/Marathi, remember to wrap the raw input via the app's internal `_formatNumber(context, <int>)` method or `toMarathiNumerals(<String>)` before it passes into a localized String parameter. This applies to version strings in update dialogs as well.

## 4. Firestore Data Patterns
- **Flattened Document Format:** Participant/member documents in Firestore must use the **flattened format** with top-level fields (`memberName`, `name`, `assignedAdhyays`, `completions`, `deviceId`, `phone`, `globalIndex`, `groupNumber`, `joinedAt`). Never introduce nested `members` maps — the old household format is legacy and not supported by `getAllParticipants()` or `getParticipantsByDevice()`.
- **Document ID Convention:** Participant doc IDs follow the `{deviceId}_{memberName}` pattern (with spaces replaced by underscores). This ensures uniqueness per device per member and allows name extraction from the ID as a fallback.
- **Bilingual Content Fields:** Any new Firestore document with user-visible text must include both `_en` and `_mr` suffixed fields (e.g., `title_en`, `title_mr`, `description_en`, `description_mr`). UI code should select the appropriate field based on `Localizations.localeOf(context).languageCode`.

---
trigger: always_on
---

# AI Assistant Coding Guidelines

These are the strict coding rules and architectural guidelines that **MUST** be natively applied to all code generated or modified by the AI assistant within the Gajanan Maharaj Sevekari repository. 

Review these guidelines before initiating development tasks to ensure consistency, performance, and best practices.

## 1. Code Formatting & Syntax
- **Formatter Rule:** Always apply the `dart format` command **ONLY** to the specific files modified during a task (e.g., `dart format lib/path/to/specific_file.dart`). Never run a global formatting reset (`dart format .`) unless explicitly requested by the user, to preserve localized Git histories.
- **Immutability:** Always rely on `final` or `const` variables wherever structurally possible. Do not declare `var` or un-assigned typed properties unless the data expects downstream mutation.
- **Widget Const Constructors:** Whenever instantiating a Flutter Widget, prefer the `const` prefix (e.g., `const SizedBox(height: 16)`) to optimize the build cycle and reduce memory overhead during rendering.
- **Null Safety:** Strictly adhere to Dart null-safety paradigms. Avoid using the `!` "bang" operator to legally force unpack properties unless you have a preceding logic gate or structural guarantee proving the value is non-null. Prefer `?.` or explicit null-handling `if` checks.

## 2. Architecture & Configuration
- **Configuration is King:** If a piece of text, a feature flag, a region restriction, or an asset path can be placed into a JSON configuration document (`lib/config/...`) rather than deeply hardcoded into a Dart Widget, it **must** be stored in the JSON. The app's core philosophy is strict configuration-driven malleability.
- **Localization Files:** Any static string exposed to the UI must be registered as a key within BOTH `app_en.arb` and `app_mr.arb`. Do not hardcode raw English text into UI Widgets.
- **Run the Code Generator:** After modifying any `.arb` file, you **must** immediately run `flutter gen-l10n` to update the `AppLocalizations` binding classes before referencing the new keys in the Dart codebase.

## 3. Theming & Styling
- **Theme Inheritance:** Always utilize the central `Theme.of(context)` to style Widgets. Instead of hardcoding `Colors.white` or `Colors.black`, rely on properties like `theme.colorScheme.onSurface`, `theme.colorScheme.primary`, or `theme.cardColor` to ensure universal Light/Dark Mode compatibility.
- **Text Styles:** Use the canonical `theme.textTheme` hierarchy (e.g. `bodyLarge`, `titleMedium`) rather than building raw `TextStyle` objects with hardcoded font sizes.
- **AppColors Extension (`theme.appColors`):** The app defines a custom `AppColors` `ThemeExtension` in `lib/app_theme.dart` that provides semantic color tokens beyond what `ColorScheme` offers. Access it via `theme.appColors.<property>`. Available properties include:
  - `primarySwatch` — The theme's primary `MaterialColor` (use `primarySwatch[600]` for specific shades).
  - `success`, `warning`, `error` — Semantic status colors.
  - `surface`, `surfaceSubtle` — Card/container backgrounds.
  - `secondaryText` — Muted text color.
  - `divider`, `tableHeader` — Table/list styling.
  - `disabledBackground`, `disabledText` — Disabled state colors.
  - `brandAccent`, `onPrimarySubtle` — Brand-specific accent and subtle on-primary text.
- **No Hardcoded Colors:** Never use raw color literals like `Colors.orange`, `Color(0xFFFF9800)`, `Colors.grey.shade600`, or similar in Widget code. Always map through either `theme.colorScheme.*` or `theme.appColors.*`. This ensures that all theme presets (Saffron, Maroon, Sandalwood, Indigo) render correctly without per-widget color overrides.
- **Multi-Theme Awareness:** The app supports multiple `ThemePreset` values. When adding a new semantic color need, add it to the `AppColors` class in `lib/app_theme.dart`, provide values for BOTH the original `lightTheme`/`darkTheme` `extensions` blocks AND the `getTheme()` factory's per-preset switch cases. Never assume "orange" is the only theme.
- **Opacity/Alpha:** Use `.withValues(alpha: 0.X)` instead of the deprecated `.withOpacity(0.X)` when applying transparency to theme colors.

## 4. Platform & Ecosystem Considerations
- **Platform Separation Checks:** When implementing sweeping new packages, be cognizant of the Web target. Always wrap potentially mobile-only code in `kIsWeb` conditional rendering, or silo Web logic vs Native logic into distinct wrapper classes (e.g. `CrossPlatformYoutubePlayer`).
- **Numeral Localization:** Flutter defaults to natively casting variables like numerical `Duration` counters or dynamic `SnackBar` inputs back to base-10 English integer Strings, regardless of the active Locale. For any numeral that must display in Hindi/Marathi, remember to wrap the raw input via the app's internal `_formatNumber(context, <int>)` method or `toMarathiNumerals(<String>)` before it passes into a localized String parameter. This applies to version strings in update dialogs as well.
- **Skip Mobile-Only Tasks on Web:** App updates, push notification permission requests, and deep link capture logic should generally be guarded by `!kIsWeb` to avoid unnecessary Firestore calls or broken UI on the web target.

## 5. Firestore Data Patterns
- **Flattened Document Format:** Participant/member documents in Firestore must use the **flattened format** with top-level fields (`memberName`, `name`, `assignedAdhyays`, `completions`, `deviceId`, `phone`, `globalIndex`, `groupNumber`, `joinedAt`). Never introduce nested `members` maps — the old household format is legacy and not supported by `getAllParticipants()` or `getParticipantsByDevice()`.
- **Document ID Convention:** Participant doc IDs follow the `{deviceId}_{memberName}` pattern (with spaces replaced by underscores). This ensures uniqueness per device per member and allows name extraction from the ID as a fallback.
- **Bilingual Content Fields:** Any new Firestore document with user-visible text must include both `_en` and `_mr` suffixed fields (e.g., `title_en`, `title_mr`, `description_en`, `description_mr`). UI code should select the appropriate field based on `Localizations.localeOf(context).languageCode`.
- **Null vs Empty String:** Be aware that Dart's `??` operator only catches `null`, not empty strings `""`. When reading Firestore fields that might be empty, use `.isNotEmpty` checks instead of relying on `??` fallback chains.

## 6. Verification & Safety
- **Always Run `flutter analyze`:** After any code modification, run `flutter analyze` and confirm zero new errors before considering the task complete. Pre-existing `info`/`warning` level issues are acceptable, but new `error` level issues must be resolved.
- **Format Only Modified Files:** Run `dart format` only on the specific files you modified (e.g., `dart format lib/path/to/specific_file.dart`). Never run `dart format .` globally.
- **Original Theme Preservation:** The `lightTheme` and `darkTheme` static fields in `lib/app_theme.dart` are marked `DO NOT MODIFY`. They are the Saffron (Orange) source of truth. To add a new theme preset, add a new `ThemePreset` enum value and extend the `switch` statement in `getTheme()` — never alter the original theme definitions.
- **Test Across Themes:** When making UI changes, verify they render correctly in both light and dark modes and consider how they will look in non-saffron theme presets (Maroon, Sandalwood, Indigo).

## 7. Flutter API Gotchas
- **Color Channel Normalization:** In Flutter 3.27+, `Color.r`, `.g`, `.b` return **normalized doubles** (0.0–1.0), NOT integers (0–255). Code that casts these directly to `int` (e.g., `color.r.toInt()`) will silently produce `0`, resulting in black. Always multiply by 255 first: `(color.r * 255).round()`.
- **MaterialColor Swatch Generation:** When creating `MaterialColor` objects from a `Color`, use the `_createMaterialColor` method in `lib/app_theme.dart` which correctly handles the normalized channel values.
- **Deprecated APIs:** Prefer `withValues(alpha: x)` over `withOpacity(x)`, `SharePlus` over `Share`, and `SharePlus.instance.share()` over `shareXFiles`.
- **Stable Builders (StreamBuilder/FutureBuilder):** Never initialize a `Stream` or `Future` directly inside a `build` method (e.g. `stream: service.getStream()`). This causes the builder to reset and "flicker" during every UI rebuild or navigation transition. Always convert the widget to a `StatefulWidget` and initialize the `Stream` or `Future` once in `initState` to ensure a stable data source.

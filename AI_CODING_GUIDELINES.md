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

## 4. Platform & Ecosystem Considerations
- **Platform Separation Checks:** When implementing sweeping new packages, be cognizant of the Web target. Always wrap potentially mobile-only code in `kIsWeb` conditional rendering, or silo Web logic vs Native logic into distinct wrapper classes (e.g. `CrossPlatformYoutubePlayer`).
- **Numeral Localization:** Flutter defaults to natively casting variables like numerical `Duration` counters or dynamic `SnackBar` inputs back to base-10 English integer Strings, regardless of the active Locale. For any numeral that must display in Hindi/Marathi, remember to wrap the raw input via the app's internal `_formatNumber(context, <int>)` method before it passes into a localized String parameter.

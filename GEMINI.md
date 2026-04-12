# Dart / Flutter Project Rules

This file should be copied to the root of your Flutter/Dart project. It is auto-loaded by Gemini and Antigravity when working in that project.

## Language-Specific Rules

Follow the Dart-specific rules defined in these files:

- [Dart Coding Standards](./coding-standards.md) — Null safety, sealed types, async patterns, widget rules, static analysis.
- [Dart Security](./security.md) — Mobile security, WebView, data protection, secrets management.
- [Dart Testing](./testing.md) — BLoC, Riverpod, widget & golden tests, fakes over mocks.
- [Dart Build Resolution](./build-resolution.md) — Null safety fixes, generic types, build_runner troubleshooting.

## Project Conventions

<!-- Customize these for your specific project -->

### State Management
<!-- Specify which library this project uses -->
- Library: `riverpod` / `bloc` / `provider` / `getx` / `mobx`

### Routing
<!-- Specify which router this project uses -->
- Library: `go_router` / `auto_route` / `Navigator 2.0`

### Architecture
<!-- Specify the architecture pattern -->
- Pattern: Clean Architecture / MVVM / MVC

### Localization
<!-- Specify the l10n approach -->
- Approach: `flutter_localizations` + ARB files

### Testing
```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# Run specific test
flutter test test/unit/test_file.dart
```

### Formatting
```bash
dart format .
dart analyze
```

## Project-Specific Rules

You MUST follow the strict app-specific architecture, Firestore, and widget token standards defined here:

- [Gajanan App Rules](./app-specific-rules.md) — Firestore flatten schemas, app_en.arb localization, semantic AppColors, and numeral formatting.


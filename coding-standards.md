# Dart Coding Standards

Dart and Flutter-specific rules. These extend the common [coding-standards.md](file:///Users/abhishekkulkarni/.gemini/rules/coding-standards.md).

## Formatting

- Use `dart format` for all `.dart` files — enforced in CI.
- Line length: 80 characters (dart format default).
- Trailing commas on multi-line argument/parameter lists to improve diffs and formatting.
- Apply the formatter **only** to files modified during the task — not globally.

## Immutability

- Prefer `final` for local variables and `const` for compile-time constants.
- Use `const` constructors wherever all fields are `final`.
- Return unmodifiable collections from public APIs (`List.unmodifiable`, `Map.unmodifiable`).
- Use `copyWith()` for state mutations in immutable state classes.
- Use `@dataclass(frozen: true)` or `freezed` for value objects.

```dart
// BAD
var count = 0;
List<String> items = ['a', 'b'];

// GOOD
final count = 0;
const items = ['a', 'b'];
```

## Naming

Follow Dart conventions:

- `camelCase` — variables, parameters, named constructors.
- `PascalCase` — classes, enums, typedefs, extensions.
- `snake_case` — file names and library names.
- `SCREAMING_SNAKE_CASE` — top-level `const` constants.
- Prefix private members with `_`.
- Extension names describe the type they extend: `StringExtensions`, not `MyHelpers`.

## Null Safety

- Avoid `!` (bang operator) — prefer `?.`, `??`, or Dart 3 pattern matching. Reserve `!` only where null is a programming error.
- Avoid `late` unless initialization is guaranteed before first use — prefer nullable or constructor init.
- Use `required` for constructor parameters that must always be provided.

```dart
// BAD — crashes at runtime if user is null
final name = user!.name;

// GOOD — null-aware operators
final name = user?.name ?? 'Unknown';

// GOOD — Dart 3 pattern matching
final name = switch (user) {
  User(:final name) => name,
  null => 'Unknown',
};

// GOOD — early-return null guard
String getUserName(User? user) {
  if (user == null) return 'Unknown';
  return user.name; // promoted to non-null
}
```

## Sealed Types & Pattern Matching (Dart 3+)

Use sealed classes to model closed state hierarchies:

```dart
sealed class AsyncState<T> {
  const AsyncState();
}

final class Loading<T> extends AsyncState<T> {
  const Loading();
}

final class Success<T> extends AsyncState<T> {
  const Success(this.data);
  final T data;
}

final class Failure<T> extends AsyncState<T> {
  const Failure(this.error);
  final Object error;
}
```

Always use exhaustive `switch` — no default/wildcard with sealed types:

```dart
// BAD
if (state is Loading) { ... }

// GOOD
return switch (state) {
  Loading() => const CircularProgressIndicator(),
  Success(:final data) => DataWidget(data),
  Failure(:final error) => ErrorWidget(error.toString()),
};
```

Use Dart 3 records `(String, int)` instead of single-use DTOs for multiple return values.

## Error Handling

- Specify exception types in `on` clauses — never use bare `catch (e)`.
- Never catch `Error` subtypes — they indicate programming bugs.
- Use `Result`-style types or sealed classes for recoverable errors.
- Avoid using exceptions for control flow.

```dart
// BAD
try {
  await fetchUser();
} catch (e) {
  log(e.toString());
}

// GOOD
try {
  await fetchUser();
} on NetworkException catch (e) {
  log('Network error: ${e.message}');
} on NotFoundException {
  handleNotFound();
}
```

## Async / Futures

- Always `await` Futures or explicitly call `unawaited()` to signal fire-and-forget.
- Never mark a function `async` if it never `await`s anything.
- Use `Future.wait` / `Future.any` for concurrent operations.
- Check `context.mounted` before using `BuildContext` after any `await` (Flutter 3.7+).

```dart
// BAD — ignoring Future
fetchData(); // fire-and-forget without marking intent

// GOOD
unawaited(fetchData()); // explicit fire-and-forget
await fetchData();      // or properly awaited
```

## Imports

- Use `package:` imports throughout — never relative imports (`../`).
- Order: `dart:` → external `package:` → internal `package:`.
- No unused imports — `dart analyze` enforces this.

## Code Generation

- Generated files (`.g.dart`, `.freezed.dart`, `.gr.dart`) must be committed or gitignored consistently — pick one strategy per project.
- Never manually edit generated files.
- Keep generator annotations (`@JsonSerializable`, `@freezed`, `@riverpod`) on the canonical source file only.

## Widget-Specific Rules

- No `build()` method exceeding 80–100 lines — extract to separate widget classes.
- Use `const` constructors on widgets to prevent unnecessary rebuilds.
- No network calls, file I/O, or heavy computation in `build()`.
- No `.listen()` or subscription creation in `build()`.
- Colors from `Theme.of(context).colorScheme` — no hardcoded `Colors.red` or hex values.
- Text styles from `Theme.of(context).textTheme` — no inline `TextStyle` with raw font sizes.

## Static Analysis

Ensure `analysis_options.yaml` has:

```yaml
analyzer:
  strict-casts: true
  strict-inference: true
  strict-raw-types: true
```

Key lint rules regardless of lint package:

- `prefer_const_constructors`
- `avoid_print`
- `unawaited_futures`
- `prefer_final_locals`
- `always_declare_return_types`
- `avoid_catches_without_on_clauses`
- `always_use_package_imports`

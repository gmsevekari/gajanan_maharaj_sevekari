# Dart Build Resolution

Dart and Flutter-specific compiler fixes. These extend the common [build-resolution.md](file:///Users/abhishekkulkarni/.gemini/rules/build-resolution.md).

## Common Diagnostic
Always use `flutter analyze` to double-check local compiler errors before submitting a fix.

## Null Safety
- **Error:** `The property 'X' can't be unconditionally accessed because the receiver can be 'null'`
  - **Minimal Fix:** Use `?.X` or `?? default`. Do not use `!` unless it's a known non-null framework injection.
  
- **Error:** `A value of type 'X?' can't be assigned to a variable of type 'X'`
  - **Minimal Fix:** Add a fallback value `?? fallback`, or wrap the operation in a null check block `if (x != null)`.

## Generics & Type Discrepancies
- **Error:** `The argument type 'X' can't be assigned to the parameter type 'Y'`
  - **Minimal Fix:** Check if one is a super/subtype. Downcast via `as Y` if required, or update the source generator (e.g. mapping an iterable `items.map((i) => i).toList()`).

## Code Generation Failures
- **Error:** `Conflicting outputs` or `Cannot generate file` or `part file not found`
  - **Nuclear Fix:** `dart run build_runner build --delete-conflicting-outputs`

## Widget Context Errors
- **Error:** `No MaterialLocalizations found` (Common in Widget Tests)
  - **Minimal Fix:** Wrap the target widget in a `MaterialApp` or provide localized `MaterialApp.router` stubs.

## Imports
- **Error:** `Target of URI doesn't exist`
  - **Minimal Fix:** Ensure `flutter pub get` has been run. For internal files, verify you aren't pointing to a deleted or renamed file. Prefer `package:` imports over relative ones.

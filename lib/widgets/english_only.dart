import 'package:flutter/material.dart';

/// Exposes the app's real locale to [EnglishOnly] subtrees, so admin-entered
/// content can still be shown in the language the user chose even though the
/// surrounding UI text is forced to English.
class AppContentLocale extends InheritedWidget {
  final String languageCode;

  const AppContentLocale({
    super.key,
    required this.languageCode,
    required super.child,
  });

  static String? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<AppContentLocale>()
      ?.languageCode;

  @override
  bool updateShouldNotify(AppContentLocale oldWidget) =>
      languageCode != oldWidget.languageCode;
}

/// Renders [builder]'s result with every localization (UI strings, Material
/// widgets, pickers) forced to English, regardless of the app language.
/// The builder's context is below the override, so `AppLocalizations.of`
/// inside it returns English.
class EnglishOnly extends StatelessWidget {
  final WidgetBuilder builder;

  const EnglishOnly({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    final appLanguage =
        AppContentLocale.maybeOf(context) ??
        Localizations.localeOf(context).languageCode;
    return AppContentLocale(
      languageCode: appLanguage,
      child: Localizations.override(
        context: context,
        locale: const Locale('en'),
        child: Builder(builder: builder),
      ),
    );
  }
}

/// True when admin-entered content (titles, descriptions, slot labels)
/// should be shown in Marathi: the app language, not the forced-English UI.
bool contentIsMarathi(BuildContext context) =>
    (AppContentLocale.maybeOf(context) ??
        Localizations.localeOf(context).languageCode) ==
    'mr';

/// [showDialog] with the dialog's content forced to English; a dialog route
/// sits above the screen, so it doesn't inherit the screen's override.
Future<T?> showEnglishDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) => showDialog<T>(
  context: context,
  barrierDismissible: barrierDismissible,
  builder: (_) => EnglishOnly(builder: builder),
);

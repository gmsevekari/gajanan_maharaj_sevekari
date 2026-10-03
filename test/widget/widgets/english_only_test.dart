import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/widgets/english_only.dart';

void main() {
  Widget app(Locale locale, Widget home) => MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: home),
  );

  testWidgets('forces English UI strings under a Marathi app locale', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        const Locale('mr'),
        EnglishOnly(
          builder: (context) => Text(AppLocalizations.of(context)!.cancel),
        ),
      ),
    );

    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('contentIsMarathi still reflects the app language inside', (
    tester,
  ) async {
    late bool inside;
    await tester.pumpWidget(
      app(
        const Locale('mr'),
        EnglishOnly(
          builder: (context) {
            inside = contentIsMarathi(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(inside, isTrue);
  });

  testWidgets('contentIsMarathi is false for an English app locale', (
    tester,
  ) async {
    late bool inside;
    await tester.pumpWidget(
      app(
        const Locale('en'),
        EnglishOnly(
          builder: (context) {
            inside = contentIsMarathi(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(inside, isFalse);
  });

  testWidgets('contentIsMarathi falls back to the locale outside EnglishOnly', (
    tester,
  ) async {
    late bool outside;
    await tester.pumpWidget(
      app(
        const Locale('mr'),
        Builder(
          builder: (context) {
            outside = contentIsMarathi(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(outside, isTrue);
  });

  testWidgets('nesting keeps the real app language, not the forced English', (
    tester,
  ) async {
    late bool nested;
    await tester.pumpWidget(
      app(
        const Locale('mr'),
        EnglishOnly(
          builder: (_) => EnglishOnly(
            builder: (context) {
              nested = contentIsMarathi(context);
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    expect(nested, isTrue);
  });

  testWidgets('showEnglishDialog renders its content in English', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        const Locale('mr'),
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showEnglishDialog<void>(
              context: context,
              builder: (ctx) =>
                  AlertDialog(title: Text(AppLocalizations.of(ctx)!.cancel)),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Cancel'), findsOneWidget);
  });
}

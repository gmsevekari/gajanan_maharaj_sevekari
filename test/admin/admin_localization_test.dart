import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  testWidgets('adminNamjapGroupTitle is present in localizations', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [
          Locale('en'),
          Locale('mr'),
        ],
        home: LocalizationChecker(),
      ),
    );

    // Check English
    expect(find.text('Namjap Groups'), findsOneWidget);

    // Switch to Marathi
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    
    expect(find.text('नामजप ग्रुप्स'), findsOneWidget);
  });
}

class LocalizationChecker extends StatefulWidget {
  const LocalizationChecker({super.key});

  @override
  State<LocalizationChecker> createState() => _LocalizationCheckerState();
}

class _LocalizationCheckerState extends State<LocalizationChecker> {
  Locale _locale = const Locale('en');

  void _toggleLocale() {
    setState(() {
      _locale = _locale.languageCode == 'en' ? const Locale('mr') : const Locale('en');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Localizations.override(
      context: context,
      locale: _locale,
      child: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context)!;
          return Scaffold(
            body: Column(
              children: [
                Text(l10n.adminNamjapGroupTitle), 
                ElevatedButton(onPressed: _toggleLocale, child: const Text('Toggle')),
              ],
            ),
          );
        },
      ),
    );
  }
}

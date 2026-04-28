import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';

void main() {
  testWidgets('AppLocalizations contains noNamjapGroupsSelectedMessage', (WidgetTester tester) async {
    late AppLocalizations localizations;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            localizations = AppLocalizations.of(context)!;
            return Container();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    
    // This will fail to compile if the key is missing in the generated class
    expect(localizations.noNamjapGroupsSelectedMessage, contains('Group Namjap'));
  });
}

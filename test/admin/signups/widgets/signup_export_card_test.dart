import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/widgets/signup_export_card.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';

void main() {
  testWidgets('renders SignupExportCard with summary stats and slot progress', (
    tester,
  ) async {
    final now = DateTime.now();
    final signup = Signup(
      id: 'signup_1',
      titleEn: 'Sunday Prasad Seva',
      titleMr: 'रविवार प्रसाद सेवा',
      descriptionEn: 'Cook and serve prasad',
      descriptionMr: 'प्रसाद सेवा',
      groupId: 'gajanan_maharaj_seattle',
      status: SignupStatus.published,
      requiresJoinCode: false,
      createdAt: now,
      updatedAt: now,
      createdBy: 'admin@test.com',
    );

    final slots = [
      SignupSlot(
        id: 'slot_1',
        labelEn: 'Week 1 - Team A',
        labelMr: 'आठवडा १',
        capacity: 5,
        claimedCount: 4,
        sortOrder: 0,
        createdAt: now,
      ),
      SignupSlot(
        id: 'slot_2',
        labelEn: 'Week 2 - Team B',
        labelMr: 'आठवडा २',
        capacity: 5,
        claimedCount: 5,
        sortOrder: 1,
        createdAt: now,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              final theme = Theme.of(context);
              return SignupExportCard(
                signup: signup,
                slots: slots,
                totalClaims: 9,
                totalCapacity: 10,
                groupName: 'Seattle',
                l10n: l10n,
                theme: theme,
                langCode: 'en',
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sunday Prasad Seva'), findsOneWidget);
    expect(find.text('Cook and serve prasad'), findsOneWidget);
    expect(find.text('Seattle'), findsOneWidget);
    expect(find.text('Total Slots'), findsOneWidget);
    expect(find.text('Total Signups'), findsOneWidget);
    expect(find.text('Filled'), findsOneWidget);
    expect(find.text('Week 1 - Team A'), findsOneWidget);
    expect(find.text('Week 2 - Team B'), findsOneWidget);
    expect(find.text('4 of 5 claimed'), findsOneWidget);
    expect(find.text('5 of 5 claimed'), findsOneWidget);
  });

  testWidgets(
    'falls back to English description and slot label when Marathi is blank '
    'and langCode is mr',
    (tester) async {
      final now = DateTime.now();
      final signup = Signup(
        id: 'signup_1',
        titleEn: 'Sunday Prasad Seva',
        titleMr: 'रविवार प्रसाद सेवा',
        descriptionEn: 'Cook and serve prasad',
        descriptionMr: '',
        groupId: 'gajanan_maharaj_seattle',
        status: SignupStatus.published,
        requiresJoinCode: false,
        createdAt: now,
        updatedAt: now,
        createdBy: 'admin@test.com',
      );

      final slots = [
        SignupSlot(
          id: 'slot_1',
          labelEn: 'Week 1 - Team A',
          labelMr: '',
          capacity: 5,
          claimedCount: 4,
          sortOrder: 0,
          createdAt: now,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                final theme = Theme.of(context);
                return SignupExportCard(
                  signup: signup,
                  slots: slots,
                  totalClaims: 4,
                  totalCapacity: 5,
                  groupName: 'Seattle',
                  l10n: l10n,
                  theme: theme,
                  langCode: 'mr',
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cook and serve prasad'), findsOneWidget);
      expect(find.text('Week 1 - Team A'), findsOneWidget);
    },
  );
}

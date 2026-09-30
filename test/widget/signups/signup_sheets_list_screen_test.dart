import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_sheet.dart';
import 'package:gajanan_maharaj_sevekari/providers/signup_service.dart';
import 'package:gajanan_maharaj_sevekari/signups/signup_sheets_list_screen.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late SignupService service;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = SignupService(firestore: firestore);
  });

  Widget wrap(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      onGenerateRoute: (settings) => MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text(settings.name ?? '')),
          body: Text('Navigated to: ${settings.name}'),
        ),
      ),
      home: child,
    );
  }

  Future<String> createSheet({
    String titleEn = 'Sunday Prasad Seva',
    String descriptionEn = '',
    SignupSheetStatus status = SignupSheetStatus.published,
    String groupId = 'group_1',
    bool requiresJoinCode = false,
  }) {
    final now = DateTime.now();
    return service.createSheet(
      SignupSheet(
        titleEn: titleEn,
        titleMr: '',
        descriptionEn: descriptionEn,
        descriptionMr: '',
        groupId: groupId,
        status: status,
        requiresJoinCode: requiresJoinCode,
        joinCode: requiresJoinCode ? 'ABC123' : null,
        createdAt: now,
        updatedAt: now,
        createdBy: 'admin@test.com',
      ),
    );
  }

  group('SignupSheetsListScreen', () {
    testWidgets('shows an invalid-group message when groupId is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          SignupSheetsListScreen(firestore: firestore, signupService: service),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Invalid group'), findsOneWidget);
    });

    testWidgets('shows an empty state when there are no active sheets', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          SignupSheetsListScreen(
            groupId: 'group_1',
            firestore: firestore,
            signupService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No active sign-up sheets'), findsOneWidget);
    });

    testWidgets(
      'lists published sheets for the group, with title and description',
      (tester) async {
        await createSheet(
          titleEn: 'Sunday Prasad Seva',
          descriptionEn: 'Cook and serve prasad',
        );

        await tester.pumpWidget(
          wrap(
            SignupSheetsListScreen(
              groupId: 'group_1',
              firestore: firestore,
              signupService: service,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Sunday Prasad Seva'), findsOneWidget);
        expect(find.text('Cook and serve prasad'), findsOneWidget);
      },
    );

    testWidgets('does not show draft or closed sheets', (tester) async {
      await createSheet(
        titleEn: 'Draft Sheet',
        status: SignupSheetStatus.draft,
      );
      await createSheet(
        titleEn: 'Closed Sheet',
        status: SignupSheetStatus.closed,
      );
      await createSheet(titleEn: 'Published Sheet');

      await tester.pumpWidget(
        wrap(
          SignupSheetsListScreen(
            groupId: 'group_1',
            firestore: firestore,
            signupService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Draft Sheet'), findsNothing);
      expect(find.text('Closed Sheet'), findsNothing);
      expect(find.text('Published Sheet'), findsOneWidget);
    });

    testWidgets('shows a join-code-required badge without revealing the code', (
      tester,
    ) async {
      await createSheet(titleEn: 'Members Sheet', requiresJoinCode: true);

      await tester.pumpWidget(
        wrap(
          SignupSheetsListScreen(
            groupId: 'group_1',
            firestore: firestore,
            signupService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Join Code Required'), findsOneWidget);
      expect(find.text('ABC123'), findsNothing);
    });

    testWidgets('tapping a sheet navigates to its detail route', (
      tester,
    ) async {
      await createSheet(titleEn: 'Sunday Prasad Seva');

      await tester.pumpWidget(
        wrap(
          SignupSheetsListScreen(
            groupId: 'group_1',
            firestore: firestore,
            signupService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sunday Prasad Seva'));
      await tester.pumpAndSettle();

      expect(find.text('Navigated to: /signup_sheet_detail'), findsOneWidget);
    });

    testWidgets('renders the Marathi title when locale is mr', (tester) async {
      final now = DateTime.now();
      await service.createSheet(
        SignupSheet(
          titleEn: 'Sunday Prasad Seva',
          titleMr: 'रविवार प्रसाद सेवा',
          groupId: 'group_1',
          status: SignupSheetStatus.published,
          createdAt: now,
          updatedAt: now,
          createdBy: 'admin@test.com',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('mr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SignupSheetsListScreen(
            groupId: 'group_1',
            firestore: firestore,
            signupService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('रविवार प्रसाद सेवा'), findsOneWidget);
    });
  });
}

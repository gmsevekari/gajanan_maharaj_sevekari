import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup.dart';
import 'package:gajanan_maharaj_sevekari/providers/festival_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/signup_service.dart';
import 'package:gajanan_maharaj_sevekari/settings/theme_provider.dart';
import 'package:gajanan_maharaj_sevekari/signups/signups_list_screen.dart';
import 'package:provider/provider.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late SignupService service;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = SignupService(firestore: firestore);
  });

  Widget wrap(Widget child, {Locale? locale}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => FestivalProvider()),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: Text(settings.name ?? '')),
            body: Text('Navigated to: ${settings.name}'),
          ),
        ),
        home: child,
      ),
    );
  }

  Future<String> createSignup({
    String titleEn = 'Sunday Prasad Seva',
    String descriptionEn = '',
    SignupStatus status = SignupStatus.published,
    String groupId = 'group_1',
    bool requiresJoinCode = false,
  }) {
    final now = DateTime.now();
    return service.createSignup(
      Signup(
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

  group('SignupsListScreen', () {
    testWidgets('shows an invalid-group message when groupId is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(SignupsListScreen(firestore: firestore, signupService: service)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Invalid group'), findsOneWidget);
    });

    testWidgets('tapping home icon navigates to home', (tester) async {
      await tester.pumpWidget(
        wrap(
          SignupsListScreen(
            groupId: 'group_1',
            firestore: firestore,
            signupService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find
            .byWidgetPredicate((w) => w is IconButton && w.onPressed != null)
            .first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Navigated to: /home'), findsOneWidget);
    });

    testWidgets('tapping settings icon navigates to settings', (tester) async {
      await tester.pumpWidget(
        wrap(
          SignupsListScreen(
            groupId: 'group_1',
            firestore: firestore,
            signupService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find
            .byWidgetPredicate((w) => w is IconButton && w.onPressed != null)
            .at(1),
      );
      await tester.pumpAndSettle();

      expect(find.text('Navigated to: /settings'), findsOneWidget);
    });

    testWidgets('shows an empty state when there are no active signups', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          SignupsListScreen(
            groupId: 'group_1',
            firestore: firestore,
            signupService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No active sign ups'), findsOneWidget);
    });

    testWidgets(
      'lists published signups for the group, with title and description',
      (tester) async {
        await createSignup(
          titleEn: 'Sunday Prasad Seva',
          descriptionEn: 'Cook and serve prasad',
        );

        await tester.pumpWidget(
          wrap(
            SignupsListScreen(
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

    testWidgets('does not show draft or closed signups', (tester) async {
      await createSignup(titleEn: 'Draft Signup', status: SignupStatus.draft);
      await createSignup(titleEn: 'Closed Signup', status: SignupStatus.closed);
      await createSignup(titleEn: 'Published Signup');

      await tester.pumpWidget(
        wrap(
          SignupsListScreen(
            groupId: 'group_1',
            firestore: firestore,
            signupService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Draft Signup'), findsNothing);
      expect(find.text('Closed Signup'), findsNothing);
      expect(find.text('Published Signup'), findsOneWidget);
    });

    testWidgets('shows a join-code-required badge without revealing the code', (
      tester,
    ) async {
      await createSignup(titleEn: 'Members Signup', requiresJoinCode: true);

      await tester.pumpWidget(
        wrap(
          SignupsListScreen(
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

    testWidgets('tapping a signup navigates to its detail route', (
      tester,
    ) async {
      await createSignup(titleEn: 'Sunday Prasad Seva');

      await tester.pumpWidget(
        wrap(
          SignupsListScreen(
            groupId: 'group_1',
            firestore: firestore,
            signupService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sunday Prasad Seva'));
      await tester.pumpAndSettle();

      expect(find.text('Navigated to: /signup_detail'), findsOneWidget);
    });

    testWidgets('renders the Marathi title when locale is mr', (tester) async {
      final now = DateTime.now();
      await service.createSignup(
        Signup(
          titleEn: 'Sunday Prasad Seva',
          titleMr: 'रविवार प्रसाद सेवा',
          descriptionEn: 'Cook and serve prasad',
          descriptionMr: 'प्रसाद शिजवा आणि वाढा',
          groupId: 'group_1',
          status: SignupStatus.published,
          createdAt: now,
          updatedAt: now,
          createdBy: 'admin@test.com',
        ),
      );

      await tester.pumpWidget(
        wrap(
          SignupsListScreen(
            groupId: 'group_1',
            firestore: firestore,
            signupService: service,
          ),
          locale: const Locale('mr'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('रविवार प्रसाद सेवा'), findsOneWidget);
      expect(find.text('प्रसाद शिजवा आणि वाढा'), findsOneWidget);
    });

    testWidgets('falls back to the English description when Marathi is blank', (
      tester,
    ) async {
      final now = DateTime.now();
      await service.createSignup(
        Signup(
          titleEn: 'Sunday Prasad Seva',
          titleMr: 'रविवार प्रसाद सेवा',
          descriptionEn: 'Cook and serve prasad',
          descriptionMr: '',
          groupId: 'group_1',
          status: SignupStatus.published,
          createdAt: now,
          updatedAt: now,
          createdBy: 'admin@test.com',
        ),
      );

      await tester.pumpWidget(
        wrap(
          SignupsListScreen(
            groupId: 'group_1',
            firestore: firestore,
            signupService: service,
          ),
          locale: const Locale('mr'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cook and serve prasad'), findsOneWidget);
    });
  });
}

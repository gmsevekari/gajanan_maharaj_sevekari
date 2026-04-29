import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:gajanan_maharaj_sevekari/admin/admin_gajanan_maharaj_group_screen.dart';
import 'package:gajanan_maharaj_sevekari/models/admin_user.dart';
import 'package:gajanan_maharaj_sevekari/models/app_config.dart';
import 'package:gajanan_maharaj_sevekari/providers/app_config_provider.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';

class MockAppConfigProvider extends Mock implements AppConfigProvider {}

void main() {
  late MockAppConfigProvider mockAppConfigProvider;
  final adminUser = AdminUser(email: 'test@example.com', roles: ['super_admin']);

  setUp(() {
    mockAppConfigProvider = MockAppConfigProvider();
    final appConfig = AppConfig(
      deities: [],
      gajananMaharajGroups: [
        GajananMaharajGroup(id: 'group1', nameEn: 'Group 1', nameMr: 'ग्रुप १', icon: null),
      ],
      socialMediaLinks: [],
      appName: {},
      updateMessage: {},
      latestVersion: '1.0.0',
      forceUpdate: 'false',
      playStoreUrl: '',
      appStoreUrl: '',
    );
    when(() => mockAppConfigProvider.appConfig).thenReturn(appConfig);
  });

  Widget createTestWidget({String mode = 'parayan'}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppConfigProvider>.value(value: mockAppConfigProvider),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        onGenerateRoute: (settings) {
          return MaterialPageRoute(builder: (context) => Scaffold(body: Text(settings.name ?? '')));
        },
        home: AdminGajananMaharajGroupScreen(adminUser: adminUser, mode: mode),
      ),
    );
  }

  testWidgets('shows Parayan title when mode is parayan', (tester) async {
    await tester.pumpWidget(createTestWidget(mode: 'parayan'));
    await tester.pumpAndSettle();
    expect(find.text('Parayan Groups'), findsOneWidget);
  });

  testWidgets('shows Namjap title when mode is namjap', (tester) async {
    await tester.pumpWidget(createTestWidget(mode: 'namjap'));
    await tester.pumpAndSettle();
    expect(find.text('Namjap Groups'), findsOneWidget);
  });

  testWidgets('navigates to Parayan Coordination when mode is parayan', (tester) async {
    await tester.pumpWidget(createTestWidget(mode: 'parayan'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Group 1'));
    await tester.pumpAndSettle();

    expect(find.text(Routes.adminParayanCoordination), findsOneWidget);
  });

  testWidgets('navigates to Namjap Dashboard when mode is namjap', (tester) async {
    await tester.pumpWidget(createTestWidget(mode: 'namjap'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Group 1'));
    await tester.pumpAndSettle();

    expect(find.text(Routes.adminGroupNamjapDashboard), findsOneWidget);
  });

  testWidgets('navigates to home when home button is pressed', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.home));
    await tester.pumpAndSettle();

    expect(find.text(Routes.home), findsOneWidget);
  });

  testWidgets('navigates to settings when settings button is pressed', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    expect(find.text(Routes.settings), findsOneWidget);
  });

  testWidgets('shows empty state when no groups are present', (tester) async {
    final appConfig = AppConfig(
      deities: [],
      gajananMaharajGroups: [],
      socialMediaLinks: [],
      appName: {},
      updateMessage: {},
      latestVersion: '1.0.0',
      forceUpdate: 'false',
      playStoreUrl: '',
      appStoreUrl: '',
    );
    when(() => mockAppConfigProvider.appConfig).thenReturn(appConfig);

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('No active parayans at the moment.'), findsOneWidget);
  });
}

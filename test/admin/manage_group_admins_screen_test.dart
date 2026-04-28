import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gajanan_maharaj_sevekari/admin/manage_group_admins_screen.dart';
import 'package:gajanan_maharaj_sevekari/admin/admin_management_service.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/admin_user.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:gajanan_maharaj_sevekari/settings/theme_provider.dart';
import 'package:gajanan_maharaj_sevekari/settings/font_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/festival_provider.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:gajanan_maharaj_sevekari/widgets/themed_icon.dart';
import '../mocks.dart';

class MockAdminManagementService extends Mock implements AdminManagementService {}

void main() {
  late MockAdminManagementService mockService;
  late MockThemeProvider mockThemeProvider;
  late MockFontProvider mockFontProvider;
  late MockFestivalProvider mockFestivalProvider;

  setUp(() {
    mockService = MockAdminManagementService();
    mockThemeProvider = MockThemeProvider();
    mockFontProvider = MockFontProvider();
    mockFestivalProvider = MockFestivalProvider();

    when(() => mockThemeProvider.themePreset).thenReturn(ThemePreset.tulsi);
    when(() => mockThemeProvider.themeMode).thenReturn(ThemeMode.light);
    when(() => mockThemeProvider.customColor).thenReturn(null);
    when(() => mockFestivalProvider.activeFestival).thenReturn(null);
  });

  Widget createTestWidget(AdminUser admin) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>.value(value: mockThemeProvider),
        ChangeNotifierProvider<FontProvider>.value(value: mockFontProvider),
        ChangeNotifierProvider<FestivalProvider>.value(value: mockFestivalProvider),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ManageGroupAdminsScreen(
          currentAdmin: admin,
          managementService: mockService,
        ),
      ),
    );
  }

  group('ManageGroupAdminsScreen Tests', () {
    final groupAdmin = AdminUser(
      email: 'group@test.com',
      roles: ['group_admin'],
      groupId: 'g1',
    );

    final superAdmin = AdminUser(
      email: 'super@test.com',
      roles: ['super_admin'],
    );

    testWidgets('shows group admins for group_admin', (tester) async {
      final adminList = [
        AdminUser(email: 'admin1@test.com', roles: ['group_admin'], groupId: 'g1'),
      ];

      when(() => mockService.getAdminsForGroup('g1'))
          .thenAnswer((_) => Stream.value(adminList));

      await tester.pumpWidget(createTestWidget(groupAdmin));
      await tester.pumpAndSettle();

      expect(find.text('admin1@test.com'), findsOneWidget);
      expect(find.text('g1'), findsWidgets);
    });

    testWidgets('shows all admins for super_admin', (tester) async {
      final adminList = [
        AdminUser(email: 'admin1@test.com', roles: ['group_admin'], groupId: 'g1'),
        AdminUser(email: 'admin2@test.com', roles: ['super_admin']),
      ];

      when(() => mockService.getAllAdmins())
          .thenAnswer((_) => Stream.value(adminList));

      await tester.pumpWidget(createTestWidget(superAdmin));
      await tester.pumpAndSettle();

      expect(find.text('admin1@test.com'), findsOneWidget);
      expect(find.text('admin2@test.com'), findsOneWidget);
    });

    testWidgets('groups admins correctly for super_admin with sorting', (tester) async {
      final adminList = [
        AdminUser(email: 'group1@test.com', roles: ['group_admin'], groupId: 'z_group'),
        AdminUser(email: 'super@test.com', roles: ['super_admin']),
        AdminUser(email: 'group2@test.com', roles: ['group_admin'], groupId: 'a_group'),
      ];

      when(() => mockService.getAllAdmins())
          .thenAnswer((_) => Stream.value(adminList));

      await tester.pumpWidget(createTestWidget(superAdmin));
      await tester.pumpAndSettle();

      // Check section headers order: Super Admins should be first
      final headers = find.byType(Text).evaluate()
          .map((e) => (e.widget as Text).data)
          .where((data) => data != null && (data == 'SUPER ADMINS' || data.contains('Group:')))
          .toList();

      expect(headers[0], 'SUPER ADMINS');
      expect(headers[1], contains('a_group'));
      expect(headers[2], contains('z_group'));
    });

    testWidgets('deletes admin after confirmation', (tester) async {
      final adminList = [
        AdminUser(email: 'admin1@test.com', roles: ['group_admin'], groupId: 'g1'),
      ];

      when(() => mockService.getAdminsForGroup('g1'))
          .thenAnswer((_) => Stream.value(adminList));
      when(() => mockService.deleteAdmin(any())).thenAnswer((_) async => {});

      await tester.pumpWidget(createTestWidget(groupAdmin));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('Are you sure you want to remove this admin?'), findsOneWidget);

      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();

      verify(() => mockService.deleteAdmin('admin1@test.com')).called(1);
      expect(find.text('Admin removed successfully'), findsOneWidget);
    });

    testWidgets('cancels admin deletion', (tester) async {
      final adminList = [
        AdminUser(email: 'admin1@test.com', roles: ['group_admin'], groupId: 'g1'),
      ];

      when(() => mockService.getAdminsForGroup('g1'))
          .thenAnswer((_) => Stream.value(adminList));

      await tester.pumpWidget(createTestWidget(groupAdmin));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      verifyNever(() => mockService.deleteAdmin(any()));
      expect(find.text('Are you sure you want to remove this admin?'), findsNothing);
    });

    testWidgets('shows error when deletion fails', (tester) async {
      final adminList = [
        AdminUser(email: 'admin1@test.com', roles: ['group_admin'], groupId: 'g1'),
      ];

      when(() => mockService.getAdminsForGroup('g1'))
          .thenAnswer((_) => Stream.value(adminList));
      when(() => mockService.deleteAdmin(any())).thenThrow('Delete Failed');

      await tester.pumpWidget(createTestWidget(groupAdmin));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();

      expect(find.textContaining('Error deleting admin: Delete Failed'), findsOneWidget);
    });

    testWidgets('shows error state when stream fails', (tester) async {
      when(() => mockService.getAdminsForGroup('g1'))
          .thenAnswer((_) => Stream.error('Firestore Error'));

      await tester.pumpWidget(createTestWidget(groupAdmin));
      await tester.pumpAndSettle();

      expect(find.textContaining('Firestore Error'), findsOneWidget);
    });

    testWidgets('shows empty state when no admins found', (tester) async {
      when(() => mockService.getAdminsForGroup('g1'))
          .thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(createTestWidget(groupAdmin));
      await tester.pumpAndSettle();

      expect(find.text('No admins found'), findsOneWidget);
    });

    testWidgets('navigates to home on icon tap', (tester) async {
      when(() => mockService.getAdminsForGroup('g1'))
          .thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ThemeProvider>.value(value: mockThemeProvider),
            ChangeNotifierProvider<FontProvider>.value(value: mockFontProvider),
            ChangeNotifierProvider<FestivalProvider>.value(value: mockFestivalProvider),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routes: {
              Routes.home: (context) => const Scaffold(body: Text('Home Screen')),
            },
            home: ManageGroupAdminsScreen(
              currentAdmin: groupAdmin,
              managementService: mockService,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.home));
      await tester.pumpAndSettle();

      expect(find.text('Home Screen'), findsOneWidget);
    });

    testWidgets('navigates to settings on icon tap', (tester) async {
      when(() => mockService.getAdminsForGroup('g1'))
          .thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ThemeProvider>.value(value: mockThemeProvider),
            ChangeNotifierProvider<FontProvider>.value(value: mockFontProvider),
            ChangeNotifierProvider<FestivalProvider>.value(value: mockFestivalProvider),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routes: {
              Routes.settings: (context) => const Scaffold(body: Text('Settings Screen')),
            },
            home: ManageGroupAdminsScreen(
              currentAdmin: groupAdmin,
              managementService: mockService,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap settings icon. Even with ThemedIcon, find.byIcon(Icons.settings) should work.
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      expect(find.text('Settings Screen'), findsOneWidget);
    });

    testWidgets('navigates to add admin screen on FAB tap', (tester) async {
      when(() => mockService.getAdminsForGroup('g1'))
          .thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ThemeProvider>.value(value: mockThemeProvider),
            ChangeNotifierProvider<FontProvider>.value(value: mockFontProvider),
            ChangeNotifierProvider<FestivalProvider>.value(value: mockFestivalProvider),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routes: {
              Routes.adminAddGroupAdmin: (context) => const Scaffold(body: Text('Add Admin Screen')),
            },
            home: ManageGroupAdminsScreen(
              currentAdmin: groupAdmin,
              managementService: mockService,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Manage Group Admins'), findsOneWidget);
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Add Admin Screen'), findsOneWidget);
    });
  });
}

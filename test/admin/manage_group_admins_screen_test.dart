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

class MockAdminManagementService extends Mock
    implements AdminManagementService {}

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
        ChangeNotifierProvider<FestivalProvider>.value(
          value: mockFestivalProvider,
        ),
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
        AdminUser(
          email: 'admin1@test.com',
          roles: ['group_admin'],
          groupId: 'g1',
        ),
      ];

      when(
        () => mockService.getAdminsForGroup('g1'),
      ).thenAnswer((_) => Stream.value(adminList));

      await tester.pumpWidget(createTestWidget(groupAdmin));
      await tester.pumpAndSettle();

      expect(find.text('admin1@test.com'), findsOneWidget);
      expect(find.text('g1'), findsWidgets);
    });

    testWidgets('shows all admins for super_admin', (tester) async {
      final adminList = [
        AdminUser(
          email: 'admin1@test.com',
          roles: ['group_admin'],
          groupId: 'g1',
        ),
        AdminUser(email: 'admin2@test.com', roles: ['super_admin']),
      ];

      when(
        () => mockService.getAllAdmins(),
      ).thenAnswer((_) => Stream.value(adminList));

      await tester.pumpWidget(createTestWidget(superAdmin));
      await tester.pumpAndSettle();

      expect(find.text('admin1@test.com'), findsOneWidget);
      expect(find.text('admin2@test.com'), findsOneWidget);
    });

    testWidgets('groups admins correctly for super_admin with sorting', (
      tester,
    ) async {
      final adminList = [
        AdminUser(
          email: 'group1@test.com',
          roles: ['group_admin'],
          groupId: 'z_group',
        ),
        AdminUser(email: 'super@test.com', roles: ['super_admin']),
        AdminUser(
          email: 'group2@test.com',
          roles: ['group_admin'],
          groupId: 'a_group',
        ),
      ];

      when(
        () => mockService.getAllAdmins(),
      ).thenAnswer((_) => Stream.value(adminList));

      await tester.pumpWidget(createTestWidget(superAdmin));
      await tester.pumpAndSettle();

      // Check section headers order: Super Admin should be first
      // We look for text that is NOT inside a chip (Container with specific padding)
      final headerWidgets = find
          .byType(Text)
          .evaluate()
          .map((e) => (e.widget as Text).data)
          .where(
            (data) =>
                data != null &&
                (data == 'SUPER ADMIN' || data.contains('Group:')),
          )
          .toList();

      // Headers should be at the expected positions. Note that 'SUPER ADMIN' might appear twice
      // if there's an admin with that role in the first group, but the headers themselves
      // are at the start of each section.
      expect(
        headerWidgets,
        containsAllInOrder(['SUPER ADMIN', 'Group: a_group', 'Group: z_group']),
      );
    });

    testWidgets('navigates to edit admin screen on edit icon tap', (
      tester,
    ) async {
      final adminList = [
        AdminUser(
          email: 'admin1@test.com',
          roles: ['group_admin'],
          groupId: 'g1',
        ),
      ];

      when(
        () => mockService.getAdminsForGroup('g1'),
      ).thenAnswer((_) => Stream.value(adminList));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ThemeProvider>.value(
              value: mockThemeProvider,
            ),
            ChangeNotifierProvider<FontProvider>.value(value: mockFontProvider),
            ChangeNotifierProvider<FestivalProvider>.value(
              value: mockFestivalProvider,
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routes: {
              Routes.adminAddGroupAdmin: (context) {
                final args =
                    ModalRoute.of(context)!.settings.arguments
                        as Map<String, dynamic>;
                if (args['adminToEdit']?.email == 'admin1@test.com') {
                  return const Scaffold(body: Text('Edit Admin Screen'));
                }
                return const Scaffold(body: Text('Add Admin Screen'));
              },
            },
            home: ManageGroupAdminsScreen(
              currentAdmin: groupAdmin,
              managementService: mockService,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Edit Admin Screen'), findsOneWidget);
    });

    testWidgets('shows error state when stream fails', (tester) async {
      when(
        () => mockService.getAdminsForGroup('g1'),
      ).thenAnswer((_) => Stream.error('Firestore Error'));

      await tester.pumpWidget(createTestWidget(groupAdmin));
      await tester.pumpAndSettle();

      expect(find.textContaining('Firestore Error'), findsOneWidget);
    });

    testWidgets('shows empty state when no admins found', (tester) async {
      when(
        () => mockService.getAdminsForGroup('g1'),
      ).thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(createTestWidget(groupAdmin));
      await tester.pumpAndSettle();

      expect(find.text('No admins found'), findsOneWidget);
    });

    testWidgets('navigates to home on icon tap', (tester) async {
      when(
        () => mockService.getAdminsForGroup('g1'),
      ).thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ThemeProvider>.value(
              value: mockThemeProvider,
            ),
            ChangeNotifierProvider<FontProvider>.value(value: mockFontProvider),
            ChangeNotifierProvider<FestivalProvider>.value(
              value: mockFestivalProvider,
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routes: {
              Routes.home: (context) =>
                  const Scaffold(body: Text('Home Screen')),
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
      when(
        () => mockService.getAdminsForGroup('g1'),
      ).thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ThemeProvider>.value(
              value: mockThemeProvider,
            ),
            ChangeNotifierProvider<FontProvider>.value(value: mockFontProvider),
            ChangeNotifierProvider<FestivalProvider>.value(
              value: mockFestivalProvider,
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routes: {
              Routes.settings: (context) =>
                  const Scaffold(body: Text('Settings Screen')),
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
      when(
        () => mockService.getAdminsForGroup('g1'),
      ).thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ThemeProvider>.value(
              value: mockThemeProvider,
            ),
            ChangeNotifierProvider<FontProvider>.value(value: mockFontProvider),
            ChangeNotifierProvider<FestivalProvider>.value(
              value: mockFestivalProvider,
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routes: {
              Routes.adminAddGroupAdmin: (context) =>
                  const Scaffold(body: Text('Add Admin Screen')),
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
      final fab = tester.widget<FloatingActionButton>(
        find.byType(FloatingActionButton),
      );

      expect(fab.backgroundColor, AppTheme.lightTheme.colorScheme.primary);
      expect(fab.foregroundColor, AppTheme.lightTheme.colorScheme.onPrimary);
      expect(find.byIcon(Icons.person_add), findsOneWidget);
      expect(find.text('ADD ADMIN'), findsOneWidget);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Add Admin Screen'), findsOneWidget);
    });
  });
}

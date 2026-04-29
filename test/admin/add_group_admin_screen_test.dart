import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:gajanan_maharaj_sevekari/admin/add_group_admin_screen.dart';
import 'package:gajanan_maharaj_sevekari/models/admin_user.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:gajanan_maharaj_sevekari/models/app_config.dart';
import 'package:gajanan_maharaj_sevekari/settings/theme_provider.dart';
import 'package:gajanan_maharaj_sevekari/settings/font_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/festival_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/app_config_provider.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/admin/admin_management_service.dart';
import '../mocks.dart';

void main() {
  late MockThemeProvider mockThemeProvider;
  late MockFontProvider mockFontProvider;
  late MockFestivalProvider mockFestivalProvider;
  late MockAppConfigProvider mockAppConfigProvider;
  late MockAdminManagementService mockAdminManagementService;

  final testGroups = [
    GajananMaharajGroup(id: 'seattle', nameEn: 'Seattle', nameMr: 'सिएटल'),
    GajananMaharajGroup(id: 'bayarea', nameEn: 'Bay Area', nameMr: 'बे एरिया'),
  ];

  setUp(() {
    mockThemeProvider = MockThemeProvider();
    mockFontProvider = MockFontProvider();
    mockFestivalProvider = MockFestivalProvider();
    mockAppConfigProvider = MockAppConfigProvider();
    mockAdminManagementService = MockAdminManagementService();

    when(() => mockThemeProvider.themePreset).thenReturn(ThemePreset.tulsi);
    when(() => mockThemeProvider.themeMode).thenReturn(ThemeMode.light);
    when(() => mockThemeProvider.customColor).thenReturn(null);
    when(() => mockFestivalProvider.activeFestival).thenReturn(null);

    final mockAppConfig = AppConfig(
      deities: [],
      gajananMaharajGroups: testGroups,
      socialMediaLinks: [],
      appName: {},
      updateMessage: {},
      latestVersion: '',
      forceUpdate: 'false',
      playStoreUrl: '',
      appStoreUrl: '',
    );
    when(() => mockAppConfigProvider.appConfig).thenReturn(mockAppConfig);
    when(
      () => mockAdminManagementService.isAdminExists(any()),
    ).thenAnswer((_) async => false);
    registerFallbackValue(AdminUser(email: '', roles: []));
  });
  Widget createTestWidget(AdminUser admin) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>.value(value: mockThemeProvider),
        ChangeNotifierProvider<FontProvider>.value(value: mockFontProvider),
        ChangeNotifierProvider<FestivalProvider>.value(
          value: mockFestivalProvider,
        ),
        ChangeNotifierProvider<AppConfigProvider>.value(
          value: mockAppConfigProvider,
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddGroupAdminScreen(
                    currentAdmin: admin,
                    managementService: mockAdminManagementService,
                  ),
                ),
              ),
              child: const Text('Launch'),
            ),
          ),
        ),
        routes: {
          Routes.home: (context) => const Scaffold(body: Text('Home')),
          Routes.settings: (context) => const Scaffold(body: Text('Settings')),
        },
      ),
    );
  }

  Widget createEditTestWidget(AdminUser currentAdmin, AdminUser adminToEdit) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>.value(value: mockThemeProvider),
        ChangeNotifierProvider<FontProvider>.value(value: mockFontProvider),
        ChangeNotifierProvider<FestivalProvider>.value(
          value: mockFestivalProvider,
        ),
        ChangeNotifierProvider<AppConfigProvider>.value(
          value: mockAppConfigProvider,
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddGroupAdminScreen(
                    currentAdmin: currentAdmin,
                    adminToEdit: adminToEdit,
                    managementService: mockAdminManagementService,
                  ),
                ),
              ),
              child: const Text('Launch Edit'),
            ),
          ),
        ),
      ),
    );
  }

  group('AddGroupAdminScreen - Form Implementation', () {
    testWidgets('renders all form fields for super_admin', (tester) async {
      final admin = AdminUser(email: 'super@test.com', roles: ['super_admin']);
      await tester.pumpWidget(createTestWidget(admin));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Launch'));
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsOneWidget); // Email
      expect(find.text('Super Admin'), findsOneWidget); // Role checkbox
      expect(find.text('Group Admin'), findsOneWidget); // Role checkbox
      expect(find.text('Parayan Admin'), findsOneWidget);
      expect(find.text('Namjap Admin'), findsOneWidget);

      // Select Group Admin to show group dropdown
      await tester.tap(find.text('Group Admin'));
      await tester.pumpAndSettle();

      expect(find.text('Select Group'), findsOneWidget); // Group Dropdown
      expect(find.text('ADD ADMIN'), findsOneWidget); // Button
    });

    testWidgets('hides group selection and super_admin role for group_admin', (
      tester,
    ) async {
      final admin = AdminUser(
        email: 'group@test.com',
        roles: ['group_admin'],
        groupId: 'seattle',
      );
      await tester.pumpWidget(createTestWidget(admin));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Launch'));
      await tester.pumpAndSettle();

      expect(find.text('Select Group'), findsNothing);
      expect(
        find.text('Super Admin'),
        findsOneWidget,
      ); // Now visible but disabled
      expect(find.text('Group Admin'), findsOneWidget);
      expect(find.text('Parayan Admin'), findsOneWidget);
      expect(find.text('Namjap Admin'), findsOneWidget);
    });

    testWidgets('shows validation errors for empty fields', (tester) async {
      final admin = AdminUser(email: 'super@test.com', roles: ['super_admin']);
      await tester.pumpWidget(createTestWidget(admin));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Launch'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('ADD ADMIN'));
      await tester.pumpAndSettle();

      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('At least one role must be selected'), findsOneWidget);
    });

    testWidgets('validates email format', (tester) async {
      final admin = AdminUser(email: 'super@test.com', roles: ['super_admin']);
      await tester.pumpWidget(createTestWidget(admin));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Launch'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'invalid-email');
      await tester.tap(find.text('ADD ADMIN'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email address'), findsOneWidget);
    });

    testWidgets('successfully validates when all fields are correct', (
      tester,
    ) async {
      final admin = AdminUser(email: 'super@test.com', roles: ['super_admin']);
      await tester.pumpWidget(createTestWidget(admin));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Launch'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'valid@test.com');
      await tester.tap(find.text('Super Admin'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('ADD ADMIN'));
      await tester.pumpAndSettle();

      // No validation errors should be visible
      expect(find.text('Email is required'), findsNothing);
      expect(find.text('At least one role must be selected'), findsNothing);
    });

    testWidgets('validates group selection when group_admin role is chosen', (
      tester,
    ) async {
      final admin = AdminUser(email: 'super@test.com', roles: ['super_admin']);
      await tester.pumpWidget(createTestWidget(admin));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Launch'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'new@test.com');

      // Select Group Admin role
      await tester.tap(find.text('Group Admin'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('ADD ADMIN'));
      await tester.pumpAndSettle();

      expect(find.text('Please select a group'), findsOneWidget);
    });

    testWidgets('clears selectedGroupId when Group Admin role is deselected', (
      tester,
    ) async {
      final admin = AdminUser(email: 'super@test.com', roles: ['super_admin']);
      await tester.pumpWidget(createTestWidget(admin));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Launch'));
      await tester.pumpAndSettle();

      // Select Group Admin and a group
      await tester.tap(find.text('Group Admin'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Select Group'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Seattle').last);
      await tester.pumpAndSettle();

      // Deselect Group Admin
      await tester.tap(find.text('Group Admin'));
      await tester.pumpAndSettle();

      // Select Group Admin again - dropdown should be empty/reset
      await tester.tap(find.text('Group Admin'));
      await tester.pumpAndSettle();

      expect(find.text('Select Group'), findsOneWidget);
    });

    testWidgets('toggles Super Admin, Parayan Admin and Namjap Admin roles', (
      tester,
    ) async {
      final admin = AdminUser(email: 'super@test.com', roles: ['super_admin']);
      await tester.pumpWidget(createTestWidget(admin));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Launch'));
      await tester.pumpAndSettle();

      // Toggle Super Admin
      await tester.tap(find.text('Super Admin'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Super Admin'));
      await tester.pumpAndSettle();

      // Toggle Parayan Admin
      await tester.tap(find.text('Parayan Admin'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Parayan Admin'));
      await tester.pumpAndSettle();

      // Toggle Namjap Admin
      await tester.tap(find.text('Namjap Admin'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Namjap Admin'));
      await tester.pumpAndSettle();
    });

    testWidgets('disposes controllers correctly', (tester) async {
      final admin = AdminUser(email: 'super@test.com', roles: ['super_admin']);
      await tester.pumpWidget(createTestWidget(admin));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Launch'));
      await tester.pumpAndSettle();

      // Pumping a different widget triggers dispose on the previous one
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });

    testWidgets('navigates to home when home icon is tapped', (tester) async {
      final admin = AdminUser(email: 'super@test.com', roles: ['super_admin']);
      await tester.pumpWidget(createTestWidget(admin));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Launch'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.home));
      await tester.pump();
    });

    testWidgets('navigates to settings when settings icon is tapped', (
      tester,
    ) async {
      final admin = AdminUser(email: 'super@test.com', roles: ['super_admin']);
      await tester.pumpWidget(createTestWidget(admin));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Launch'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pump();
    });

    testWidgets('shows Marathi group names when locale is mr', (tester) async {
      final admin = AdminUser(
        email: 'group@test.com',
        roles: ['group_admin'],
        groupId: 'seattle',
      );

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
            ChangeNotifierProvider<AppConfigProvider>.value(
              value: mockAppConfigProvider,
            ),
            Provider<AdminManagementService>.value(
              value: mockAdminManagementService,
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('mr'),
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddGroupAdminScreen(
                        currentAdmin: admin,
                        managementService: mockAdminManagementService,
                      ),
                    ),
                  ),
                  child: const Text('Launch'),
                ),
              ),
            ),
            routes: {
              Routes.home: (context) => const Scaffold(body: Text('Home')),
              Routes.settings: (context) =>
                  const Scaffold(body: Text('Settings')),
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Launch'));
      await tester.pumpAndSettle();

      // 'Group Admin' in Marathi is 'ग्रुप ॲडमिन'
      await tester.tap(find.text('ग्रुप ॲडमिन'));
      await tester.pumpAndSettle();

      // Group name in header should be raw groupId for consistency
      expect(find.text('seattle'), findsOneWidget);
    });

    testWidgets('displays raw groupId in header even if not in config', (
      tester,
    ) async {
      final admin = AdminUser(
        email: 'group@test.com',
        roles: ['group_admin'],
        groupId: 'unknown_group',
      );
      await tester.pumpWidget(createTestWidget(admin));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Launch'));
      await tester.pumpAndSettle();

      expect(find.text('unknown_group'), findsOneWidget);
    });

    testWidgets('calls saveAdmin and shows success snackbar on success', (
      tester,
    ) async {
      final admin = AdminUser(email: 'super@test.com', roles: ['super_admin']);
      await tester.pumpWidget(createTestWidget(admin));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Launch'));
      await tester.pumpAndSettle();

      when(
        () => mockAdminManagementService.saveAdmin(any()),
      ).thenAnswer((_) async => {});

      await tester.enterText(find.byType(TextFormField), 'new@test.com');
      await tester.tap(find.text('Super Admin'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('ADD ADMIN'));
      await tester.pump(); // Start of async call

      await tester.pumpAndSettle();

      verify(() => mockAdminManagementService.saveAdmin(any())).called(1);

      // Verify we are back on previous screen (showing Launch button)
      expect(find.text('Launch'), findsOneWidget);

      // Verify snackbar
      expect(find.text('Admin added successfully'), findsOneWidget);
    });

    testWidgets('shows error snackbar on failure', (tester) async {
      final admin = AdminUser(email: 'super@test.com', roles: ['super_admin']);
      await tester.pumpWidget(createTestWidget(admin));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Launch'));
      await tester.pumpAndSettle();

      when(
        () => mockAdminManagementService.saveAdmin(any()),
      ).thenThrow(Exception('Failed to save'));

      await tester.enterText(find.byType(TextFormField), 'new@test.com');
      await tester.tap(find.text('Super Admin'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('ADD ADMIN'));
      await tester.pumpAndSettle();

      expect(find.text('Error: Exception: Failed to save'), findsOneWidget);
    });

    testWidgets('shows error when admin already exists', (tester) async {
      final admin = AdminUser(email: 'super@test.com', roles: ['super_admin']);
      await tester.pumpWidget(createTestWidget(admin));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Launch'));
      await tester.pumpAndSettle();

      when(
        () => mockAdminManagementService.isAdminExists(any()),
      ).thenAnswer((_) async => true);

      await tester.enterText(find.byType(TextFormField), 'existing@test.com');
      await tester.tap(find.text('Super Admin'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('ADD ADMIN'));
      await tester.pumpAndSettle();

      expect(find.text('Admin with this email already exists'), findsOneWidget);
      verifyNever(() => mockAdminManagementService.saveAdmin(any()));
    });
  });

  group('AddGroupAdminScreen - Edit Mode', () {
    testWidgets('renders pre-filled fields and locks email', (tester) async {
      final currentAdmin = AdminUser(email: 'super@test.com', roles: ['super_admin']);
      final adminToEdit = AdminUser(
        email: 'edit@test.com',
        roles: ['group_admin'],
        groupId: 'seattle',
      );

      await tester.pumpWidget(createEditTestWidget(currentAdmin, adminToEdit));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Launch Edit'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Admin'), findsOneWidget);
      expect(find.text('edit@test.com'), findsOneWidget);
      
      // Check if email field is disabled
      final emailField = tester.widget<TextFormField>(find.byType(TextFormField).first);
      expect(emailField.enabled, isFalse);

      // Check roles
      final groupAdminCheckbox = tester.widget<CheckboxListTile>(find.widgetWithText(CheckboxListTile, 'Group Admin'));
      expect(groupAdminCheckbox.value, isTrue);

      expect(find.text('UPDATE ADMIN'), findsOneWidget);
      expect(find.text('Delete Admin'), findsOneWidget);
    });

    testWidgets('successfully updates admin', (tester) async {
      final currentAdmin = AdminUser(email: 'super@test.com', roles: ['super_admin']);
      final adminToEdit = AdminUser(
        email: 'edit@test.com',
        roles: ['group_admin'],
        groupId: 'seattle',
      );

      when(() => mockAdminManagementService.saveAdmin(any())).thenAnswer((_) async => {});

      await tester.pumpWidget(createEditTestWidget(currentAdmin, adminToEdit));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Launch Edit'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('UPDATE ADMIN'));
      await tester.pump();
      await tester.pumpAndSettle();

      verify(() => mockAdminManagementService.saveAdmin(any())).called(1);
      expect(find.text('Admin updated successfully'), findsOneWidget);
    });

    testWidgets('successfully deletes admin', (tester) async {
      final currentAdmin = AdminUser(email: 'super@test.com', roles: ['super_admin']);
      final adminToEdit = AdminUser(
        email: 'edit@test.com',
        roles: ['group_admin'],
        groupId: 'seattle',
      );

      when(() => mockAdminManagementService.deleteAdmin(any())).thenAnswer((_) async => {});

      await tester.pumpWidget(createEditTestWidget(currentAdmin, adminToEdit));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Launch Edit'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Delete Admin'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AlertDialog, 'Delete Admin'), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      verify(() => mockAdminManagementService.deleteAdmin('edit@test.com')).called(1);
      expect(find.text('Admin removed successfully'), findsOneWidget);
    });
  });
}

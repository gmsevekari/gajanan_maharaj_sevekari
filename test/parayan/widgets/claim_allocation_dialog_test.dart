import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gajanan_maharaj_sevekari/parayan/widgets/claim_allocation_dialog.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/providers/festival_provider.dart';
import 'package:gajanan_maharaj_sevekari/settings/theme_provider.dart';
import 'package:gajanan_maharaj_sevekari/settings/font_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/app_config_provider.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gajanan_maharaj_sevekari/utils/notification_service_helper.dart';
import 'package:gajanan_maharaj_sevekari/notifications/notification_constants.dart';
import '../../mocks.dart';

void main() {
  late MockParayanService mockService;
  late MockFestivalProvider mockFestivalProvider;
  late MockThemeProvider mockThemeProvider;
  late MockFirebaseMessaging mockFirebaseMessaging;
  late MockFontProvider mockFontProvider;
  late MockAppConfigProvider mockAppConfigProvider;

  setUp(() {
    mockService = MockParayanService();
    mockFestivalProvider = MockFestivalProvider();
    mockThemeProvider = MockThemeProvider();
    mockFirebaseMessaging = MockFirebaseMessaging();
    mockFontProvider = MockFontProvider();
    mockAppConfigProvider = MockAppConfigProvider();

    when(() => mockFestivalProvider.activeFestival).thenReturn(null);
    when(() => mockThemeProvider.themePreset).thenReturn(ThemePreset.tulsi);
    when(() => mockThemeProvider.themeMode).thenReturn(ThemeMode.light);
    when(() => mockThemeProvider.customColor).thenReturn(null);
    when(
      () => mockFirebaseMessaging.subscribeToTopic(any()),
    ).thenAnswer((_) async => {});

    NotificationServiceHelper.overrideMessaging = mockFirebaseMessaging;

    SharedPreferences.setMockInitialValues({
      NotificationConstants.parayanRemindersPrefKey: true,
    });
  });

  Widget createTestWidget(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<FestivalProvider>.value(
          value: mockFestivalProvider,
        ),
        ChangeNotifierProvider<ThemeProvider>.value(value: mockThemeProvider),
        ChangeNotifierProvider<FontProvider>.value(value: mockFontProvider),
        ChangeNotifierProvider<AppConfigProvider>.value(
          value: mockAppConfigProvider,
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );
  }

  Widget _wrapDialog(Widget dialog) {
    return Builder(
      builder: (context) {
        return ElevatedButton(
          onPressed: () => showDialog(context: context, builder: (_) => dialog),
          child: const Text('Open Dialog'),
        );
      },
    );
  }

  group('ClaimAllocationDialog Tests', () {
    testWidgets('initial render and validation', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          _wrapDialog(
            ClaimAllocationDialog(
              eventId: 'e1',
              deviceId: 'd1',
              daysCount: 3,
              parayanService: mockService,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Find My Adhyays').first, findsOneWidget);
      expect(find.text('Code').first, findsOneWidget);
      expect(find.text('+91').first, findsOneWidget);

      // Submit without input
      await tester.tap(find.text('Submit'));
      await tester.pump();

      expect(find.text('Please enter a valid phone number'), findsOneWidget);
    });

    testWidgets('successful claim flow', (tester) async {
      when(
        () => mockService.claimAllocation(
          eventId: any(named: 'eventId'),
          phone: any(named: 'phone'),
          deviceId: any(named: 'deviceId'),
          overwrite: any(named: 'overwrite'),
        ),
      ).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return {'status': 'SUCCESS'};
      });

      await tester.pumpWidget(
        createTestWidget(
          _wrapDialog(
            ClaimAllocationDialog(
              eventId: 'e1',
              deviceId: 'd1',
              daysCount: 3,
              parayanService: mockService,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).last, '9876543210');
      await tester.tap(find.text('Submit'));

      // 1. Initial pump to start the async operation
      await tester.pump();

      // 2. Pump again to see the loading indicator (optional but good for coverage)
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // 3. Wait for the future to complete
      await tester.pump(const Duration(seconds: 1));

      // 4. Wait for snackbar animation
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Verify snackbar exists
      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text('Adhyay allocation linked successfully!'),
        findsOneWidget,
      );

      // Dialog should be popped
      await tester.pumpAndSettle();
      expect(find.byType(ClaimAllocationDialog), findsNothing);
    });

    testWidgets('conflict flow and overwrite', (tester) async {
      // First call returns CONFLICT
      when(
        () => mockService.claimAllocation(
          eventId: 'e1',
          phone: '+919876543210',
          deviceId: 'd1',
          overwrite: false,
        ),
      ).thenAnswer((_) async => {'status': 'CONFLICT'});

      // Second call (overwrite) returns SUCCESS
      when(
        () => mockService.claimAllocation(
          eventId: 'e1',
          phone: '+919876543210',
          deviceId: 'd1',
          overwrite: true,
        ),
      ).thenAnswer((_) async => {'status': 'SUCCESS'});

      await tester.pumpWidget(
        createTestWidget(
          _wrapDialog(
            ClaimAllocationDialog(
              eventId: 'e1',
              deviceId: 'd1',
              daysCount: 3,
              parayanService: mockService,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).last, '9876543210');
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      // Verify conflict dialog
      expect(
        find.textContaining('This phone number is already linked'),
        findsOneWidget,
      );

      // Tap Yes to overwrite
      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();

      // Verify success and dialog closed
      expect(
        find.text('Adhyay allocation linked successfully!'),
        findsOneWidget,
      );
      expect(find.byType(ClaimAllocationDialog), findsNothing);
    });

    testWidgets('handles NOT_FOUND status', (tester) async {
      when(
        () => mockService.claimAllocation(
          phone: any(named: 'phone'),
          deviceId: any(named: 'deviceId'),
          overwrite: any(named: 'overwrite'),
          eventId: any(named: 'eventId'),
        ),
      ).thenAnswer((_) async => {'status': 'NOT_FOUND'});

      await tester.pumpWidget(
        createTestWidget(
          _wrapDialog(
            ClaimAllocationDialog(
              eventId: 'e1',
              deviceId: 'd1',
              daysCount: 3,
              parayanService: mockService,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).last, '0000000000');
      await tester.tap(find.text('Submit'));

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      expect(
        find.text('No allocation found for this phone number.'),
        findsOneWidget,
      );
    });

    testWidgets('handles general service errors', (tester) async {
      when(
        () => mockService.claimAllocation(
          phone: any(named: 'phone'),
          deviceId: any(named: 'deviceId'),
          overwrite: any(named: 'overwrite'),
          eventId: any(named: 'eventId'),
        ),
      ).thenThrow('Service failure');

      await tester.pumpWidget(
        createTestWidget(
          _wrapDialog(
            ClaimAllocationDialog(
              eventId: 'e1',
              deviceId: 'd1',
              daysCount: 3,
              parayanService: mockService,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).last, '9999999999');
      await tester.tap(find.text('Submit'));

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('Error: Service failure'), findsOneWidget);
    });

    testWidgets('validation for country code and cancel action', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          _wrapDialog(
            ClaimAllocationDialog(
              eventId: 'e1',
              deviceId: 'd1',
              daysCount: 3,
              parayanService: mockService,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Test country code validation
      await tester.enterText(
        find.byType(TextFormField).first,
        '91',
      ); // Missing +
      await tester.tap(find.text('Submit'));
      await tester.pump();
      expect(find.text('!'), findsOneWidget);

      // Test cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(ClaimAllocationDialog), findsNothing);
    });
    testWidgets('conflict flow and cancel (No)', (tester) async {
      when(
        () => mockService.claimAllocation(
          eventId: any(named: 'eventId'),
          phone: any(named: 'phone'),
          deviceId: any(named: 'deviceId'),
          overwrite: any(named: 'overwrite'),
        ),
      ).thenAnswer((_) async => {'status': 'CONFLICT'});

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('mr')],
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => ClaimAllocationDialog(
                      eventId: 'e1',
                      deviceId: 'd1',
                      daysCount: 3,
                      parayanService: mockService,
                    ),
                  ),
                  child: const Text('Open Dialog'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Enter phone number
      await tester.enterText(find.byType(TextField).last, '1234567890');
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      // Check conflict dialog - use partial text match for alreadyLinkedPrompt
      expect(find.textContaining('already linked'), findsOneWidget);

      // Tap No
      await tester.tap(find.text('No'));
      await tester.pumpAndSettle();

      // Should be back to initial dialog
      expect(find.textContaining('already linked'), findsNothing);
      expect(find.text('Find My Adhyays').first, findsOneWidget);
    });
  });
}

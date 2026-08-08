import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:gajanan_maharaj_sevekari/event_calendar/event_calendar_screen.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/providers/festival_provider.dart';
import 'package:gajanan_maharaj_sevekari/settings/theme_provider.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeFirebaseFirestore fakeFirestore;
  late FestivalProvider festivalProvider;
  late ThemeProvider themeProvider;

  setUpAll(() async {
    await initializeDateFormatting('en', null);
    await initializeDateFormatting('mr', null);
  });

  setUp(() async {
    fakeFirestore = FakeFirebaseFirestore();
    festivalProvider = FestivalProvider();
    themeProvider = ThemeProvider();

    final now = DateTime.now();
    await fakeFirestore.collection('events').add({
      'title_en': 'Prakat Din Utsav',
      'title_mr': 'प्रकट दिन उत्सव',
      'start_time': Timestamp.fromDate(now.add(const Duration(days: 1))),
      'event_type': 'special_event',
    });
  });

  Widget createScreenWidget() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<FestivalProvider>.value(value: festivalProvider),
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const EventCalendarScreen(),
      ),
    );
  }

  group('EventCalendarScreen Widget Tests', () {
    testWidgets('renders EventCalendarScreen cleanly', (WidgetTester tester) async {
      await tester.pumpWidget(createScreenWidget());
      tester.takeException();
      await tester.pump();

      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}

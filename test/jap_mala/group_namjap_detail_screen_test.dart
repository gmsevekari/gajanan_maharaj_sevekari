import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/jap_mala/group_namjap_detail_screen.dart';
import 'package:gajanan_maharaj_sevekari/models/group_namjap_event.dart';
import 'package:gajanan_maharaj_sevekari/providers/group_namjap_service.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:gajanan_maharaj_sevekari/settings/theme_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/festival_provider.dart';
import 'package:mocktail/mocktail.dart';

class MockGroupNamjapService extends Mock implements GroupNamjapService {}

void main() {
  late MockGroupNamjapService mockService;
  late GroupNamjapEvent mockEvent;

  setUp(() {
    mockService = MockGroupNamjapService();
    mockEvent = GroupNamjapEvent(
      id: 'test_event',
      nameEn: 'Test Event',
      nameMr: 'चाचणी इव्हेंट',
      sankalpEn: 'Test Sankalp',
      sankalpMr: 'चाचणी संकल्प',
      mantra: 'Gan Gan Ganat Bote',
      targetCount: 1000,
      totalCount: 500,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 7)),
      createdAt: DateTime.now(),
      status: 'ongoing',
      joinCode: '123456',
      groupId: 'seattle',
    );

    when(() => mockService.getEventStream('test_event'))
        .thenAnswer((_) => Stream.value(mockEvent));
    when(() => mockService.getParticipantStream(any(), any(), any()))
        .thenAnswer((_) => Stream.value(null));
  });

  testWidgets('GroupNamjapDetailScreen shows event details', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => FestivalProvider()),
          ChangeNotifierProvider<GroupNamjapService>.value(value: mockService),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('en')],
          home: GroupNamjapDetailScreen(eventId: 'test_event'),
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 1)); // Wait for streams and layout

    // Expect to see Mantra and Sankalp
    expect(find.text('Gan Gan Ganat Bote'), findsOneWidget);
    expect(find.text('Test Sankalp'), findsOneWidget);
    
    // Expect to see stats
    expect(find.textContaining('500 / 1000'), findsOneWidget);
  });
}

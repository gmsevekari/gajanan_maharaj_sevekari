import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/jap_mala/group_namjap_list_screen.dart';
import 'package:gajanan_maharaj_sevekari/widgets/themed_icon.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:gajanan_maharaj_sevekari/settings/theme_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/group_namjap_service.dart';
import 'package:gajanan_maharaj_sevekari/providers/festival_provider.dart';

import 'package:mocktail/mocktail.dart';

class MockGroupNamjapService extends Mock implements GroupNamjapService {}

void main() {
  late MockGroupNamjapService mockService;

  setUp(() {
    mockService = MockGroupNamjapService();
    when(
      () => mockService.getActiveEvents(any()),
    ).thenAnswer((_) => Stream.value([]));
    when(
      () => mockService.getCompletedEvents(any()),
    ).thenAnswer((_) => Stream.value([]));
  });

  testWidgets('GroupNamjapListScreen renders with two tabs', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

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
          supportedLocales: [Locale('en'), Locale('mr')],
          locale: Locale('en'),
          home: GroupNamjapListScreen(),
        ),
      ),
    );

    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.pumpAndSettle();

    // Verify AppBar
    expect(find.byType(AppBar), findsOneWidget);

    // Verify Tabs
    expect(find.text('Upcoming / Active'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);

    // Verify Title
    expect(find.text('Group Namjap'), findsOneWidget);

    // Verify AppBar Icons
    expect(find.byType(ThemedIcon), findsAtLeastNWidgets(2));
  });
}

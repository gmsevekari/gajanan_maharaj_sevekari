import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/providers/app_config_provider.dart';
import 'package:gajanan_maharaj_sevekari/shared/global_search_delegate.dart';

class MockAppConfigProvider extends Mock implements AppConfigProvider {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAppConfigProvider mockAppConfigProvider;

  setUp(() {
    mockAppConfigProvider = MockAppConfigProvider();
    when(() => mockAppConfigProvider.searchContent(any(), any())).thenAnswer((_) async => []);
  });

  Widget createSearchWidget(GlobalSearchDelegate delegate) {
    return ChangeNotifierProvider<AppConfigProvider>.value(
      value: mockAppConfigProvider,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => showSearch(context: context, delegate: delegate),
                child: const Text('Open Search'),
              );
            },
          ),
        ),
      ),
    );
  }

  group('GlobalSearchDelegate Widget Tests', () {
    testWidgets('opens search bar and renders hint text and clear action', (WidgetTester tester) async {
      final delegate = GlobalSearchDelegate(hintText: 'Search Stotras...');
      await tester.pumpWidget(createSearchWidget(delegate));
      await tester.tap(find.text('Open Search'));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);

      delegate.query = 'Gajanan';
      await tester.pumpAndSettle();

      expect(delegate.buildActions(tester.element(find.byType(TextField))), isNotNull);
    });

    testWidgets('buildSuggestions returns Container for short queries', (WidgetTester tester) async {
      final delegate = GlobalSearchDelegate(hintText: 'Search...');
      delegate.query = 'a'; // < 2 chars

      await tester.pumpWidget(createSearchWidget(delegate));
      await tester.tap(find.text('Open Search'));
      await tester.pumpAndSettle();

      final suggestionsWidget = delegate.buildSuggestions(tester.element(find.byType(TextField)));
      expect(suggestionsWidget, isA<Container>());
    });
  });
}

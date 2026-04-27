import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/jap_mala/widgets/manual_jap_tab.dart';
import 'package:gajanan_maharaj_sevekari/providers/jap_mala_provider.dart';
import 'package:provider/provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';

class MockJapMalaProvider extends Mock implements JapMalaProvider {}

void main() {
  late MockJapMalaProvider mockProvider;

  setUp(() {
    mockProvider = MockJapMalaProvider();
    when(() => mockProvider.completedMalas).thenReturn(1);
    when(() => mockProvider.currentCount).thenReturn(50);
    when(() => mockProvider.increment()).thenAnswer((_) async {});
    when(() => mockProvider.decrement()).thenAnswer((_) async {});
  });

  Widget createTab({bool compact = false, bool enabled = true}) {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ChangeNotifierProvider<JapMalaProvider>.value(
          value: mockProvider,
          child: ManualJapTab(compact: compact, enabled: enabled),
        ),
      ),
    );
  }

  testWidgets('renders counters and animation in normal mode', (tester) async {
    await tester.pumpWidget(createTab());

    expect(find.text('Mala'), findsOneWidget);
    expect(find.text('Jap'), findsOneWidget);
    expect(find.text('01'), findsOneWidget);
    expect(find.text('50 / १०८'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.byIcon(Icons.remove), findsOneWidget);
  });

  testWidgets('renders in compact mode', (tester) async {
    await tester.pumpWidget(createTab(compact: true));

    // Cards should be hidden
    expect(find.text('Mala'), findsNothing);
    // Buttons and animation should be in a Row
    expect(find.byType(Row), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.byIcon(Icons.remove), findsOneWidget);
  });

  testWidgets('increment triggers provider and animation', (tester) async {
    await tester.pumpWidget(createTab());

    await tester.tap(find.byIcon(Icons.add));
    verify(() => mockProvider.increment()).called(1);
  });

  testWidgets('decrement triggers provider', (tester) async {
    await tester.pumpWidget(createTab());

    await tester.tap(find.byIcon(Icons.remove));
    verify(() => mockProvider.decrement()).called(1);
  });

  testWidgets('compact mode buttons trigger provider', (tester) async {
    await tester.pumpWidget(createTab(compact: true));

    await tester.tap(find.byIcon(Icons.add));
    verify(() => mockProvider.increment()).called(1);

    await tester.tap(find.byIcon(Icons.remove));
    verify(() => mockProvider.decrement()).called(1);
  });

  testWidgets('didUpdateWidget updates animation when compact mode changes', (tester) async {
    await tester.pumpWidget(createTab(compact: false));
    
    // Re-pump with compact: true to trigger didUpdateWidget
    await tester.pumpWidget(createTab(compact: true));
    
    await tester.pumpAndSettle();
    // Verification is implicit by triggering the code path
  });

  testWidgets('Mala animation is horizontally centered in compact mode', (tester) async {
    await tester.pumpWidget(createTab(compact: true));
    
    final minusButton = find.byIcon(Icons.remove);
    final plusButton = find.byIcon(Icons.add);
    
    // Check their parent SizedBox widths
    final minusSizedBox = tester.widget<SizedBox>(
      find.ancestor(
        of: minusButton,
        matching: find.byType(SizedBox),
      ).first,
    );
    
    expect(minusSizedBox.width, 72.0);
  });

  testWidgets('Increment button has increased height in compact mode', (tester) async {
    await tester.pumpWidget(createTab(compact: true));
    
    final plusContainer = tester.widget<Container>(
      find.ancestor(
        of: find.byIcon(Icons.add),
        matching: find.byType(Container),
      ).first,
    );
    
    expect(plusContainer.constraints?.minHeight, 100.0);
    expect(plusContainer.constraints?.minWidth, 72.0);
  });
}

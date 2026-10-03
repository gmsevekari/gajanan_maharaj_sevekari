import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/widgets/fitted_app_bar_title.dart';

void main() {
  Widget wrap(String title, {List<Widget> actions = const []}) => MaterialApp(
    theme: AppTheme.lightTheme,
    home: Scaffold(
      appBar: AppBar(title: FittedAppBarTitle(title), actions: actions),
    ),
  );

  testWidgets('renders the title in the app bar colors', (tester) async {
    await tester.pumpWidget(wrap('Slots'));

    final text = tester.widget<Text>(find.text('Slots'));
    final theme = Theme.of(tester.element(find.text('Slots')));
    expect(text.style?.color, theme.colorScheme.onPrimary);
    expect(text.style?.fontWeight, FontWeight.bold);
  });

  testWidgets('scales a long title down to fit instead of cutting it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      wrap(
        'Rakhumai Navaratri Saree Seva 2026 - Seattle Temple Community',
        actions: [
          IconButton(icon: const Icon(Icons.home), onPressed: () {}),
          IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
        ],
      ),
    );

    final box = tester.getRect(find.byType(FittedAppBarTitle));
    final text = tester.getRect(find.byType(Text));
    expect(tester.takeException(), isNull);
    expect(text.width, lessThanOrEqualTo(box.width + 0.01));
    expect(text.left, greaterThanOrEqualTo(box.left - 0.01));
  });

  testWidgets('keeps a short title at its natural size', (tester) async {
    await tester.pumpWidget(wrap('Slots'));

    final fitted = tester.widget<FittedBox>(find.byType(FittedBox));
    expect(fitted.fit, BoxFit.scaleDown);
    expect(fitted.alignment, Alignment.centerLeft);
  });
}

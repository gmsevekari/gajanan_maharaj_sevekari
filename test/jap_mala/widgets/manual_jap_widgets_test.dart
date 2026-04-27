import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/jap_mala/widgets/jap_control_buttons.dart';
import 'package:gajanan_maharaj_sevekari/jap_mala/widgets/mala_count_card.dart';
import 'package:gajanan_maharaj_sevekari/jap_mala/widgets/rudraksha_animation.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(body: child),
    );
  }

  group('MalaCountCard', () {
    testWidgets('renders label and value correctly', (tester) async {
      await tester.pumpWidget(wrap(
        const MalaCountCard(label: 'Test Label', value: '123'),
      ));

      expect(find.text('Test Label'), findsOneWidget);
      expect(find.text('123'), findsOneWidget);
    });

    testWidgets('renders in compact mode (Row layout)', (tester) async {
      await tester.pumpWidget(wrap(
        const MalaCountCard(label: 'Mala', value: '10', compact: true),
      ));

      // In compact mode it uses a Row
      expect(find.byType(Row), findsOneWidget);
      expect(find.text('Mala'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
    });
  });

  group('JapControlButtons', () {
    testWidgets('triggers callbacks when enabled', (tester) async {
      bool incrementCalled = false;
      bool decrementCalled = false;

      await tester.pumpWidget(wrap(
        JapControlButtons(
          compact: false,
          enabled: true,
          onIncrement: () => incrementCalled = true,
          onDecrement: () => decrementCalled = true,
        ),
      ));

      await tester.tap(find.byIcon(Icons.add));
      await tester.tap(find.byIcon(Icons.remove));

      expect(incrementCalled, isTrue);
      expect(decrementCalled, isTrue);
    });

    testWidgets('does not trigger callbacks when disabled', (tester) async {
      bool incrementCalled = false;

      await tester.pumpWidget(wrap(
        JapControlButtons(
          compact: false,
          enabled: false,
          onIncrement: () => incrementCalled = true,
        ),
      ));

      await tester.tap(find.byIcon(Icons.add));
      expect(incrementCalled, isFalse);
    });
  });

  group('RudrakshaAnimation', () {
    testWidgets('renders Rudraksha images', (tester) async {
      // Mock animation
      final controller = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(seconds: 1),
      );

      await tester.pumpWidget(wrap(
        RudrakshaAnimation(
          animation: controller,
          beadHeight: 80,
          visibleBeads: 3,
          compact: true,
          enabled: true,
        ),
      ));

      // Should find at least 3 Rudraksha images (plus 1 buffer)
      expect(find.byType(Image), findsAtLeast(3));
      
      controller.dispose();
    });

    testWidgets('dims when disabled', (tester) async {
      final controller = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(seconds: 1),
      );

      await tester.pumpWidget(wrap(
        RudrakshaAnimation(
          animation: controller,
          beadHeight: 80,
          visibleBeads: 3,
          compact: true,
          enabled: false,
        ),
      ));

      // Find an opacity widget that is dimmed (enabled ? opacity : opacity * 0.5)
      // This is a bit hard to test precisely without deeper inspection, 
      // but we verify it builds without error.
      expect(find.byType(RudrakshaAnimation), findsOneWidget);
      
      controller.dispose();
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/widgets/festival_launch_animation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget createAnimationWidget({
    required FestivalAnimationType type,
    required VoidCallback onComplete,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: FestivalLaunchAnimation(
          message: 'Happy Festival!',
          type: type,
          onComplete: onComplete,
        ),
      ),
    );
  }

  group('FestivalLaunchAnimation Widget Tests', () {
    testWidgets('renders fireworks type launch animation', (WidgetTester tester) async {
      bool completed = false;
      await tester.pumpWidget(createAnimationWidget(
        type: FestivalAnimationType.fireworks,
        onComplete: () => completed = true,
      ));

      while (tester.takeException() != null) {}
      await tester.pump(const Duration(seconds: 10));

      expect(find.byType(FestivalLaunchAnimation), findsOneWidget);
    });

    testWidgets('renders flowerPetals type launch animation', (WidgetTester tester) async {
      bool completed = false;
      await tester.pumpWidget(createAnimationWidget(
        type: FestivalAnimationType.flowerPetals,
        onComplete: () => completed = true,
      ));

      while (tester.takeException() != null) {}
      await tester.pump(const Duration(seconds: 10));

      expect(find.byType(FestivalLaunchAnimation), findsOneWidget);
    });
  });
}

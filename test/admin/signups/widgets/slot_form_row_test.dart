import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/widgets/slot_form_row.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/utils/slot_schedule.dart';

void main() {
  late TextEditingController labelEn;
  late TextEditingController labelMr;
  late TextEditingController capacity;
  late TextEditingController amount;
  final formKey = GlobalKey<FormState>();

  setUp(() {
    labelEn = TextEditingController(text: 'Week 1');
    labelMr = TextEditingController();
    capacity = TextEditingController(text: '5');
    amount = TextEditingController();
  });

  tearDown(() {
    labelEn.dispose();
    labelMr.dispose();
    capacity.dispose();
    amount.dispose();
  });

  Future<void> show(
    WidgetTester tester, {
    bool showHeader = true,
    int? minCapacity,
    VoidCallback? onRemove,
    VoidCallback? onMoveUp,
    VoidCallback? onMoveDown,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: SlotFormRow(
              index: 0,
              labelEnController: labelEn,
              labelMrController: labelMr,
              capacityController: capacity,
              suggestedAmountController: amount,
              schedule: SlotScheduleInput(startDate: DateTime(2030, 7, 3)),
              onScheduleChanged: (_) {},
              showHeader: showHeader,
              minCapacity: minCapacity,
              onRemove: onRemove,
              onMoveUp: onMoveUp,
              onMoveDown: onMoveDown,
            ),
          ),
        ),
      ),
    ),
  );

  group('header', () {
    testWidgets('shows the slot number and the move and remove buttons by '
        'default', (tester) async {
      await show(tester, onRemove: () {}, onMoveUp: () {}, onMoveDown: () {});

      expect(find.text('Slot 1'), findsOneWidget);
      expect(find.byTooltip('Remove slot'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
    });

    testWidgets('leaves the whole header out when showHeader is false', (
      tester,
    ) async {
      await show(tester, showHeader: false);

      expect(find.text('Slot 1'), findsNothing);
      expect(find.byType(IconButton), findsNothing);
      // The fields are still there.
      expect(find.byKey(const Key('slotLabelEn_0')), findsOneWidget);
      expect(find.byKey(const Key('slotCapacity_0')), findsOneWidget);
    });

    testWidgets('disables a button that has no callback', (tester) async {
      await show(tester, onRemove: () {});

      final up = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.arrow_upward),
      );
      expect(up.onPressed, isNull);
    });
  });

  group('capacity', () {
    Future<void> enter(WidgetTester tester, String value) async {
      await tester.enterText(find.byKey(const Key('slotCapacity_0')), value);
      formKey.currentState!.validate();
      await tester.pump();
    }

    testWidgets('needs a number', (tester) async {
      await show(tester);

      await enter(tester, '');

      expect(find.text('Please enter a capacity'), findsOneWidget);
    });

    testWidgets('must be positive', (tester) async {
      await show(tester);

      for (final bad in ['0', '-2', 'abc', '1.5']) {
        await enter(tester, bad);
        expect(
          find.text('Capacity must be a positive number'),
          findsOneWidget,
          reason: bad,
        );
      }
    });

    testWidgets('has no other lower limit when no minimum is given', (
      tester,
    ) async {
      await show(tester);

      await enter(tester, '1');

      expect(find.text('Capacity must be a positive number'), findsNothing);
      expect(find.textContaining('already signed up'), findsNothing);
    });

    testWidgets('cannot be below the minimum, and says how many have signed '
        'up', (tester) async {
      await show(tester, minCapacity: 3);

      await enter(tester, '2');

      expect(
        find.text("Capacity can't be less than the 3 already signed up"),
        findsOneWidget,
      );
    });

    testWidgets('may equal or exceed the minimum', (tester) async {
      await show(tester, minCapacity: 3);

      for (final ok in ['3', '4', '100']) {
        await enter(tester, ok);
        expect(
          find.textContaining('already signed up'),
          findsNothing,
          reason: ok,
        );
      }
    });

    testWidgets('still rejects zero and text when there is a minimum', (
      tester,
    ) async {
      await show(tester, minCapacity: 3);

      await enter(tester, '0');
      expect(find.text('Capacity must be a positive number'), findsOneWidget);

      await enter(tester, 'abc');
      expect(find.text('Capacity must be a positive number'), findsOneWidget);
    });

    testWidgets('a minimum of 0 or 1 adds nothing to the basic rule', (
      tester,
    ) async {
      for (final min in [0, 1]) {
        await show(tester, minCapacity: min);
        await enter(tester, '1');
        expect(find.textContaining('already signed up'), findsNothing);
      }
    });
  });
}

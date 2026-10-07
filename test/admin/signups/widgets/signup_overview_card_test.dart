import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/widgets/signup_overview_card.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }

  SignupOverviewCard card({
    String title = 'Sunday Prasad Seva',
    String groupName = '',
    SignupStatus status = SignupStatus.draft,
    String? joinCode,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) => SignupOverviewCard(
    title: title,
    groupName: groupName,
    status: status,
    joinCode: joinCode,
    onEdit: onEdit ?? () {},
    onDelete: onDelete ?? () {},
  );

  testWidgets('renders the title', (tester) async {
    await tester.pumpWidget(wrap(card()));

    expect(find.text('Sunday Prasad Seva'), findsOneWidget);
  });

  testWidgets('shows a group chip when groupName is non-empty', (tester) async {
    await tester.pumpWidget(wrap(card(groupName: 'Seattle')));

    expect(find.text('Seattle'), findsOneWidget);
  });

  testWidgets('omits the group chip when groupName is empty', (tester) async {
    await tester.pumpWidget(wrap(card()));

    // The status chip is the only chip.
    expect(find.byType(Chip), findsOneWidget);
  });

  testWidgets('shows the status of the signup', (tester) async {
    for (final entry in {
      SignupStatus.draft: 'Draft',
      SignupStatus.published: 'Published',
      SignupStatus.closed: 'Closed',
    }.entries) {
      await tester.pumpWidget(wrap(card(status: entry.key)));
      expect(find.text(entry.value), findsOneWidget, reason: entry.value);
    }
  });

  testWidgets('shows the join code when one is required', (tester) async {
    await tester.pumpWidget(wrap(card(joinCode: 'ABC123')));

    expect(find.text('ABC123'), findsOneWidget);
    expect(find.byTooltip('Copy Join Code'), findsOneWidget);
  });

  testWidgets('shows no join code when none is required', (tester) async {
    await tester.pumpWidget(wrap(card()));

    expect(find.byIcon(Icons.key), findsNothing);
    expect(find.byTooltip('Copy Join Code'), findsNothing);
  });

  testWidgets('copies the join code when the copy button is tapped', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(card(joinCode: 'ABC123')));

    await tester.tap(find.byTooltip('Copy Join Code'));
    await tester.pumpAndSettle();

    expect(find.text('Join Code copied to clipboard'), findsOneWidget);
  });

  testWidgets('has no description', (tester) async {
    await tester.pumpWidget(wrap(card()));

    // Title is the only body text besides the status chip and the buttons.
    final texts = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .toList();
    expect(texts, ['Sunday Prasad Seva', 'Draft', 'Delete', 'Edit']);
  });

  group('edit button', () {
    testWidgets('is labelled Edit', (tester) async {
      await tester.pumpWidget(wrap(card()));

      expect(find.text('Edit'), findsOneWidget);
    });

    testWidgets('calls onEdit when tapped', (tester) async {
      var edits = 0;
      await tester.pumpWidget(wrap(card(onEdit: () => edits++)));

      await tester.tap(find.text('Edit'));
      await tester.pump();

      expect(edits, 1);
    });

    testWidgets('sits on the status row, level with the status chip', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(card(status: SignupStatus.published)));

      final chip = tester.getRect(find.text('Published'));
      final edit = tester.getRect(find.text('Edit'));
      expect(edit.left, greaterThan(chip.right));
      expect((edit.center.dy - chip.center.dy).abs(), lessThan(8));
    });

    testWidgets('does not crowd a long title, group and join code at 360px '
        'and large text', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      // In a scroll view, as on the detail page: the wide test font makes the
      // wrapped title taller than the screen.
      await tester.pumpWidget(
        wrap(
          SingleChildScrollView(
            child: card(
              title: 'A very long sign up title that has to wrap on a phone',
              groupName: 'Gajanan Maharaj Seattle',
              status: SignupStatus.published,
              joinCode: 'ABC123',
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      final cardRect = tester.getRect(find.byType(Card));
      for (final label in ['Edit', 'Delete']) {
        final rect = tester.getRect(find.text(label));
        expect(
          rect.left,
          greaterThanOrEqualTo(cardRect.left + 16),
          reason: label,
        );
        expect(
          rect.right,
          lessThanOrEqualTo(cardRect.right - 16),
          reason: label,
        );
      }
    });
  });

  group('delete button', () {
    testWidgets('is labelled Delete', (tester) async {
      await tester.pumpWidget(wrap(card()));

      expect(find.byKey(const Key('deleteSignupButton')), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('calls onDelete, and only onDelete, when tapped', (
      tester,
    ) async {
      var deletes = 0;
      var edits = 0;
      await tester.pumpWidget(
        wrap(card(onDelete: () => deletes++, onEdit: () => edits++)),
      );

      await tester.tap(find.byKey(const Key('deleteSignupButton')));
      await tester.pump();

      expect(deletes, 1);
      expect(edits, 0);
    });

    testWidgets('sits next to Edit on the status row', (tester) async {
      await tester.pumpWidget(wrap(card(status: SignupStatus.published)));

      final chip = tester.getRect(find.text('Published'));
      final delete = tester.getRect(find.text('Delete'));
      final edit = tester.getRect(find.text('Edit'));
      expect(delete.left, greaterThan(chip.right));
      expect(edit.left, greaterThan(delete.right));
      expect((delete.center.dy - edit.center.dy).abs(), lessThan(2));
      expect((delete.center.dy - chip.center.dy).abs(), lessThan(8));
    });

    testWidgets('leaves a gap between Delete and Edit against a mis-tap', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(card()));

      final delete = tester.getRect(
        find.byKey(const Key('deleteSignupButton')),
      );
      final edit = tester.getRect(
        find.ancestor(of: find.text('Edit'), matching: find.byType(TextButton)),
      );
      expect(edit.left - delete.right, greaterThanOrEqualTo(4));
    });

    testWidgets('keeps Edit at the right edge of the card', (tester) async {
      await tester.pumpWidget(wrap(card(status: SignupStatus.published)));

      final cardRect = tester.getRect(find.byType(Card));
      final edit = tester.getRect(find.text('Edit'));
      // Only the card's padding and the button's own padding are to its right.
      expect(cardRect.right - edit.right, lessThan(40));
    });

    testWidgets('is drawn in the error colour so it reads as destructive', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(card()));

      final context = tester.element(find.text('Delete'));
      final style = tester
          .widget<TextButton>(find.byKey(const Key('deleteSignupButton')))
          .style!;
      expect(
        style.foregroundColor!.resolve({}),
        Theme.of(context).colorScheme.error,
      );
    });

    testWidgets('wraps below the status instead of overflowing at 320px and '
        'large text', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(
        wrap(
          SingleChildScrollView(
            child: card(status: SignupStatus.published, joinCode: 'ABC123'),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      final chip = tester.getRect(find.text('Published'));
      final delete = tester.getRect(find.text('Delete'));
      final edit = tester.getRect(find.text('Edit'));
      final cardRect = tester.getRect(find.byType(Card));
      // They really did drop below the status (a Wrap never overflows, so
      // this is what shows the layout adapted) ...
      expect(delete.top, greaterThan(chip.bottom));
      expect(edit.top, greaterThan(chip.bottom));
      // ... and stay inside the card's padding.
      for (final rect in [delete, edit]) {
        expect(rect.left, greaterThanOrEqualTo(cardRect.left + 16));
        expect(rect.right, lessThanOrEqualTo(cardRect.right - 16));
      }
    });
  });
}

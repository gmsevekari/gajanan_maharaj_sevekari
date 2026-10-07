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
  }) => SignupOverviewCard(
    title: title,
    groupName: groupName,
    status: status,
    joinCode: joinCode,
    onEdit: onEdit ?? () {},
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

    // Title is the only body text besides the status chip and Edit.
    final texts = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .toList();
    expect(texts, ['Sunday Prasad Seva', 'Draft', 'Edit']);
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
      expect(tester.getRect(find.text('Edit')).right, lessThanOrEqualTo(360));
    });
  });
}

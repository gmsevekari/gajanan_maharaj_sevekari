import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/widgets/signup_overview_card.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(body: child),
    );
  }

  testWidgets('renders the title and description', (tester) async {
    await tester.pumpWidget(
      wrap(
        const SignupOverviewCard(
          title: 'Sunday Prasad Seva',
          description: 'Cook and serve prasad',
          groupName: '',
        ),
      ),
    );

    expect(find.text('Sunday Prasad Seva'), findsOneWidget);
    expect(find.text('Cook and serve prasad'), findsOneWidget);
  });

  testWidgets('hides the description text when it is empty', (tester) async {
    await tester.pumpWidget(
      wrap(
        const SignupOverviewCard(
          title: 'Sunday Prasad Seva',
          description: '',
          groupName: '',
        ),
      ),
    );

    expect(find.text('Sunday Prasad Seva'), findsOneWidget);
    expect(find.byType(Chip), findsNothing);
  });

  testWidgets('shows a group chip when groupName is non-empty', (tester) async {
    await tester.pumpWidget(
      wrap(
        const SignupOverviewCard(
          title: 'Sunday Prasad Seva',
          description: '',
          groupName: 'Seattle',
        ),
      ),
    );

    expect(find.byType(Chip), findsOneWidget);
    expect(find.text('Seattle'), findsOneWidget);
  });
}

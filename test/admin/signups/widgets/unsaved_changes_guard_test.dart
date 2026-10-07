import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/widgets/unsaved_changes_guard.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';

void main() {
  bool hasChanges = false;
  bool busy = false;

  setUp(() {
    hasChanges = false;
    busy = false;
  });

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => StatefulBuilder(
                      builder: (context, setState) => UnsavedChangesGuard(
                        hasUnsavedChanges: hasChanges,
                        busy: busy,
                        child: Scaffold(
                          appBar: AppBar(title: const Text('Editor')),
                          body: Column(
                            children: [
                              TextButton(
                                onPressed: () =>
                                    setState(() => hasChanges = true),
                                child: const Text('Change'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    setState(() => hasChanges = false),
                                child: const Text('Undo'),
                              ),
                              TextButton(
                                onPressed: () => setState(() => busy = true),
                                child: const Text('Start'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('lets the user straight back when nothing changed', (
    tester,
  ) async {
    await open(tester);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Editor'), findsNothing);
    expect(find.text('Discard changes?'), findsNothing);
  });

  testWidgets('asks first when there are unsaved changes', (tester) async {
    await open(tester);
    await tester.tap(find.text('Change'));
    await tester.pump();

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Discard changes?'), findsOneWidget);
    expect(find.text("Your changes haven't been saved."), findsOneWidget);
    expect(find.text('Editor'), findsOneWidget);
  });

  testWidgets('stays when the user chooses Keep Editing', (tester) async {
    await open(tester);
    await tester.tap(find.text('Change'));
    await tester.pump();
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Keep Editing'));
    await tester.pumpAndSettle();

    expect(find.text('Editor'), findsOneWidget);
    expect(find.text('Discard changes?'), findsNothing);
  });

  testWidgets('leaves when the user chooses Discard', (tester) async {
    await open(tester);
    await tester.tap(find.text('Change'));
    await tester.pump();
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();

    expect(find.text('Editor'), findsNothing);
  });

  testWidgets('stops asking once the changes are undone', (tester) async {
    await open(tester);
    await tester.tap(find.text('Change'));
    await tester.pump();
    await tester.tap(find.text('Undo'));
    await tester.pump();

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Discard changes?'), findsNothing);
    expect(find.text('Editor'), findsNothing);
  });

  testWidgets('neither leaves nor asks while busy', (tester) async {
    await open(tester);
    await tester.tap(find.text('Change'));
    await tester.tap(find.text('Start'));
    await tester.pump();

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Editor'), findsOneWidget);
    expect(find.text('Discard changes?'), findsNothing);
  });

  testWidgets('does not leave while busy even with nothing changed', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.text('Start'));
    await tester.pump();

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Editor'), findsOneWidget);
  });
}

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/widgets/signup_entries_export_card.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_entry.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';
import 'package:gajanan_maharaj_sevekari/signups/widgets/signup_entries_table.dart';
import 'package:gajanan_maharaj_sevekari/widgets/english_only.dart';
import 'package:screenshot/screenshot.dart';

void main() {
  final now = DateTime.utc(2026, 10, 6, 12);

  final slotA = SignupSlot(
    id: 'a',
    labelEn: 'Morning Seva',
    labelMr: 'सकाळची सेवा',
    startAt: DateTime.utc(2026, 10, 10, 16),
    endAt: DateTime.utc(2026, 10, 10, 18),
    timezone: 'America/Los_Angeles',
    capacity: 5,
    claimedCount: 2,
    sortOrder: 0,
    createdAt: now,
  );
  final slotB = SignupSlot(
    id: 'b',
    labelEn: 'Evening Seva',
    labelMr: '',
    startAt: DateTime.utc(2026, 10, 12, 2),
    endAt: DateTime.utc(2026, 10, 12, 4),
    timezone: 'America/Los_Angeles',
    capacity: 5,
    claimedCount: 1,
    sortOrder: 1,
    createdAt: now,
  );

  SignupEntry entry(String slotId, String name, {String? phone}) => SignupEntry(
    id: '$slotId$name',
    slotId: slotId,
    name: name,
    phone: phone,
    email: '$name@example.com',
    pledgeAmount: 25,
    note: 'Will bring flowers',
    joinedAt: now,
  );

  Widget wrap(Widget child) => MaterialApp(
    theme: AppTheme.lightTheme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );

  SignupEntriesExportCard card({
    String title = 'Sunday Prasad Seva',
    String groupName = 'Seattle',
    List<SignupEntry>? entries,
    List<SignupSlot>? slots,
    int part = 1,
    int totalParts = 1,
  }) => SignupEntriesExportCard(
    title: title,
    groupName: groupName,
    entries: entries ?? [entry('a', 'Asha'), entry('b', 'Bhau')],
    slots: slots ?? [slotA, slotB],
    part: part,
    totalParts: totalParts,
  );

  testWidgets('shows the title, group, tagline and the entries table', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(card()));

    expect(find.text('Sunday Prasad Seva'), findsOneWidget);
    expect(find.text('Seattle'), findsOneWidget);
    expect(find.text('Entries'), findsOneWidget);
    expect(
      find.text('|| Anant Koti Brahmandanayak Gajanan Maharaj Ki Jai ||'),
      findsOneWidget,
    );
    expect(find.byType(SignupEntriesTable), findsOneWidget);
    expect(find.text('Asha'), findsOneWidget);
    expect(find.text('Bhau'), findsOneWidget);
    expect(find.text('Morning Seva'), findsOneWidget);
    expect(find.textContaining('October 10'), findsOneWidget);
  });

  testWidgets('leaves out the group line when there is no group', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(card(groupName: '')));

    expect(find.text('Seattle'), findsNothing);
    expect(find.text(''), findsNothing); // no blank line left in its place
    expect(find.text('Sunday Prasad Seva'), findsOneWidget);
  });

  testWidgets('says which part it is when the export has several images', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(card(part: 2, totalParts: 3)));

    expect(find.text('Entries - Part 2 of 3'), findsOneWidget);
  });

  testWidgets('does not number a single image', (tester) async {
    await tester.pumpWidget(wrap(card()));

    expect(find.textContaining('Part'), findsNothing);
  });

  testWidgets('never shows contact, pledge or note details', (tester) async {
    await tester.pumpWidget(
      wrap(card(entries: [entry('a', 'Asha', phone: '12065550100')])),
    );

    expect(find.textContaining('12065550100'), findsNothing);
    expect(find.textContaining('example.com'), findsNothing);
    expect(find.textContaining('25'), findsNothing);
    expect(find.textContaining('flowers'), findsNothing);
  });

  testWidgets('is a fixed width, so the image is the same on every phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(wrap(Center(child: card())));

    expect(
      tester.getSize(find.byType(SignupEntriesExportCard)).width,
      SignupEntriesExportCard.cardWidth,
    );
  });

  group('scoped', () {
    /// A context from a real app, whose theme and language the card must
    /// carry into a tree that has neither.
    Future<BuildContext> appContext(
      WidgetTester tester, {
      Locale locale = const Locale('en'),
      double textScale = 1,
      bool englishOnly = true,
    }) async {
      late BuildContext captured;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: const MediaQueryData().copyWith(
              textScaler: TextScaler.linear(textScale),
            ),
            child: englishOnly
                ? EnglishOnly(
                    builder: (context) {
                      captured = context;
                      return const SizedBox();
                    },
                  )
                : Builder(
                    builder: (context) {
                      captured = context;
                      return const SizedBox();
                    },
                  ),
          ),
        ),
      );
      return captured;
    }

    /// What the screenshot package builds: a bare tree with only a text
    /// direction above the widget.
    Widget bare(Widget child) =>
        Directionality(textDirection: TextDirection.ltr, child: child);

    testWidgets('renders outside the app, with its own theme and words', (
      tester,
    ) async {
      final context = await appContext(tester);
      final scoped = SignupEntriesExportCard.scoped(context, card());

      await tester.pumpWidget(bare(scoped));

      expect(tester.takeException(), isNull);
      expect(find.text('Entries'), findsOneWidget);
      expect(find.text('Asha'), findsOneWidget);
      expect(find.text('Name'), findsOneWidget);
    });

    testWidgets('keeps the content language of the app', (tester) async {
      final context = await appContext(tester, locale: const Locale('mr'));
      final scoped = SignupEntriesExportCard.scoped(context, card());

      await tester.pumpWidget(bare(scoped));

      expect(find.text('सकाळची सेवा'), findsOneWidget);
      expect(find.text('Morning Seva'), findsNothing);
      // The column headings stay English.
      expect(find.text('Name'), findsOneWidget);
    });

    testWidgets('forces English words even from a context that is not already '
        'English-only', (tester) async {
      final context = await appContext(
        tester,
        locale: const Locale('mr'),
        englishOnly: false,
      );

      await tester.pumpWidget(
        bare(SignupEntriesExportCard.scoped(context, card())),
      );

      expect(find.text('Name'), findsOneWidget);
      expect(find.text('नाव'), findsNothing);
      expect(find.text('Entries'), findsOneWidget);
    });

    testWidgets('ignores the admin\'s text size, so it cannot be cut off', (
      tester,
    ) async {
      final normal = await appContext(tester);
      await tester.pumpWidget(
        bare(SignupEntriesExportCard.scoped(normal, card())),
      );
      final normalHeight = tester.getSize(find.byType(SignupEntriesExportCard));

      final large = await appContext(tester, textScale: 2);
      await tester.pumpWidget(
        bare(SignupEntriesExportCard.scoped(large, card())),
      );
      final largeHeight = tester.getSize(find.byType(SignupEntriesExportCard));

      expect(largeHeight, normalHeight);
    });

    /// The pixel size of the PNG the screenshot package really makes from the
    /// card, the way the sign-ups export makes it.
    Future<({int width, int height})> capturedSize(
      WidgetTester tester,
      BuildContext context, {
      double pixelRatio = 2,
    }) async {
      final bytes = await tester.runAsync(
        () => ScreenshotController().captureFromLongWidget(
          SignupEntriesExportCard.scoped(context, card()),
          context: context,
          pixelRatio: pixelRatio,
          delay: Duration.zero,
        ),
      );
      // A PNG's width and height are the two big-endian ints after "IHDR".
      final header = ByteData.sublistView(Uint8List.fromList(bytes!));
      return (width: header.getUint32(16), height: header.getUint32(20));
    }

    testWidgets('really renders to a PNG exactly the card\'s width', (
      tester,
    ) async {
      final context = await appContext(tester);

      final size = await capturedSize(tester, context);

      expect(size.width, SignupEntriesExportCard.cardWidth * 2);
      expect(size.height, greaterThan(100));
    });

    testWidgets('really renders the same size however large the admin\'s '
        'text is', (tester) async {
      final normal = await capturedSize(tester, await appContext(tester));
      final large = await capturedSize(
        tester,
        await appContext(tester, textScale: 2),
      );

      expect(large, normal);
    });

    testWidgets('really renders at the pixel ratio it is asked for', (
      tester,
    ) async {
      final context = await appContext(tester);

      final sharp = await capturedSize(tester, context);
      final plain = await capturedSize(tester, context, pixelRatio: 1);

      expect(sharp.width, plain.width * 2);
      expect(sharp.height, plain.height * 2);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/widgets/signup_header_image_card.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }

  testWidgets('shows Add Image and no preview when there is no image', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        SignupHeaderImageCard(
          headerImageUrl: null,
          isUploading: false,
          onPickImage: () {},
          onRemoveImage: null,
        ),
      ),
    );

    expect(find.text('Add Image'), findsOneWidget);
    expect(find.text('Replace Image'), findsNothing);
    expect(find.text('Remove Image'), findsNothing);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('shows a preview and Replace/Remove when there is an image', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        SignupHeaderImageCard(
          headerImageUrl: 'https://example.com/header.jpg',
          isUploading: false,
          onPickImage: () {},
          onRemoveImage: () {},
        ),
      ),
    );
    // Image.network makes a real HTTP request with no network access in
    // the test environment; harmless for this test, which only checks
    // button state, not decoded pixels.
    tester.takeException();

    expect(find.text('Replace Image'), findsOneWidget);
    expect(find.text('Remove Image'), findsOneWidget);
    expect(find.text('Add Image'), findsNothing);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('shows an uploading indicator and hides the buttons', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        SignupHeaderImageCard(
          headerImageUrl: null,
          isUploading: true,
          onPickImage: () {},
          onRemoveImage: null,
        ),
      ),
    );

    expect(find.text('Please wait...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Add Image'), findsNothing);
  });

  testWidgets('invokes onPickImage when the add button is tapped', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      wrap(
        SignupHeaderImageCard(
          headerImageUrl: null,
          isUploading: false,
          onPickImage: () => tapped = true,
          onRemoveImage: null,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('addOrReplaceHeaderImageButton')));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('invokes onRemoveImage when the remove button is tapped', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      wrap(
        SignupHeaderImageCard(
          headerImageUrl: 'https://example.com/header.jpg',
          isUploading: false,
          onPickImage: () {},
          onRemoveImage: () => tapped = true,
        ),
      ),
    );
    tester.takeException();

    await tester.tap(find.byKey(const Key('removeHeaderImageButton')));
    await tester.pump();

    expect(tapped, isTrue);
  });
}

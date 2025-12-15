// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/main.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/settings/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App shows home screen smoke test', (WidgetTester tester) async {
    // STEP 1: Mock SharedPreferences for the test environment. This is required.
    SharedPreferences.setMockInitialValues({});

    // STEP 2: Create the provider and load the theme, exactly like in main.dart.
    final themeProvider = ThemeProvider();
    await themeProvider.loadTheme();

    // STEP 3: Build the app with the pre-loaded provider.
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: themeProvider,
        child: const MyApp(),
      ),
    );

    // Allow the UI to settle after all asynchronous operations.
    await tester.pumpAndSettle();

    // Verify that the home screen displays its key widgets.
    expect(find.text('Upcoming Event'), findsOneWidget);
    expect(find.text('गजानन विजय ग्रंथ'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppTheme & AppColors Comprehensive Unit Tests', () {
    test('lightTheme and darkTheme static properties return correct brightness', () {
      expect(AppTheme.lightTheme.brightness, equals(Brightness.light));
      expect(AppTheme.darkTheme.brightness, equals(Brightness.dark));
    });

    test('getTheme returns expected ThemeData for all ThemePreset values in light and dark modes', () {
      for (final preset in ThemePreset.values) {
        final lightThemeData = AppTheme.getTheme(
          preset,
          false,
          customColor: preset == ThemePreset.custom ? Colors.purple : null,
        );
        expect(lightThemeData.brightness, equals(Brightness.light));

        final darkThemeData = AppTheme.getTheme(
          preset,
          true,
          customColor: preset == ThemePreset.custom ? Colors.purple : null,
        );
        expect(darkThemeData.brightness, equals(Brightness.dark));
      }
    });

    test('getTheme handles ThemePreset.custom when customColor is null', () {
      final defaultLight = AppTheme.getTheme(ThemePreset.custom, false, customColor: null);
      expect(defaultLight, equals(AppTheme.lightTheme));

      final defaultDark = AppTheme.getTheme(ThemePreset.custom, true, customColor: null);
      expect(defaultDark, equals(AppTheme.darkTheme));
    });

    test('AppColors.copyWith returns new instance with updated properties or default copies', () {
      const colors = AppColors(
        primarySwatch: Colors.orange,
        success: Colors.green,
        warning: Colors.orange,
        error: Colors.red,
        divider: Colors.grey,
        tableHeader: Colors.grey,
        disabledBackground: Colors.grey,
        disabledText: Colors.grey,
        secondaryText: Colors.grey,
        surface: Colors.white,
        surfaceSubtle: Colors.white10,
        brandAccent: Color(0xFF9B3746),
        onPrimarySubtle: Colors.white70,
      );

      final noArgCopy = colors.copyWith();
      expect(noArgCopy.success, equals(Colors.green));

      final updated = colors.copyWith(
        primarySwatch: Colors.blue,
        success: Colors.teal,
        warning: Colors.amber,
        error: Colors.redAccent,
        divider: Colors.black12,
        tableHeader: Colors.black26,
        disabledBackground: Colors.black38,
        disabledText: Colors.black45,
        secondaryText: Colors.black54,
        surface: Colors.black,
        surfaceSubtle: Colors.black12,
        brandAccent: Color(0xFF123456),
        onPrimarySubtle: Colors.black87,
      );
      expect(updated.success, equals(Colors.teal));
      expect(updated.warning, equals(Colors.amber));
    });

    test('AppColors.lerp performs linear interpolation correctly', () {
      const colors1 = AppColors(
        primarySwatch: Colors.orange,
        success: Colors.green,
        warning: Colors.orange,
        error: Colors.red,
        divider: Colors.grey,
        tableHeader: Colors.grey,
        disabledBackground: Colors.grey,
        disabledText: Colors.grey,
        secondaryText: Colors.grey,
        surface: Colors.white,
        surfaceSubtle: Colors.white10,
        brandAccent: Color(0xFF9B3746),
        onPrimarySubtle: Colors.white70,
      );

      const colors2 = AppColors(
        primarySwatch: Colors.blue,
        success: Colors.lightGreen,
        warning: Colors.amber,
        error: Colors.redAccent,
        divider: Colors.black12,
        tableHeader: Colors.black26,
        disabledBackground: Colors.black38,
        disabledText: Colors.black45,
        secondaryText: Colors.black54,
        surface: Colors.black,
        surfaceSubtle: Colors.black12,
        brandAccent: Color(0xFF123456),
        onPrimarySubtle: Colors.black87,
      );

      final lerpNull = colors1.lerp(null, 0.5);
      expect(lerpNull, equals(colors1));

      final lerp0 = colors1.lerp(colors2, 0.0);
      expect(lerp0.primarySwatch, equals(Colors.orange));

      final lerp1 = colors1.lerp(colors2, 1.0);
      expect(lerp1.primarySwatch, equals(Colors.blue));
    });

    test('ThemeData.appColors extension returns extension or default fallback', () {
      expect(AppTheme.lightTheme.appColors, isNotNull);

      final emptyTheme = ThemeData();
      expect(emptyTheme.appColors, isNotNull);
      expect(emptyTheme.appColors.primarySwatch, equals(Colors.orange));
    });
  });
}

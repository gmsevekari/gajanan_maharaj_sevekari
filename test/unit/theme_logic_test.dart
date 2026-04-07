import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';

void main() {
  group('AppTheme & AppColors', () {
    test('getTheme should return saffron themes by default', () {
      final light = AppTheme.getTheme(ThemePreset.saffron, false);
      final dark = AppTheme.getTheme(ThemePreset.saffron, true);
      
      expect(light.colorScheme.primary, Colors.orange);
      expect(dark.colorScheme.primary, Colors.orange);
      expect(dark.brightness, Brightness.dark);
    });

    test('getTheme should return maroon theme for maroon preset', () {
      final theme = AppTheme.getTheme(ThemePreset.maroon, false);
      expect(theme.colorScheme.primary, const Color(0xFF9B3746));
    });

    test('AppColors extension should return default values if not present', () {
      final theme = ThemeData.light();
      final colors = theme.appColors;
      
      expect(colors.primarySwatch, Colors.orange);
      expect(colors.brandAccent, const Color(0xFF9B3746));
    });

    test('AppColors copyWith should update specific fields', () {
      const colors = AppColors(
        primarySwatch: Colors.blue,
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
        brandAccent: Colors.blue,
        onPrimarySubtle: Colors.white70,
      );
      
      final updated = colors.copyWith(success: Colors.teal);
      expect(updated.success, Colors.teal);
      expect(updated.primarySwatch, Colors.blue);
    });

    test('AppColors lerp should interpolate colors', () {
      const colors1 = AppColors(
        primarySwatch: Colors.blue,
        success: Colors.red,
        warning: Colors.orange,
        error: Colors.red,
        divider: Colors.grey,
        tableHeader: Colors.grey,
        disabledBackground: Colors.grey,
        disabledText: Colors.grey,
        secondaryText: Colors.grey,
        surface: Colors.white,
        surfaceSubtle: Colors.white10,
        brandAccent: Colors.blue,
        onPrimarySubtle: Colors.white70,
      );
      const colors2 = AppColors(
        primarySwatch: Colors.green,
        success: Colors.blue,
        warning: Colors.orange,
        error: Colors.red,
        divider: Colors.grey,
        tableHeader: Colors.grey,
        disabledBackground: Colors.grey,
        disabledText: Colors.grey,
        secondaryText: Colors.grey,
        surface: Colors.white,
        surfaceSubtle: Colors.white10,
        brandAccent: Colors.blue,
        onPrimarySubtle: Colors.white70,
      );
      
      final lerped = colors1.lerp(colors2, 0.5);
      expect(lerped.success, Color.lerp(Colors.red, Colors.blue, 0.5));
    });
  });
}

import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    primarySwatch: Colors.orange,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.orange,
      foregroundColor: Colors.white,
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.orange,
      primary: Colors.orange,
      secondary: Colors.amber,
      brightness: Brightness.light,
    ),
    cardTheme: CardThemeData(
      elevation: 4.0,
      color: Colors.orange[50],
      shadowColor: Colors.orange,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: Color(0xFFFF9800), width: 1),
      ),
    ),
    iconTheme: IconThemeData(color: Colors.orange[400]),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange[50],
        foregroundColor: Colors.orange[600], // Lighter text/icon color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: BorderSide(color: Color(0xFFFF9800), width: 1),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Colors.orange,
      contentTextStyle: const TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
    ),
    extensions: const <ThemeExtension<dynamic>>[
      AppColors(primarySwatch: Colors.orange),
    ],
  );

  static final ThemeData darkTheme = ThemeData(
    primarySwatch: Colors.orange,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.orange,
      foregroundColor: Colors.white,
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.orange,
      primary: Colors.orange,
      secondary: Colors.amber,
      brightness: Brightness.dark,
    ),
    cardTheme: CardThemeData(
      elevation: 4.0,
      color: const Color(0xFF0A0805),
      shadowColor: Color(0xFFE65100),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: Color(0xFFFF9800), width: 1),
      ),
    ),
    iconTheme: IconThemeData(color: Colors.orange[400]),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF0A0805),
        foregroundColor: Colors.orange[600], // Lighter text/icon color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: BorderSide(color: Color(0xFFFF9800), width: 1),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Colors.orange,
      contentTextStyle: const TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
    ),
    extensions: const <ThemeExtension<dynamic>>[
      AppColors(primarySwatch: Colors.orange),
    ],
  );
}

class AppColors extends ThemeExtension<AppColors> {
  final MaterialColor primarySwatch;

  const AppColors({required this.primarySwatch});

  @override
  AppColors copyWith({MaterialColor? primarySwatch}) {
    return AppColors(
      primarySwatch: primarySwatch ?? this.primarySwatch,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) {
      return this;
    }
    // Snap to the other swatch cleanly
    return AppColors(
      primarySwatch: t < 0.5 ? primarySwatch : other.primarySwatch,
    );
  }
}

extension AppColorsExtension on ThemeData {
  AppColors get appColors => extension<AppColors>() ?? const AppColors(primarySwatch: Colors.orange);
}

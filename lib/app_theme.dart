import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    primarySwatch: Colors.orange,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.orange,
      foregroundColor: Colors.white,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.orange,
      primary: Colors.orange,
      secondary: Colors.amber,
      brightness: Brightness.light,
    ).copyWith(surface: Colors.white),
  );

  static final ThemeData darkTheme = ThemeData(
    primarySwatch: Colors.orange,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.orange,
      foregroundColor: Colors.white,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.orange,
      primary: Colors.orange,
      secondary: Colors.amber,
      brightness: Brightness.dark,
    ),
  );
}

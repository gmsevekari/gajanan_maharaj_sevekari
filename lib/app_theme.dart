import 'package:flutter/material.dart';

enum ThemePreset {
  saffron,
  maroon,
  sandalwood,
  indigo,
  tulsi,
  kumkum,
  lotus,
  peacock,
  custom,
  diwali,
}

class AppTheme {
  // ─────────────────────────────────────────────────────────────────────────
  // ORIGINAL LIGHT THEME — DO NOT MODIFY
  // ─────────────────────────────────────────────────────────────────────────
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
      onPrimary: Colors.white,
      secondary: Colors.amber,
      surface: Colors.white,
      onSurface: Colors.black,
      onSurfaceVariant: Colors.black54,
      outline: Colors.grey[300],
      brightness: Brightness.light,
    ),
    cardTheme: CardThemeData(
      elevation: 4.0,
      color: Colors.orange[50],
      shadowColor: Colors.orange,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: const Color(0xFFFF9800), width: 1),
      ),
    ),
    iconTheme: IconThemeData(color: Colors.orange[400]),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange[50],
        foregroundColor: Colors.orange[600], // Lighter text/icon color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: const BorderSide(color: Color(0xFFFF9800), width: 1),
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
    extensions: <ThemeExtension<dynamic>>[
      AppColors(
        primarySwatch: Colors.orange,
        success: Colors.green,
        warning: Colors.orange,
        error: Colors.red,
        divider: Colors.grey.shade300,
        tableHeader: Colors.grey.shade200,
        disabledBackground: Colors.grey.shade200,
        disabledText: Colors.grey.shade400,
        secondaryText: Colors.grey.shade600,
        surface: Colors.white,
        surfaceSubtle: Colors.white10,
        brandAccent: const Color(0xFF9B3746),
        onPrimarySubtle: Colors.white70,
      ),
    ],
  );

  // ─────────────────────────────────────────────────────────────────────────
  // ORIGINAL DARK THEME — DO NOT MODIFY
  // ─────────────────────────────────────────────────────────────────────────
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
      onPrimary: Colors.white,
      secondary: Colors.amber,
      onSurface: Colors.white,
      onSurfaceVariant: Colors.white70,
      outline: Colors.grey,
      brightness: Brightness.dark,
    ),
    cardTheme: CardThemeData(
      elevation: 4.0,
      color: const Color(0xFF0A0805),
      shadowColor: const Color(0xFFE65100),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: const BorderSide(color: Color(0xFFFF9800), width: 1),
      ),
    ),
    iconTheme: IconThemeData(color: Colors.orange[400]),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0A0805),
        foregroundColor: Colors.orange[600], // Lighter text/icon color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: const BorderSide(color: Color(0xFFFF9800), width: 1),
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
    extensions: <ThemeExtension<dynamic>>[
      AppColors(
        primarySwatch: Colors.orange,
        success: Colors.greenAccent,
        warning: Colors.orangeAccent,
        error: Colors.redAccent,
        divider: Colors.grey.shade700,
        tableHeader: Colors.grey.shade900,
        disabledBackground: Colors.grey.shade800,
        disabledText: Colors.grey.shade400,
        secondaryText: Colors.grey.shade400,
        surface: const Color(0xFF0A0805),
        surfaceSubtle: Colors.white10,
        brandAccent: const Color(0xFF9B3746),
        onPrimarySubtle: Colors.white70,
      ),
    ],
  );

  // ─────────────────────────────────────────────────────────────────────────
  // THEME FACTORY — returns the original themes for saffron, creates
  // structurally identical copies with swapped colors for other presets.
  // ─────────────────────────────────────────────────────────────────────────
  static ThemeData getTheme(
    ThemePreset preset,
    bool isDark, {
    Color? customColor,
  }) {
    if (preset == ThemePreset.saffron) {
      return isDark ? darkTheme : lightTheme;
    }

    final Color primary;
    final Color secondary;
    final MaterialColor swatch;
    // Light-mode specific
    final Color lightCardColor;
    final Color lightCardBorder;
    final Color lightIconColor;
    final Color lightButtonFg;
    // Dark-mode specific
    final Color darkCardColor;
    final Color darkShadowColor;
    final Color darkCardBorder;
    final Color darkIconColor;
    final Color darkButtonFg;

    switch (preset) {
      case ThemePreset.maroon:
        primary = const Color(0xFF9B3746);
        secondary = const Color(0xFFFFD700);
        swatch = _createMaterialColor(primary);
        lightCardColor = const Color(0xFFF9EBEB);
        lightCardBorder = primary;
        lightIconColor = const Color(0xFFB14A5B);
        lightButtonFg = const Color(0xFF7D2C39);
        darkCardColor = const Color(0xFF140A0C);
        darkShadowColor = const Color(0xFF5D1D27);
        darkCardBorder = primary;
        darkIconColor = const Color(0xFFB14A5B);
        darkButtonFg = const Color(0xFFCF6679);
        break;
      case ThemePreset.sandalwood:
        primary = const Color(0xFFB87333);
        secondary = const Color(0xFFE31E24);
        swatch = _createMaterialColor(primary);
        lightCardColor = const Color(0xFFFAEFE6);
        lightCardBorder = primary;
        lightIconColor = const Color(0xFFC98B52);
        lightButtonFg = const Color(0xFF9A5F2A);
        darkCardColor = const Color(0xFF120D08);
        darkShadowColor = const Color(0xFF6E451F);
        darkCardBorder = primary;
        darkIconColor = const Color(0xFFC98B52);
        darkButtonFg = const Color(0xFFD4A06A);
        break;
      case ThemePreset.indigo:
        primary = const Color(0xFF3F51B5);
        secondary = const Color(0xFF00BCD4);
        swatch = _createMaterialColor(primary);
        lightCardColor = const Color(0xFFEBEEF9);
        lightCardBorder = primary;
        lightIconColor = const Color(0xFF5C6BC0);
        lightButtonFg = const Color(0xFF303F9F);
        darkCardColor = const Color(0xFF0A0B14);
        darkShadowColor = const Color(0xFF26316D);
        darkCardBorder = primary;
        darkIconColor = const Color(0xFF5C6BC0);
        darkButtonFg = const Color(0xFF7986CB);
        break;
      case ThemePreset.tulsi:
        primary = const Color(0xFF2E7D32);
        secondary = const Color(0xFFFFD54F);
        swatch = _createMaterialColor(primary);
        lightCardColor = const Color(0xFFE8F5E9);
        lightCardBorder = primary;
        lightIconColor = const Color(0xFF43A047);
        lightButtonFg = const Color(0xFF1B5E20);
        darkCardColor = const Color(0xFF0A1A0D);
        darkShadowColor = const Color(0xFF1B5E20);
        darkCardBorder = primary;
        darkIconColor = const Color(0xFF66BB6A);
        darkButtonFg = const Color(0xFF81C784);
        break;
      case ThemePreset.kumkum:
        primary = const Color(0xFFE53935);
        secondary = const Color(0xFFFFD700);
        swatch = _createMaterialColor(primary);
        lightCardColor = const Color(0xFFFFEBEE);
        lightCardBorder = primary;
        lightIconColor = const Color(0xFFEF5350);
        lightButtonFg = const Color(0xFFC62828);
        darkCardColor = const Color(0xFF1A0808);
        darkShadowColor = const Color(0xFF8E1A1A);
        darkCardBorder = primary;
        darkIconColor = const Color(0xFFEF5350);
        darkButtonFg = const Color(0xFFEF9A9A);
        break;
      case ThemePreset.diwali:
        primary = const Color(0xFF154C8C); // Royal Blue from image
        secondary = const Color(0xFFF2C249); // Gold from image
        swatch = _createMaterialColor(primary);
        lightCardColor = const Color(0xFFE3F2FD); // Light Blue Tint
        lightCardBorder = const Color(0xFFE52B7B); // Vibrant Pink Border from image
        lightIconColor = const Color(0xFFE52B7B); // Pink from image
        lightButtonFg = const Color(0xFF154C8C); // Royal Blue
        darkCardColor = const Color(0xFF0D2149); // Dark Navy from image
        darkShadowColor = const Color(0xFFE52B7B); // Pink Shadow
        darkCardBorder = const Color(0xFFE52B7B); // Vibrant Pink Border from image
        darkIconColor = const Color(0xFFF2C249); // Gold Icons
        darkButtonFg = const Color(0xFFF2C249); // Gold
        break;
      case ThemePreset.lotus:
        primary = const Color(0xFFE91E90);
        secondary = const Color(0xFFCE93D8);
        swatch = _createMaterialColor(primary);
        lightCardColor = const Color(0xFFFCE4EC);
        lightCardBorder = primary;
        lightIconColor = const Color(0xFFEC407A);
        lightButtonFg = const Color(0xFFC2185B);
        darkCardColor = const Color(0xFF1A0812);
        darkShadowColor = const Color(0xFF880E4F);
        darkCardBorder = primary;
        darkIconColor = const Color(0xFFF06292);
        darkButtonFg = const Color(0xFFF48FB1);
        break;
      case ThemePreset.peacock:
        primary = const Color(0xFF00897B);
        secondary = const Color(0xFF4DD0E1);
        swatch = _createMaterialColor(primary);
        lightCardColor = const Color(0xFFE0F2F1);
        lightCardBorder = primary;
        lightIconColor = const Color(0xFF26A69A);
        lightButtonFg = const Color(0xFF00695C);
        darkCardColor = const Color(0xFF071512);
        darkShadowColor = const Color(0xFF004D40);
        darkCardBorder = primary;
        darkIconColor = const Color(0xFF4DB6AC);
        darkButtonFg = const Color(0xFF80CBC4);
        break;
      case ThemePreset.custom:
        if (customColor == null) return isDark ? darkTheme : lightTheme;
        final derived = _deriveThemeColors(customColor);
        primary = customColor;
        secondary = derived['secondary']!;
        swatch = _createMaterialColor(primary);
        lightCardColor = derived['lightCardColor']!;
        lightCardBorder = primary;
        lightIconColor = derived['lightIconColor']!;
        lightButtonFg = derived['lightButtonFg']!;
        darkCardColor = derived['darkCardColor']!;
        darkShadowColor = derived['darkShadowColor']!;
        darkCardBorder = primary;
        darkIconColor = derived['darkIconColor']!;
        darkButtonFg = derived['darkButtonFg']!;
        break;
      default:
        return isDark ? darkTheme : lightTheme;
    }

    if (isDark) {
      return ThemeData(
        primarySwatch: swatch,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: AppBarTheme(
          backgroundColor: primary,
          foregroundColor: Colors.white,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          primary: primary,
          onPrimary: Colors.white,
          secondary: secondary,
          onSurface: Colors.white,
          onSurfaceVariant: Colors.white70,
          outline: Colors.grey,
          brightness: Brightness.dark,
        ),
        cardTheme: CardThemeData(
          elevation: 4.0,
          color: darkCardColor,
          shadowColor: darkShadowColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
            side: BorderSide(color: darkCardBorder, width: 1),
          ),
        ),
        iconTheme: IconThemeData(color: darkIconColor),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: darkCardColor,
            foregroundColor: darkButtonFg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
              side: BorderSide(color: primary, width: 1),
            ),
            padding: const EdgeInsets.symmetric(
              vertical: 16.0,
              horizontal: 24.0,
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: primary,
          contentTextStyle: const TextStyle(color: Colors.white),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        extensions: <ThemeExtension<dynamic>>[
          AppColors(
            primarySwatch: swatch,
            success: Colors.greenAccent,
            warning: Colors.orangeAccent,
            error: Colors.redAccent,
            divider: Colors.grey.shade700,
            tableHeader: Colors.grey.shade900,
            disabledBackground: Colors.grey.shade800,
            disabledText: Colors.grey.shade400,
            secondaryText: Colors.grey.shade400,
            surface: darkCardColor,
            surfaceSubtle: Colors.white10,
            brandAccent: const Color(0xFF9B3746),
            onPrimarySubtle: Colors.white70,
          ),
        ],
      );
    } else {
      return ThemeData(
        primarySwatch: swatch,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: AppBarTheme(
          backgroundColor: primary,
          foregroundColor: Colors.white,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          primary: primary,
          onPrimary: Colors.white,
          secondary: secondary,
          surface: Colors.white,
          onSurface: Colors.black,
          onSurfaceVariant: Colors.black54,
          outline: Colors.grey[300],
          brightness: Brightness.light,
        ),
        cardTheme: CardThemeData(
          elevation: 4.0,
          color: lightCardColor,
          shadowColor: lightCardBorder,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
            side: BorderSide(color: lightCardBorder, width: 1),
          ),
        ),
        iconTheme: IconThemeData(color: lightIconColor),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: lightCardColor,
            foregroundColor: lightButtonFg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
              side: BorderSide(color: primary, width: 1),
            ),
            padding: const EdgeInsets.symmetric(
              vertical: 16.0,
              horizontal: 24.0,
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: primary,
          contentTextStyle: const TextStyle(color: Colors.white),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        extensions: <ThemeExtension<dynamic>>[
          AppColors(
            primarySwatch: swatch,
            success: Colors.green,
            warning: Colors.orange,
            error: Colors.red,
            divider: Colors.grey.shade300,
            tableHeader: Colors.grey.shade200,
            disabledBackground: Colors.grey.shade200,
            disabledText: Colors.grey.shade400,
            secondaryText: Colors.grey.shade600,
            surface: Colors.white,
            surfaceSubtle: Colors.white10,
            brandAccent: const Color(0xFF9B3746),
            onPrimarySubtle: Colors.white70,
          ),
        ],
      );
    }
  }

  /// Algorithmically derives all theme color variants from a single [baseColor]
  /// using HSL transformations. Used by the custom theme preset.
  static Map<String, Color> _deriveThemeColors(Color baseColor) {
    final hsl = HSLColor.fromColor(baseColor);

    return {
      // Secondary: analogous hue (+60°), vibrant
      'secondary': hsl
          .withHue((hsl.hue + 60) % 360)
          .withSaturation(0.7)
          .withLightness(0.55)
          .toColor(),

      // Light mode
      'lightCardColor': hsl.withSaturation(0.18).withLightness(0.95).toColor(),
      'lightIconColor': hsl
          .withSaturation((hsl.saturation * 0.85).clamp(0.3, 0.8))
          .withLightness(0.50)
          .toColor(),
      'lightButtonFg': hsl
          .withSaturation((hsl.saturation * 0.9).clamp(0.3, 0.8))
          .withLightness(0.28)
          .toColor(),

      // Dark mode — tinted backgrounds instead of flat black
      'darkCardColor': hsl.withSaturation(0.30).withLightness(0.06).toColor(),
      'darkShadowColor': hsl.withSaturation(0.50).withLightness(0.18).toColor(),
      'darkIconColor': hsl.withSaturation(0.50).withLightness(0.55).toColor(),
      'darkButtonFg': hsl.withSaturation(0.40).withLightness(0.72).toColor(),
    };
  }

  static MaterialColor _createMaterialColor(Color color) {
    final List<double> strengths = <double>[.05];
    final Map<int, Color> swatch = {};
    final int r = (color.r * 255).round();
    final int g = (color.g * 255).round();
    final int b = (color.b * 255).round();

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    for (final strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromARGB(
        255,
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
      );
    }
    return MaterialColor(color.value, swatch);
  }
}

class AppColors extends ThemeExtension<AppColors> {
  final MaterialColor primarySwatch;
  final Color success;
  final Color warning;
  final Color error;
  final Color divider;
  final Color tableHeader;
  final Color disabledBackground;
  final Color disabledText;
  final Color secondaryText;
  final Color surface;
  final Color surfaceSubtle;
  final Color brandAccent;
  final Color onPrimarySubtle;

  const AppColors({
    required this.primarySwatch,
    required this.success,
    required this.warning,
    required this.error,
    required this.divider,
    required this.tableHeader,
    required this.disabledBackground,
    required this.disabledText,
    required this.secondaryText,
    required this.surface,
    required this.surfaceSubtle,
    required this.brandAccent,
    required this.onPrimarySubtle,
  });

  @override
  AppColors copyWith({
    MaterialColor? primarySwatch,
    Color? success,
    Color? warning,
    Color? error,
    Color? divider,
    Color? tableHeader,
    Color? disabledBackground,
    Color? disabledText,
    Color? secondaryText,
    Color? surface,
    Color? surfaceSubtle,
    Color? brandAccent,
    Color? onPrimarySubtle,
  }) {
    return AppColors(
      primarySwatch: primarySwatch ?? this.primarySwatch,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      divider: divider ?? this.divider,
      tableHeader: tableHeader ?? this.tableHeader,
      disabledBackground: disabledBackground ?? this.disabledBackground,
      disabledText: disabledText ?? this.disabledText,
      secondaryText: secondaryText ?? this.secondaryText,
      surface: surface ?? this.surface,
      surfaceSubtle: surfaceSubtle ?? this.surfaceSubtle,
      brandAccent: brandAccent ?? this.brandAccent,
      onPrimarySubtle: onPrimarySubtle ?? this.onPrimarySubtle,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) {
      return this;
    }
    return AppColors(
      primarySwatch: t < 0.5 ? primarySwatch : other.primarySwatch,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      tableHeader: Color.lerp(tableHeader, other.tableHeader, t)!,
      disabledBackground: Color.lerp(
        disabledBackground,
        other.disabledBackground,
        t,
      )!,
      disabledText: Color.lerp(disabledText, other.disabledText, t)!,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceSubtle: Color.lerp(surfaceSubtle, other.surfaceSubtle, t)!,
      brandAccent: Color.lerp(brandAccent, other.brandAccent, t)!,
      onPrimarySubtle: Color.lerp(onPrimarySubtle, other.onPrimarySubtle, t)!,
    );
  }
}

extension AppColorsExtension on ThemeData {
  AppColors get appColors =>
      extension<AppColors>() ??
      const AppColors(
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
}

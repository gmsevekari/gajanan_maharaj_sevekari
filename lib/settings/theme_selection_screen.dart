import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/settings/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';

class ThemeSelectionScreen extends StatelessWidget {
  const ThemeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.theme),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              Routes.home,
              (route) => false,
            ),
          ),
        ],
      ),
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Light / Dark / System Mode ──────────────────────
                _buildThemeOption(
                  context,
                  localizations.lightTheme,
                  themeProvider.themeMode == ThemeMode.light,
                  () => themeProvider.setTheme(ThemeMode.light),
                ),
                _buildThemeOption(
                  context,
                  localizations.darkTheme,
                  themeProvider.themeMode == ThemeMode.dark,
                  () => themeProvider.setTheme(ThemeMode.dark),
                ),
                _buildThemeOption(
                  context,
                  localizations.systemTheme,
                  themeProvider.themeMode == ThemeMode.system,
                  () => themeProvider.setTheme(ThemeMode.system),
                ),

                const SizedBox(height: 24),

                // ── Color Palette Grid ──────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    localizations.colorPalette,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 4,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.85,
                    children: [
                      _buildPresetOption(
                        context,
                        localizations.themeSaffron,
                        Colors.orange,
                        ThemePreset.saffron,
                        themeProvider,
                      ),
                      _buildPresetOption(
                        context,
                        localizations.themeMaroon,
                        const Color(0xFF9B3746),
                        ThemePreset.maroon,
                        themeProvider,
                      ),
                      _buildPresetOption(
                        context,
                        localizations.themeSandalwood,
                        const Color(0xFFB87333),
                        ThemePreset.sandalwood,
                        themeProvider,
                      ),
                      _buildPresetOption(
                        context,
                        localizations.themeIndigo,
                        const Color(0xFF3F51B5),
                        ThemePreset.indigo,
                        themeProvider,
                      ),
                      _buildPresetOption(
                        context,
                        localizations.themeTulsi,
                        const Color(0xFF2E7D32),
                        ThemePreset.tulsi,
                        themeProvider,
                      ),
                      _buildPresetOption(
                        context,
                        localizations.themeKumkum,
                        const Color(0xFFE53935),
                        ThemePreset.kumkum,
                        themeProvider,
                      ),
                      _buildPresetOption(
                        context,
                        localizations.themeLotus,
                        const Color(0xFFE91E90),
                        ThemePreset.lotus,
                        themeProvider,
                      ),
                      _buildPresetOption(
                        context,
                        localizations.themePeacock,
                        const Color(0xFF00897B),
                        ThemePreset.peacock,
                        themeProvider,
                      ),
                      _buildCustomOption(context, themeProvider),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    String title,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);

    Color cardColor;
    Color textColor;

    if (isSelected) {
      cardColor = theme.appColors.primarySwatch[200]!;
      textColor = theme.appColors.primarySwatch[800]!;
    } else {
      cardColor = theme.cardTheme.color!;
      textColor = theme.appColors.primarySwatch[600]!;
    }

    return Card(
      elevation: theme.cardTheme.elevation,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(
          color: isSelected
              ? theme.appColors.primarySwatch
              : theme.appColors.primarySwatch,
          width: 1,
        ),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        trailing: isSelected
            ? Icon(Icons.check, color: theme.appColors.primarySwatch[600])
            : null,
        onTap: onTap,
      ),
    );
  }

  Widget _buildPresetOption(
    BuildContext context,
    String name,
    Color primaryColor,
    ThemePreset preset,
    ThemeProvider themeProvider,
  ) {
    final theme = Theme.of(context);
    final isSelected = themeProvider.themePreset == preset;

    return GestureDetector(
      onTap: () => themeProvider.setPreset(preset),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withValues(alpha: 0.1)
              : theme.cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : theme.colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 22, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 10),
            Text(
              name,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? primaryColor : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomOption(BuildContext context, ThemeProvider themeProvider) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;
    final isSelected = themeProvider.themePreset == ThemePreset.custom;
    final currentCustomColor =
        themeProvider.customColor ?? theme.colorScheme.primary;

    return GestureDetector(
      onTap: () => _showColorPickerDialog(context, themeProvider),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? currentCustomColor.withValues(alpha: 0.1)
              : theme.cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? currentCustomColor
                : theme.colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: currentCustomColor.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isSelected
                    ? null
                    : const SweepGradient(
                        colors: [
                          Color(0xFFFF0000),
                          Color(0xFFFF9800),
                          Color(0xFFFFEB3B),
                          Color(0xFF4CAF50),
                          Color(0xFF2196F3),
                          Color(0xFF9C27B0),
                          Color(0xFFFF0000),
                        ],
                      ),
                color: isSelected ? currentCustomColor : null,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 22, color: Colors.white)
                  : const Icon(Icons.palette, size: 20, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Text(
              localizations.themeCustom,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? currentCustomColor
                    : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showColorPickerDialog(
    BuildContext context,
    ThemeProvider themeProvider,
  ) {
    final localizations = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return _ColorPickerDialog(
          title: localizations.customColorPicker,
          initialColor: themeProvider.customColor ?? Colors.deepPurple,
          onColorSelected: (color) {
            themeProvider.setCustomColor(color);
          },
        );
      },
    );
  }
}

/// A self-contained HSL hue + saturation picker dialog.
class _ColorPickerDialog extends StatefulWidget {
  final String title;
  final Color initialColor;
  final ValueChanged<Color> onColorSelected;

  const _ColorPickerDialog({
    required this.title,
    required this.initialColor,
    required this.onColorSelected,
  });

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late HSLColor _hslColor;

  @override
  void initState() {
    super.initState();
    _hslColor = HSLColor.fromColor(widget.initialColor);
    // Fix saturation/lightness to usable range for themes
    if (_hslColor.saturation < 0.3) {
      _hslColor = _hslColor.withSaturation(0.5);
    }
    if (_hslColor.lightness < 0.2 || _hslColor.lightness > 0.7) {
      _hslColor = _hslColor.withLightness(0.45);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedColor = _hslColor.toColor();

    return AlertDialog(
      title: Text(
        widget.title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Color Preview ──
            Container(
              height: 60,
              decoration: BoxDecoration(
                color: selectedColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: selectedColor.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Hue Slider ──
            _buildLabel(context, 'Hue'),
            const SizedBox(height: 8),
            _HueSlider(
              hue: _hslColor.hue,
              onChanged: (hue) {
                setState(() {
                  _hslColor = _hslColor.withHue(hue);
                });
              },
            ),
            const SizedBox(height: 20),

            // ── Saturation Slider ──
            _buildLabel(context, 'Saturation'),
            const SizedBox(height: 8),
            _GradientSlider(
              value: _hslColor.saturation,
              startColor: _hslColor.withSaturation(0.0).toColor(),
              endColor: _hslColor.withSaturation(1.0).toColor(),
              onChanged: (value) {
                setState(() {
                  _hslColor = _hslColor.withSaturation(value);
                });
              },
            ),
            const SizedBox(height: 20),

            // ── Lightness Slider ──
            _buildLabel(context, 'Brightness'),
            const SizedBox(height: 8),
            _GradientSlider(
              value: _hslColor.lightness,
              startColor: Colors.black,
              endColor: _hslColor.withLightness(0.5).toColor(),
              onChanged: (value) {
                setState(() {
                  _hslColor = _hslColor.withLightness(value.clamp(0.15, 0.65));
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        FilledButton(
          onPressed: () {
            widget.onColorSelected(selectedColor);
            Navigator.pop(context);
          },
          style: FilledButton.styleFrom(backgroundColor: selectedColor),
          child: const Text('Apply', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildLabel(BuildContext context, String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Full-spectrum hue slider with a rainbow gradient track.
class _HueSlider extends StatelessWidget {
  final double hue;
  final ValueChanged<double> onChanged;

  const _HueSlider({required this.hue, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            onPanUpdate: (details) {
              final newHue =
                  (details.localPosition.dx / constraints.maxWidth * 360).clamp(
                    0.0,
                    360.0,
                  );
              onChanged(newHue);
            },
            onTapDown: (details) {
              final newHue =
                  (details.localPosition.dx / constraints.maxWidth * 360).clamp(
                    0.0,
                    360.0,
                  );
              onChanged(newHue);
            },
            child: CustomPaint(
              size: Size(constraints.maxWidth, 32),
              painter: _HueTrackPainter(hue: hue),
            ),
          );
        },
      ),
    );
  }
}

class _HueTrackPainter extends CustomPainter {
  final double hue;

  _HueTrackPainter({required this.hue});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 4, size.width, size.height - 8);
    final gradient = LinearGradient(
      colors: List.generate(
        13,
        (i) => HSLColor.fromAHSL(1.0, i * 30.0, 0.85, 0.5).toColor(),
      ),
    );
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      paint,
    );

    // Thumb
    final thumbX = (hue / 360) * size.width;
    final thumbColor = HSLColor.fromAHSL(1.0, hue, 0.85, 0.5).toColor();
    canvas.drawCircle(
      Offset(thumbX.clamp(8.0, size.width - 8.0), size.height / 2),
      10,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(thumbX.clamp(8.0, size.width - 8.0), size.height / 2),
      8,
      Paint()
        ..color = thumbColor
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _HueTrackPainter oldDelegate) =>
      oldDelegate.hue != hue;
}

/// A generic two-color gradient slider for saturation/lightness.
class _GradientSlider extends StatelessWidget {
  final double value;
  final Color startColor;
  final Color endColor;
  final ValueChanged<double> onChanged;

  const _GradientSlider({
    required this.value,
    required this.startColor,
    required this.endColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            onPanUpdate: (details) {
              final newValue = (details.localPosition.dx / constraints.maxWidth)
                  .clamp(0.0, 1.0);
              onChanged(newValue);
            },
            onTapDown: (details) {
              final newValue = (details.localPosition.dx / constraints.maxWidth)
                  .clamp(0.0, 1.0);
              onChanged(newValue);
            },
            child: CustomPaint(
              size: Size(constraints.maxWidth, 32),
              painter: _GradientTrackPainter(
                value: value,
                startColor: startColor,
                endColor: endColor,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GradientTrackPainter extends CustomPainter {
  final double value;
  final Color startColor;
  final Color endColor;

  _GradientTrackPainter({
    required this.value,
    required this.startColor,
    required this.endColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 4, size.width, size.height - 8);
    final gradient = LinearGradient(colors: [startColor, endColor]);
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      paint,
    );

    // Thumb
    final thumbX = value * size.width;
    final thumbColor = Color.lerp(startColor, endColor, value)!;
    canvas.drawCircle(
      Offset(thumbX.clamp(8.0, size.width - 8.0), size.height / 2),
      10,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(thumbX.clamp(8.0, size.width - 8.0), size.height / 2),
      8,
      Paint()
        ..color = thumbColor
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _GradientTrackPainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.startColor != startColor ||
      oldDelegate.endColor != endColor;
}

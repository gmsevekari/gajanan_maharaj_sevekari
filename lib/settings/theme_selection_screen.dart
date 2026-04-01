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
}

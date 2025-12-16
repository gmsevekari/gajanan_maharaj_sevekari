import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/settings/theme_provider.dart';
import 'package:provider/provider.dart';

class ThemeSelectionScreen extends StatelessWidget {
  const ThemeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.theme, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      ),
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
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
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildThemeOption(
      BuildContext context, String title, bool isSelected, VoidCallback onTap) {

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    Color cardColor;
    Color textColor;

    if (isSelected) {
      cardColor = Colors.orange[100]!;
      textColor = Colors.orange[800]!;
    } else {
      cardColor = isDarkMode ? Colors.grey[850]! : Colors.white;
      textColor = isDarkMode ? Colors.white70 : Colors.black87;
    }

    return Card(
      elevation: 4.0,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: isSelected ? Colors.orange : Colors.grey.withOpacity(0.5), width: 1),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        title: Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
        trailing: isSelected
            ? Icon(Icons.check, color: Colors.orange[600])
            : null,
        onTap: onTap,
      ),
    );
  }
}

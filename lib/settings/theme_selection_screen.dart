import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/settings/theme_provider.dart';
import 'package:provider/provider.dart';

class ThemeSelectionScreen extends StatelessWidget {
  const ThemeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme Selection'),
      ),
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                _buildThemeOption(
                  context,
                  'Light Theme',
                  themeProvider.themeMode == ThemeMode.light,
                  () => themeProvider.setTheme(ThemeMode.light),
                ),
                _buildThemeOption(
                  context,
                  'Dark Theme',
                  themeProvider.themeMode == ThemeMode.dark,
                  () => themeProvider.setTheme(ThemeMode.dark),
                ),
                _buildThemeOption(
                  context,
                  'System Theme',
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
    return Card(
      child: ListTile(
        title: Text(title, style: const TextStyle(fontSize: 18)),
        trailing: isSelected
            ? Icon(Icons.check, color: Theme.of(context).primaryColor)
            : null,
        onTap: onTap,
      ),
    );
  }
}

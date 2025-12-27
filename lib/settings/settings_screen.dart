import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/settings/about_app_screen.dart';
import 'package:gajanan_maharaj_sevekari/settings/disclaimer_screen.dart';
import 'package:gajanan_maharaj_sevekari/settings/language_selection_screen.dart';
import 'package:gajanan_maharaj_sevekari/settings/theme_selection_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.settings, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, Routes.home, (route) => false),
          ),
        ],
      ),
      body: ListView(
        children: [
          _buildSettingsItem(context, localizations.language, Icons.language, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const LanguageSelectionScreen()));
          }),
          _buildSettingsItem(context, localizations.theme, Icons.color_lens, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ThemeSelectionScreen()));
          }),
          _buildSettingsItem(context, localizations.about, Icons.info, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutAppScreen()));
          }),
          _buildSettingsItem(context, localizations.disclaimer, Icons.gavel, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const DisclaimerScreen()));
          }),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 4.0,
      color: Colors.orange[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: Colors.orange.withAlpha(128), width: 1),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        leading: Icon(icon, color: Colors.orange[400]),
        title: Text(title, style: TextStyle(color: Colors.orange[600], fontWeight: FontWeight.bold, fontSize: 18)),
        trailing: Icon(Icons.arrow_forward_ios, color: Colors.orange[400]),
        onTap: onTap,
      ),
    );
  }
}

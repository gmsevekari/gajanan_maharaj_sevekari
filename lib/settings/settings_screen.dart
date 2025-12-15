import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/settings/about_app_screen.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/settings/disclaimer_screen.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/settings/language_selection_screen.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/settings/theme_selection_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          _buildSettingsItem(context, 'Language', Icons.language, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const LanguageSelectionScreen()));
          }),
          _buildSettingsItem(context, 'Theme', Icons.color_lens, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ThemeSelectionScreen()));
          }),
          _buildSettingsItem(context, 'About', Icons.info, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutAppScreen()));
          }),
          _buildSettingsItem(context, 'Disclaimer', Icons.gavel, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const DisclaimerScreen()));
          }),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontSize: 18)),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}

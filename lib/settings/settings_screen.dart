import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/settings/about_app_screen.dart';
import 'package:gajanan_maharaj_sevekari/settings/disclaimer_screen.dart';
import 'package:gajanan_maharaj_sevekari/settings/font_selection_screen.dart';
import 'package:gajanan_maharaj_sevekari/settings/language_selection_screen.dart';
import 'package:gajanan_maharaj_sevekari/settings/theme_selection_screen.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.settings),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, Routes.home, (route) => false),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(8.0),
        children: [
          _buildSettingsCard(context, Icons.language, localizations.language, const LanguageSelectionScreen()),
          _buildSettingsCard(context, Icons.color_lens, localizations.theme, const ThemeSelectionScreen()),
          _buildSettingsCard(context, Icons.font_download, localizations.font, const FontSelectionScreen()),
          _buildSettingsCard(context, Icons.info, localizations.about, const AboutAppScreen()),
          _buildSettingsCard(context, Icons.article, localizations.disclaimer, const DisclaimerScreen()),
          _buildContactUsCard(context, localizations),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, IconData icon, String title, Widget screen) {
    final theme = Theme.of(context);
    return Card(
      elevation: theme.cardTheme.elevation,
      color: theme.cardTheme.color,
      shape: theme.cardTheme.shape,
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        leading: Icon(icon, color: theme.iconTheme.color),
        title: Text(title, style: TextStyle(color: Colors.orange[600], fontWeight: FontWeight.bold, fontSize: 18)),
        trailing: Icon(Icons.arrow_forward_ios, color: theme.colorScheme.primary, size: 16.0),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
        },
      ),
    );
  }

  Widget _buildContactUsCard(BuildContext context, AppLocalizations localizations) {
    final theme = Theme.of(context);
    return Card(
      elevation: theme.cardTheme.elevation,
      color: theme.cardTheme.color,
      shape: theme.cardTheme.shape,
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        leading: Icon(Icons.email, color: theme.iconTheme.color),
        title: Text(localizations.contactUs, style: TextStyle(color: Colors.orange[600], fontWeight: FontWeight.bold, fontSize: 18)),
        trailing: Icon(Icons.arrow_forward_ios, color: theme.colorScheme.primary, size: 16.0),
        onTap: () async {
          final Uri emailLaunchUri = Uri(
            scheme: 'mailto',
            path: 'gajananmaharajseattle@gmail.com',
            query: 'subject=${Uri.encodeComponent('Gajanan Maharaj Sevekari App Feedback')}',
          );
          await launchUrl(emailLaunchUri);
        },
      ),
    );
  }
}

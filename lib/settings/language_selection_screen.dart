import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/settings/locale_provider.dart';
import 'package:provider/provider.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.language),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, Routes.home, (route) => false),
          ),
        ],
      ),
      body: Consumer<LocaleProvider>(
        builder: (context, localeProvider, child) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                _buildLanguageOption(
                  context,
                  localizations.english,
                  localeProvider.locale.languageCode == 'en',
                  () => localeProvider.setLocale(const Locale('en')),
                ),
                _buildLanguageOption(
                  context,
                  localizations.marathi,
                  localeProvider.locale.languageCode == 'mr',
                  () => localeProvider.setLocale(const Locale('mr')),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLanguageOption(
      BuildContext context, String title, bool isSelected, VoidCallback onTap) {
    final theme = Theme.of(context);

    Color cardColor;
    Color textColor;

    if (isSelected) {
      cardColor = Colors.orange[200]!;
      textColor = Colors.orange[800]!;
    } else {
      cardColor = theme.cardTheme.color!;
      textColor = Colors.orange[600]!;
    }

    return Card(
      elevation: theme.cardTheme.elevation,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: isSelected ? Colors.orange : Color(0xFFFF9800), width: 1),
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

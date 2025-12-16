import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/settings/locale_provider.dart';
import 'package:provider/provider.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.language, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
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
    return Card(
      elevation: 4.0,
      color: isSelected ? Colors.orange[100] : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: isSelected ? Colors.orange : Colors.grey.withOpacity(0.5), width: 1),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        title: Text(title, style: TextStyle(color: isSelected ? Colors.orange[600] : Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        trailing: isSelected
            ? Icon(Icons.check, color: Colors.orange[400])
            : null,
        onTap: onTap,
      ),
    );
  }
}

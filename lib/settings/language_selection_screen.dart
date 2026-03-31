import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/settings/locale_provider.dart';
import 'package:provider/provider.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';

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
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              Routes.home,
              (route) => false,
            ),
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
}

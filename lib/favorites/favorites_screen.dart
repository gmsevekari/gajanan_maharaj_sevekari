import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/app_config.dart';
import 'package:gajanan_maharaj_sevekari/providers/app_config_provider.dart';
import 'package:gajanan_maharaj_sevekari/shared/content_list_screen.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:provider/provider.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final appConfig = Provider.of<AppConfigProvider>(context).appConfig!;
    final favoritesConfig = appConfig.favorites;
    final defaultDeity = appConfig.deities.first;

    final favoritesMap = {
      'sunday_prarthana': favoritesConfig.sundayPrarthana,
      'other_aartis': favoritesConfig.otherAartis,
      'other_stotras': favoritesConfig.otherStotras,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.favoritesTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, Routes.home, (route) => false),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, Routes.settings),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: favoritesConfig.order.map((key) {
            final content = favoritesMap[key];
            if (content == null) return const SizedBox.shrink();

            final title = _getTitle(localizations, content.titleKey);

            return _buildFavoriteCard(
              context,
              theme,
              title,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ContentListScreen(
                      deity: defaultDeity,
                      title: title,
                      contentTypeId: key,
                      content: content,
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  String _getTitle(AppLocalizations localizations, String key) {
    switch (key) {
      case 'sundayPrarthanaTitle':
        return localizations.sundayPrarthanaTitle;
      case 'otherAartis':
        return localizations.otherAartis;
      case 'otherStotras':
        return localizations.otherStotras;
      default:
        return '';
    }
  }

  Widget _buildFavoriteCard(BuildContext context, ThemeData theme, String title, VoidCallback onTap) {
    return Card(
      elevation: theme.cardTheme.elevation,
      color: theme.cardTheme.color,
      shape: theme.cardTheme.shape,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 18.0),
        ),
        trailing: Icon(Icons.arrow_forward_ios, color: theme.colorScheme.primary, size: 16.0),
        onTap: onTap,
      ),
    );
  }
}

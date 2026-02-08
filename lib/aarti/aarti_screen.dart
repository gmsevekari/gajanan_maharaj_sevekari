import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/app_config.dart';
import 'package:gajanan_maharaj_sevekari/shared/content_detail_screen.dart';
import 'package:gajanan_maharaj_sevekari/shared/content_list_screen.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';

class AartiScreen extends StatelessWidget {
  final DeityConfig deity;
  const AartiScreen({super.key, required this.deity});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.aartiTitle),
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
      body: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: (deity.nityopasana.aartis as AartiContent).categories.length,
        itemBuilder: (context, index) {
          final category = (deity.nityopasana.aartis as AartiContent).categories[index];
          final title = _getCategoryTitle(localizations, category.titleKey);
          return _buildCategoryCard(context, title, category, deity);
        },
      ),
    );
  }

  String _getCategoryTitle(AppLocalizations localizations, String key) {
    switch (key) {
      case 'dailyAartis':
        return localizations.dailyAartis;
      case 'eventAartis':
        return localizations.eventAartis;
      default:
        return '';
    }
  }

  Widget _buildCategoryCard(
      BuildContext context, String title, AartiCategoryConfig category, DeityConfig deity) {
    final theme = Theme.of(context);
    return Card(
      elevation: theme.cardTheme.elevation,
      color: theme.cardTheme.color,
      shape: theme.cardTheme.shape,
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 18.0),
        ),
        trailing: Icon(Icons.arrow_forward_ios, color: theme.colorScheme.primary, size: 16.0),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ContentListScreen(
                deity: deity,
                title: title,
                contentType: ContentTypeExtension.fromString(category.contentType),
                content: category, // Pass the entire category object
              ),
            ),
          );
        },
      ),
    );
  }
}

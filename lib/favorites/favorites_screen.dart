import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/aarti/aarti_list_screen.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);

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
        child: Column(
          children: [
            Card(
              elevation: theme.cardTheme.elevation,
              color: theme.cardTheme.color,
              shape: theme.cardTheme.shape,
              margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
              child: ListTile(
                title: Text(
                  localizations.sundayPrarthanaTitle,
                  style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 18.0),
                ),
                trailing: Icon(Icons.arrow_forward_ios, color: theme.colorScheme.primary, size: 16.0),
                onTap: () => Navigator.pushNamed(context, Routes.sundayPrarthana),
              ),
            ),
            Card(
              elevation: theme.cardTheme.elevation,
              color: theme.cardTheme.color,
              shape: theme.cardTheme.shape,
              margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
              child: ListTile(
                title: Text(
                  localizations.otherAartis,
                  style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 18.0),
                ),
                trailing: Icon(Icons.arrow_forward_ios, color: theme.colorScheme.primary, size: 16.0),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AartiListScreen(category: AartiCategory.other),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

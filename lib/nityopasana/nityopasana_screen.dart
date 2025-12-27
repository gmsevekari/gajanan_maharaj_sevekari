import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';

class NityopasanaScreen extends StatelessWidget {
  const NityopasanaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    final List<Map<String, dynamic>> nityopasanaModules = [
      {'title': localizations.granthTitle, 'icon': Icons.menu_book_outlined, 'route': Routes.granth},
      {'title': localizations.stotraTitle, 'icon': Icons.queue_music, 'route': Routes.stotra},
      {'title': localizations.bhajanTitle, 'icon': Icons.lyrics_outlined, 'route': Routes.bhajan},
      {'title': localizations.aartiTitle, 'icon': Icons.library_music_outlined, 'route': Routes.aarti},
      {'title': localizations.namavaliTitle, 'icon': Icons.format_list_numbered, 'route': Routes.namavali},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.nityopasanaTitle, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, Routes.settings),
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(8.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.4,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
        ),
        itemCount: nityopasanaModules.length,
        itemBuilder: (context, index) {
          return _buildGridItem(
            context,
            nityopasanaModules[index]['title'],
            nityopasanaModules[index]['icon'],
            nityopasanaModules[index]['route'],
          );
        },
      ),
    );
  }

  Widget _buildGridItem(BuildContext context, String title, IconData icon, String route) {
    return Card(
      elevation: 8.0,
      color: Colors.orange[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: Colors.orange.withAlpha(128), width: 1),
      ),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40.0, color: Colors.orange[400]),
            const SizedBox(height: 8.0),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.orange[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

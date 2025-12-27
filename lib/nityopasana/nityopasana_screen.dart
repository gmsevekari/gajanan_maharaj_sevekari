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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Wrap(
            spacing: 8.0, // Horizontal space between cards
            runSpacing: 8.0, // Vertical space between rows
            alignment: WrapAlignment.center,
            children: nityopasanaModules.map((module) {
              return SizedBox(
                width: (MediaQuery.of(context).size.width - 24) / 2, // 24 = padding * 2 + spacing
                child: _buildGridItem(
                  context,
                  module['title'],
                  module['icon'],
                  module['route'],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildGridItem(BuildContext context, String title, dynamic icon, String route) {
    return AspectRatio(
      aspectRatio: 1.4,
      child: Card(
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
              if (icon is IconData)
                Icon(icon, size: 40.0, color: Colors.orange[400])
              else if (icon is String)
                Image.asset(icon, height: 40.0, width: 40.0),
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
      ),
    );
  }
}

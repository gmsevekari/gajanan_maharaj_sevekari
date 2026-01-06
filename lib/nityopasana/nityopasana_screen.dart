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
        title: Text(localizations.nityopasanaTitle),
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

  Widget _buildGridItem(
    BuildContext context,
    String title,
    dynamic icon,
    String route,
  ) {
    final theme = Theme.of(context);

    return AspectRatio(
      aspectRatio: 1.4,
      child: Container(
        // This Container provides the distinct bottom shadow
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: theme.cardTheme.shadowColor!, // Color of the shadow
              offset: const Offset(0, 4), // Shift shadow downwards
              blurRadius: 0, // Sharp edge for a "hard" shadow look
              spreadRadius: 0,
            ),
          ],
        ),
        child: Card(
          elevation: 0, // Disable default card elevation
          margin: EdgeInsets.zero, // Remove default margin
          color: theme.cardTheme.color,
          shape: theme.cardTheme.shape,
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
      ),
    );
  }
}

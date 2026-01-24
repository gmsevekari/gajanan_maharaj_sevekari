import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/app_config.dart';
import 'package:gajanan_maharaj_sevekari/aarti/aarti_screen.dart';
import 'package:gajanan_maharaj_sevekari/namavali/namavali_screen.dart';
import 'package:gajanan_maharaj_sevekari/shared/content_list_screen.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';

class NityopasanaScreen extends StatelessWidget {
  final DeityConfig deity;
  const NityopasanaScreen({super.key, required this.deity});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

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
            spacing: 8.0,
            runSpacing: 8.0,
            alignment: WrapAlignment.center,
            children: deity.nityopasana.order.map((id) {
              final content = _getContent(deity, id);
              return SizedBox(
                width: (MediaQuery.of(context).size.width - 24) / 2,
                child: _buildGridItem(
                  context,
                  _getTitle(localizations, (content as dynamic).titleKey),
                  _getIcon((content as dynamic).icon),
                  () => _navigateToContent(context, id, deity, _getTitle(localizations, (content as dynamic).titleKey), content),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  dynamic _getContent(DeityConfig deity, String id) {
    switch (id) {
      case 'granth': return deity.nityopasana.granth;
      case 'stotras': return deity.nityopasana.stotras;
      case 'bhajans': return deity.nityopasana.bhajans;
      case 'aartis': return deity.nityopasana.aartis;
      case 'namavali': return deity.nityopasana.namavali;
      default: throw Exception('Unknown content id: $id');
    }
  }

  void _navigateToContent(BuildContext context, String id, DeityConfig deity, String title, dynamic content) {
    Widget screen;
    if (id == 'aartis') {
      screen = AartiScreen(deity: deity);
    } else if (id == 'namavali') {
      screen = NamavaliScreen(deity: deity);
    } else {
      screen = ContentListScreen(
        deity: deity,
        title: title,
        contentTypeId: id,
        content: content as NityopasanaContent,
      );
    }
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  String _getTitle(AppLocalizations localizations, String key) {
    switch (key) {
      case 'granthTitle': return localizations.granthTitle;
      case 'stotraTitle': return localizations.stotraTitle;
      case 'bhajanTitle': return localizations.bhajanTitle;
      case 'aartiTitle': return localizations.aartiTitle;
      case 'namavaliTitle': return localizations.namavaliTitle;
      default: return '';
    }
  }

  IconData _getIcon(String iconName) {
    const iconMap = {
      'menu_book_outlined': Icons.menu_book_outlined,
      'queue_music': Icons.queue_music,
      'lyrics_outlined': Icons.lyrics_outlined,
      'library_music_outlined': Icons.library_music_outlined,
      'format_list_numbered': Icons.format_list_numbered,
    };
    return iconMap[iconName] ?? Icons.info;
  }

  Widget _buildGridItem(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);

    return AspectRatio(
      aspectRatio: 1.4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).cardTheme.shadowColor!,
              offset: const Offset(0, 4),
              blurRadius: 0,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: Theme.of(context).cardTheme.color,
          shape: Theme.of(context).cardTheme.shape,
          child: InkWell(
            onTap: onTap,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 40.0, color: Theme.of(context).iconTheme.color),
                const SizedBox(height: 8.0),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.orange[600], fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

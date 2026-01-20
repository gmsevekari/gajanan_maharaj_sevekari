import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/shared/content_detail_screen.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';

class SundayPrarthanaScreen extends StatefulWidget {
  const SundayPrarthanaScreen({super.key});

  @override
  State<SundayPrarthanaScreen> createState() => _SundayPrarthanaScreenState();
}

class _SundayPrarthanaScreenState extends State<SundayPrarthanaScreen> {
  late Future<List<Map<String, String>>> _stotraListFuture;

  final List<String> _stotraFiles = [
    'guru_geeta.json',
    'datta_majala.json',
    'karuna_tripadi.json',
    'gajanan_maharaj_bavanni.json', // Corrected filename
    'siddha_mangal.json',
    'ghor_kashtodharan.json',
    'datta_stuti.json',
    'namjap.json',
  ];

  @override
  void initState() {
    super.initState();
    _stotraListFuture = _loadStotraList();
  }

  Future<List<Map<String, String>>> _loadStotraList() async {
    final List<Map<String, String>> stotraList = [];
    for (var fileName in _stotraFiles) {
      String directory;
      String path;

      if (fileName == 'gajanan_maharaj_bavanni.json') {
        directory = ''; // It's in the root of stotras
        path = 'resources/texts/stotras/$fileName';
      } else {
        directory = 'sunday_prarthana';
        path = 'resources/texts/stotras/sunday_prarthana/$fileName';
      }

      final String response = await rootBundle.loadString(path);
      final data = await json.decode(response);
      final imageName = data['image'] ?? '';

      stotraList.add({
        'title_mr': data['title_mr'],
        'title_en': data['title_en'],
        'fileName': fileName,
        'directory': directory, // Pass the correct directory
        'imagePath': directory.isNotEmpty
            ? 'resources/images/stotras/$directory/$imageName'
            : 'resources/images/stotras/$imageName',
      });
    }
    return stotraList;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.sundayPrarthanaTitle),
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
      body: FutureBuilder<List<Map<String, String>>>(
        future: _stotraListFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final stotras = snapshot.data!;

            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: stotras.length,
              itemBuilder: (context, index) {
                final stotra = stotras[index];
                final title = locale.languageCode == 'mr' ? stotra['title_mr'] : stotra['title_en'];

                return Card(
                  elevation: theme.cardTheme.elevation,
                  color: theme.cardTheme.color,
                  shape: theme.cardTheme.shape,
                  margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: ListTile(
                    title: Text(
                      title!,
                      style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 18.0),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.play_circle_outline),
                          color: theme.colorScheme.primary,
                          onPressed: () {
                            final directory = stotra['directory']!;
                            final fileName = stotra['fileName']!;
                            final assetPath = directory.isNotEmpty
                                ? 'resources/texts/stotras/$directory/$fileName'
                                : 'resources/texts/stotras/$fileName';

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ContentDetailScreen(
                                  contentType: ContentType.stotra,
                                  contentList: stotras,
                                  currentIndex: index,
                                  imagePath: stotra['imagePath']!,
                                  assetPath: assetPath,
                                  initialTabIndex: 1,
                                  autoPlay: true,
                                ),
                              ),
                            );
                          },
                        ),
                        Icon(Icons.arrow_forward_ios, color: theme.colorScheme.primary, size: 16.0),
                      ],
                    ),
                    onTap: () {
                      final directory = stotra['directory']!;
                      final fileName = stotra['fileName']!;
                      final assetPath = directory.isNotEmpty
                          ? 'resources/texts/stotras/$directory/$fileName'
                          : 'resources/texts/stotras/$fileName';

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ContentDetailScreen(
                            contentType: ContentType.stotra,
                            contentList: stotras,
                            currentIndex: index,
                            imagePath: stotra['imagePath']!,
                            assetPath: assetPath,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          } else {
            return const Center(child: Text('No stotras found'));
          }
        },
      ),
    );
  }
}

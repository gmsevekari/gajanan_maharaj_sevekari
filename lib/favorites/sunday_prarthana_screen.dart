import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/stotra/stotra_details_screen.dart';
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
      stotraList.add({
        'title_mr': data['title_mr'],
        'title_en': data['title_en'],
        'fileName': fileName,
        'directory': directory, // Pass the correct directory
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
        title: Text(localizations.sundayPrarthanaTitle, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.orange,
        iconTheme: const IconThemeData(color: Colors.white),
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
              itemCount: stotras.length,
              itemBuilder: (context, index) {
                final stotra = stotras[index];
                final title = locale.languageCode == 'mr' ? stotra['title_mr'] : stotra['title_en'];

                return Card(
                  elevation: 4.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    side: BorderSide(color: Colors.orange.withAlpha(128), width: 1),
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: ListTile(
                    title: Text(
                      title!,
                      style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 18.0),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, color: theme.colorScheme.primary),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StotraDetailsScreen(
                            stotraList: stotras,
                            currentIndex: index,
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

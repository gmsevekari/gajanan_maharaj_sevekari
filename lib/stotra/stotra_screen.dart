import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/stotra/stotra_details_screen.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';

class StotraScreen extends StatefulWidget {
  const StotraScreen({super.key});

  @override
  State<StotraScreen> createState() => _StotraScreenState();
}

class _StotraScreenState extends State<StotraScreen> {
  late Future<List<Map<String, String>>> _stotraListFuture;

  final List<String> _stotraFiles = [
    'gajanan_maharaj_avahan.json',
    'gajanan_maharaj_ashtak.json',
    'gajanan_maharaj_bavanni.json',
    'gajanan_maharaj_21_namaskar.json',
    'gajanan_maharaj_sumananjali.json',
    'gajanan_maharaj_stotra_dasganu_maharaj_krut.json',
    'gajanan_maharaj_prachiti.json',
    'gajanan_maharaj_stotra_kasturicha_mrug.json',
    'gajanan_maharaj_stotra_yogi_rana.json',
    'gajananache_modak.json',
    'gajanan_maharaj_chalisa.json',
  ];

  @override
  void initState() {
    super.initState();
    _stotraListFuture = _loadStotraList();
  }

  Future<List<Map<String, String>>> _loadStotraList() async {
    final List<Map<String, String>> stotraList = [];
    for (var fileName in _stotraFiles) {
      final String response = await rootBundle.loadString('resources/texts/stotras/$fileName');
      final data = await json.decode(response);
      stotraList.add({
        'title_mr': data['title_mr'],
        'title_en': data['title_en'],
        'fileName': fileName,
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
        title: Text(localizations.stotraTitle),
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
                  elevation: theme.cardTheme.elevation,
                  color: theme.cardTheme.color,
                  shape: theme.cardTheme.shape,
                  margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: ListTile(
                    title: Text(
                      title!,
                      style: TextStyle(color: Colors.orange[600], fontWeight: FontWeight.bold, fontSize: 18.0),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, color: theme.colorScheme.primary, size: 16.0),
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

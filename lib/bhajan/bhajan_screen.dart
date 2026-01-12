import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gajanan_maharaj_sevekari/bhajan/bhajan_detail_screen.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';

class BhajanScreen extends StatefulWidget {
  const BhajanScreen({super.key});

  @override
  State<BhajanScreen> createState() => _BhajanScreenState();
}

class _BhajanScreenState extends State<BhajanScreen> {
  late Future<List<Map<String, String>>> _bhajanListFuture;

  final List<String> _bhajanFiles = [
    'gajananachya_charani_julavu.json',
    'murti_ahe_shegaonla.json',
    'gajananachya_bhajanat_nahato.json',
    'gajanan_maharaj_ovya.json',
    'sansari_sukhi_kasa_vhayacha.json',
    'shegavicha_zenda_fadfadato_unch_ambara.json',
  ];

  @override
  void initState() {
    super.initState();
    _bhajanListFuture = _loadBhajanList();
  }

  Future<List<Map<String, String>>> _loadBhajanList() async {
    final List<Map<String, String>> bhajanList = [];
    for (var fileName in _bhajanFiles) {
      final String response = await rootBundle.loadString('resources/texts/bhajans/$fileName');
      final data = await json.decode(response);
      bhajanList.add({
        'title_mr': data['title_mr'],
        'title_en': data['title_en'],
        'fileName': fileName,
      });
    }
    return bhajanList;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.bhajanTitle),
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
        future: _bhajanListFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final bhajans = snapshot.data!;

            return ListView.builder(
              itemCount: bhajans.length,
              itemBuilder: (context, index) {
                final bhajan = bhajans[index];
                final title = locale.languageCode == 'mr' ? bhajan['title_mr'] : bhajan['title_en'];

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
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BhajanDetailScreen(
                                  bhajanList: bhajans,
                                  currentIndex: index,
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BhajanDetailScreen(
                            bhajanList: bhajans,
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
            return const Center(child: Text('No bhajans found'));
          }
        },
      ),
    );
  }
}

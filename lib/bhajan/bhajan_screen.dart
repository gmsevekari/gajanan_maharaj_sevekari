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

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.bhajanTitle, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
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
                  elevation: 4.0,
                  color: Colors.orange[50],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    side: BorderSide(color: Colors.orange.withAlpha(128), width: 1),
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: ListTile(
                    title: Text(
                      title!,
                      style: TextStyle(color: Colors.orange[600], fontWeight: FontWeight.bold, fontSize: 18.0),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BhajanDetailScreen(bhajanFileName: bhajan['fileName']!),
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

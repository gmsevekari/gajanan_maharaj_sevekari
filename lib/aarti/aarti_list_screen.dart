import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gajanan_maharaj_sevekari/aarti/aarti_detail_screen.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';

enum AartiCategory { daily, event }

class AartiListScreen extends StatefulWidget {
  final AartiCategory category;

  const AartiListScreen({super.key, required this.category});

  @override
  State<AartiListScreen> createState() => _AartiListScreenState();
}

class _AartiListScreenState extends State<AartiListScreen> {
  late Future<List<Map<String, String>>> _aartiListFuture;

  final Map<AartiCategory, List<String>> _aartiFiles = {
    AartiCategory.daily: [
      'kakad_aarti.json',
      'madhyan_aarti.json',
      'dhoop_aarti.json',
      'shej_aarti.json',
    ],
    AartiCategory.event: [
      'prakat_din_aarti.json',
      'akshay_tritiya_aarti.json',
      'ashadhi_ekadashi_aarti.json',
      'rushi_panchami_aarti.json',
      'diwali_pahat_aarti.json',
      'datta_jayanti_aarti.json',
      'ram_navami_aarti.json',
    ]
  };

  @override
  void initState() {
    super.initState();
    _aartiListFuture = _loadAartiList();
  }

  Future<List<Map<String, String>>> _loadAartiList() async {
    final List<Map<String, String>> aartiList = [];
    final directory = widget.category == AartiCategory.daily ? 'daily' : 'event';
    final files = _aartiFiles[widget.category]!;

    for (var fileName in files) {
      final String response = await rootBundle.loadString('resources/texts/aartis/$directory/$fileName');
      final data = await json.decode(response);
      aartiList.add({
        'title_mr': data['title_mr'],
        'title_en': data['title_en'],
        'fileName': fileName,
        'directory': directory,
      });
    }
    return aartiList;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final String title = widget.category == AartiCategory.daily ? localizations.dailyAartis : localizations.eventAartis;

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
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
        future: _aartiListFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final aartis = snapshot.data!;

            return ListView.builder(
              itemCount: aartis.length,
              itemBuilder: (context, index) {
                final aarti = aartis[index];
                final title = locale.languageCode == 'mr' ? aarti['title_mr'] : aarti['title_en'];

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
                          builder: (context) => AartiDetailScreen(
                            aartiList: aartis,
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
            return const Center(child: Text('No aartis found'));
          }
        },
      ),
    );
  }
}

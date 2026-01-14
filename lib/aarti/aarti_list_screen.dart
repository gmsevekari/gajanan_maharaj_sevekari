import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gajanan_maharaj_sevekari/aarti/aarti_detail_screen.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';

enum AartiCategory { daily, event, other }

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
      'diwali_prabhat_aarti.json',
      'datta_jayanti_aarti.json',
      'ram_navami_aarti.json',
    ],
    AartiCategory.other: [
      'ganapati_aarti.json',
      'devi_aarti.json',
      'datta_maharaj_aarti.json',
      'shankar_aarti.json',
      'vitthal_aarti.json',
      'khandoba_aarti.json',
      'sai_baba_aarti.json',
      'dnyaneshwar_maharaj_aarti.json',
      'tukaram_maharaj_aarti.json',
      'karpur_aarti.json',
      'prarthana_ghalin_lotangan.json',
      'mantrapushpanjali.json',
    ]
  };

  @override
  void initState() {
    super.initState();
    _aartiListFuture = _loadAartiList();
  }

  Future<List<Map<String, String>>> _loadAartiList() async {
    final List<Map<String, String>> aartiList = [];
    final directory = widget.category == AartiCategory.daily
        ? 'daily'
        : (widget.category == AartiCategory.event ? 'event' : 'other');
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
    final String title = widget.category == AartiCategory.daily
        ? localizations.dailyAartis
        : (widget.category == AartiCategory.event
            ? localizations.eventAartis
            : localizations.otherAartis);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
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
                                builder: (context) => AartiDetailScreen(
                                  aartiList: aartis,
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

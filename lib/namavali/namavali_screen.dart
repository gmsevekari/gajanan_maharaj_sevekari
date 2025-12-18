import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/utils/routes.dart';

class NamavaliScreen extends StatefulWidget {
  const NamavaliScreen({super.key});

  @override
  State<NamavaliScreen> createState() => _NamavaliScreenState();
}

class _NamavaliScreenState extends State<NamavaliScreen> {
  late Future<List<dynamic>> _namavaliFuture;
  double _fontSize = 18.0;

  @override
  void initState() {
    super.initState();
    _namavaliFuture = _loadNamavali();
  }

  Future<List<dynamic>> _loadNamavali() async {
    final String response = await rootBundle.loadString('resources/texts/namavali/namavali_108.json');
    final data = await json.decode(response);
    return data['names'];
  }

  void _changeFontSize(double delta) {
    setState(() {
      _fontSize = (_fontSize + delta).clamp(12.0, 30.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.namavaliTitle, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, Routes.settings),
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _namavaliFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final names = snapshot.data!;

            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 120), // Padding for FloatingActionButtons
              itemCount: names.length,
              itemBuilder: (context, index) {
                final nameData = names[index];
                final name = locale.languageCode == 'mr' ? nameData['name_mr'] : nameData['name_en'];

                return Card(
                  elevation: 4.0,
                  color: Colors.orange[50],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    side: BorderSide(color: Colors.orange.withAlpha(128), width: 1),
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange[300],
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      name,
                      style: TextStyle(color: Colors.orange[600], fontWeight: FontWeight.bold, fontSize: _fontSize),
                    ),
                  ),
                );
              },
            );
          } else {
            return const Center(child: Text('No names found'));
          }
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'add',
            mini: true,
            backgroundColor: Colors.orange.withAlpha(179),
            foregroundColor: Colors.white,
            onPressed: () => _changeFontSize(2.0),
            child: const Icon(Icons.add, size: 20),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'remove',
            mini: true,
            backgroundColor: Colors.orange.withAlpha(179),
            foregroundColor: Colors.white,
            onPressed: () => _changeFontSize(-2.0),
            child: const Icon(Icons.remove, size: 20),
          ),
        ],
      ),
    );
  }
}

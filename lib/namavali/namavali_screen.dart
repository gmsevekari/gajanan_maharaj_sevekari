import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';

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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.namavaliTitle, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
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
      body: FutureBuilder<List<dynamic>>(
        future: _namavaliFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final names = snapshot.data!;

            return ListView.separated(
              padding: const EdgeInsets.only(bottom: 120), // Padding for FloatingActionButtons
              itemCount: names.length + 1, // Add 1 for the footer
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                if (index == names.length) {
                  // This is the footer
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Image.asset('resources/images/logo/App_Logo.png', height: 50, width: 50),
                        const SizedBox(height: 8),
                        Text(
                          localizations.namavaliFooter,
                          style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: theme.colorScheme.secondary),
                        ),
                      ],
                    ),
                  );
                }

                final nameData = names[index];
                final name = locale.languageCode == 'mr' ? nameData['name_mr'] : nameData['name_en'];

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange[100],
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(color: Colors.orange[800]),
                    ),
                  ),
                  title: Text(
                    name,
                    style: TextStyle(fontSize: _fontSize),
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

import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/bhajan/bhajan_detail_screen.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/l10n/app_localizations.dart';

class BhajanScreen extends StatelessWidget {
  const BhajanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    final List<String> bhajans = [
      localizations.bhajanGajananachya,
      localizations.bhajanMurtiAhe,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.bhajanTitle, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      ),
      body: ListView.builder(
        itemCount: bhajans.length,
        itemBuilder: (context, index) {
          final bhajanTitle = bhajans[index];
          return Card(
            elevation: 4.0,
            color: Colors.orange[50],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
              side: BorderSide(color: Colors.orange.withOpacity(0.5), width: 1),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: ListTile(
              title: Text(bhajanTitle, style: TextStyle(color: Colors.orange[600], fontWeight: FontWeight.bold)),
              trailing: Icon(Icons.arrow_forward_ios, color: Colors.orange[400]),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BhajanDetailScreen(bhajanTitle: bhajanTitle),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

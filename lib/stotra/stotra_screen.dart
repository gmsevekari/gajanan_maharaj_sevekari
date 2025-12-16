import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/stotra/stotra_detail_screen.dart';

class StotraScreen extends StatelessWidget {
  const StotraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    final List<String> stotras = [
      localizations.stotraAvahan,
      localizations.stotraBavanni,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.stotraTitle, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      ),
      body: ListView.builder(
        itemCount: stotras.length,
        itemBuilder: (context, index) {
          final stotraTitle = stotras[index];
          return Card(
            elevation: 4.0,
            color: Colors.orange[50],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
              side: BorderSide(color: Colors.orange.withOpacity(0.5), width: 1),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: ListTile(
              title: Text(stotraTitle, style: TextStyle(color: Colors.orange[600], fontWeight: FontWeight.bold)),
              trailing: Icon(Icons.arrow_forward_ios, color: Colors.orange[400]),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StotraDetailScreen(stotraTitle: stotraTitle),
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

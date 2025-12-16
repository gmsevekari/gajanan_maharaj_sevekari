import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/l10n/app_localizations.dart';

class NamavaliScreen extends StatelessWidget {
  const NamavaliScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    final List<String> namavali = List.generate(108, (index) => '${localizations.name} ${index + 1}');

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.namavaliTitle, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      ),
      body: ListView.builder(
        itemCount: namavali.length,
        itemBuilder: (context, index) {
          return Card(
            elevation: 4.0,
            color: Colors.orange[50],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
              side: BorderSide(color: Colors.orange.withOpacity(0.5), width: 1),
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
                namavali[index],
                style: TextStyle(color: Colors.orange[600], fontWeight: FontWeight.bold, fontSize: 18.0),
              ),
            ),
          );
        },
      ),
    );
  }
}

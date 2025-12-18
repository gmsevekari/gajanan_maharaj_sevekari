import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/granth/granth_adhyay_detail_screen.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/utils/routes.dart';

class GranthScreen extends StatelessWidget {
  const GranthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.granthTitle, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, Routes.settings),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: 21,
        itemBuilder: (context, index) {
          final adhyayNumber = index + 1;
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
                  '$adhyayNumber',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text('${localizations.adhyay} $adhyayNumber', style: TextStyle(color: Colors.orange[600], fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GranthAdhyayDetailScreen(adhyayNumber: adhyayNumber),
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

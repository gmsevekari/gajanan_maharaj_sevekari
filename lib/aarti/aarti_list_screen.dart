import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/aarti/aarti_detail_screen.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/l10n/app_localizations.dart';

enum AartiCategory { daily, event }

class AartiListScreen extends StatelessWidget {
  final AartiCategory category;

  const AartiListScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final List<String> aartis = _getAartisForCategory(localizations);
    final String title = category == AartiCategory.daily ? localizations.dailyAartis : localizations.eventAartis;

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      ),
      body: ListView.builder(
        itemCount: aartis.length,
        itemBuilder: (context, index) {
          final aartiTitle = aartis[index];
          return Card(
            elevation: 4.0,
            color: Colors.orange[50],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
              side: BorderSide(color: Colors.orange.withOpacity(0.5), width: 1),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: ListTile(
              title: Text(aartiTitle, style: TextStyle(color: Colors.orange[600], fontWeight: FontWeight.bold)),
              trailing: Icon(Icons.arrow_forward_ios, color: Colors.orange[400]),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AartiDetailScreen(aartiTitle: aartiTitle),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  List<String> _getAartisForCategory(AppLocalizations localizations) {
    if (category == AartiCategory.daily) {
      return [
        localizations.kakadAarti,
        localizations.madhyanAarti,
        localizations.dhoopAarti,
        localizations.shejAarti,
      ];
    } else {
      return [
        localizations.prakatDinAarti,
        localizations.ashadhiEkadashiAarti,
        localizations.dattaJayantiAarti,
        localizations.ramNavamiAarti,
        localizations.akshayTritiyaAarti,
        localizations.rushiPanchamiAarti,
      ];
    }
  }
}

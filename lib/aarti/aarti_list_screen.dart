import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/aarti/aarti_detail_screen.dart';

enum AartiCategory { daily, event }

class AartiListScreen extends StatelessWidget {
  final AartiCategory category;

  const AartiListScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final List<String> aartis = _getAartisForCategory();
    final String title = category == AartiCategory.daily ? 'Daily Aartis' : 'Event Aartis';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: ListView.builder(
        itemCount: aartis.length,
        itemBuilder: (context, index) {
          final aartiTitle = aartis[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: ListTile(
              title: Text(aartiTitle),
              trailing: const Icon(Icons.arrow_forward_ios),
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

  List<String> _getAartisForCategory() {
    if (category == AartiCategory.daily) {
      return [
        'Kakad Aarti',
        'Madhyan Aarti',
        'Dhoop Aarti',
        'Shej Aarti',
      ];
    } else {
      return [
        'Prakat Din Aarti',
        'Ashadhi Ekadashi Aarti',
        'Datta Jayanti Aarti',
        'Ram Navami Aarti',
        'Akshay Tritiya Aarti',
        'Rushi Panchami Aarti',
      ];
    }
  }
}

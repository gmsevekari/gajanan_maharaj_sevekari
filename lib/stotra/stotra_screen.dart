import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/stotra/stotra_detail_screen.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/utils/constants.dart';

class StotraScreen extends StatelessWidget {
  const StotraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> stotras = [
      'Gajanan Maharaj Avahan',
      'Gajanan Maharaj Bavanni',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(Constants.stotraTitle),
      ),
      body: ListView.builder(
        itemCount: stotras.length,
        itemBuilder: (context, index) {
          final stotraTitle = stotras[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: ListTile(
              title: Text(stotraTitle),
              trailing: const Icon(Icons.arrow_forward_ios),
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

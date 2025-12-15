import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/utils/constants.dart';

class NamavaliScreen extends StatelessWidget {
  const NamavaliScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> namavali = List.generate(108, (index) => 'Name ${index + 1}');

    return Scaffold(
      appBar: AppBar(
        title: const Text(Constants.namavaliTitle),
      ),
      body: ListView.builder(
        itemCount: namavali.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(
                namavali[index],
                style: const TextStyle(fontSize: 18.0),
              ),
            ),
          );
        },
      ),
    );
  }
}

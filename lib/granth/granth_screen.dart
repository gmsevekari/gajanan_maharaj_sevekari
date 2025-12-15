import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/granth/granth_adhyay_detail_screen.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/utils/constants.dart';

class GranthScreen extends StatelessWidget {
  const GranthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(Constants.granthTitle),
      ),
      body: ListView.builder(
        itemCount: 21,
        itemBuilder: (context, index) {
          final adhyayNumber = index + 1;
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  '$adhyayNumber',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text('Adhyay $adhyayNumber'),
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

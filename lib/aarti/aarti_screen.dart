import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/aarti/aarti_list_screen.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/utils/constants.dart';

class AartiScreen extends StatelessWidget {
  const AartiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(Constants.aartiTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            _buildCategoryCard(context, 'Daily Aartis', AartiCategory.daily),
            _buildCategoryCard(context, 'Event Aartis', AartiCategory.event),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, String title, AartiCategory category) {
    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AartiListScreen(category: category),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Icon(Icons.arrow_forward_ios),
            ],
          ),
        ),
      ),
    );
  }
}

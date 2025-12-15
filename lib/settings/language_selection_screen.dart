import 'package:flutter/material.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Language Selection'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            _buildLanguageOption(context, 'Marathi', true),
            _buildLanguageOption(context, 'English', false),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(BuildContext context, String language, bool isSelected) {
    return Card(
      child: ListTile(
        title: Text(language, style: const TextStyle(fontSize: 18)),
        trailing: isSelected ? Icon(Icons.check, color: Theme.of(context).primaryColor) : null,
        onTap: () {
          // Logic to change language
        },
      ),
    );
  }
}

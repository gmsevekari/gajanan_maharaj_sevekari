import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';

class DisclaimerScreen extends StatefulWidget {
  const DisclaimerScreen({super.key});

  @override
  State<DisclaimerScreen> createState() => _DisclaimerScreenState();
}

class _DisclaimerScreenState extends State<DisclaimerScreen> {
  late Future<Map<String, dynamic>> _disclaimerFuture;

  @override
  void initState() {
    super.initState();
    _disclaimerFuture = _loadDisclaimer();
  }

  Future<Map<String, dynamic>> _loadDisclaimer() async {
    final String response = await rootBundle.loadString('resources/texts/disclaimer/disclaimer.json');
    final data = await json.decode(response);
    return data;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.disclaimer),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, Routes.home, (route) => false),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _disclaimerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final disclaimerData = snapshot.data ?? {};
          final isMarathi = locale.languageCode == 'mr';
          final title = isMarathi ? disclaimerData['title_mr'] : disclaimerData['title_en'];
          final content = isMarathi ? disclaimerData['content_mr'] : disclaimerData['content_en'];

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(
                shape: theme.cardTheme.shape,
                color: theme.cardTheme.color,
                elevation: theme.cardTheme.elevation,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title ?? '',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        content ?? '',
                        style: theme.textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

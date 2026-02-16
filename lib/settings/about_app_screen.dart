import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';

class AboutAppScreen extends StatefulWidget {
  const AboutAppScreen({super.key});

  @override
  State<AboutAppScreen> createState() => _AboutAppScreenState();
}

class _AboutAppScreenState extends State<AboutAppScreen> {
  late Future<Map<String, dynamic>> _aboutAppFuture;

  @override
  void initState() {
    super.initState();
    _aboutAppFuture = _loadAboutApp();
  }

  Future<Map<String, dynamic>> _loadAboutApp() async {
    final String response = await rootBundle.loadString('resources/texts/about/about_app.json');
    final data = await json.decode(response);
    return data;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.about),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, Routes.home, (route) => false),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _aboutAppFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final aboutData = snapshot.data!;
            final isMarathi = locale.languageCode == 'mr';

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionCard(
                    context,
                    title: isMarathi ? aboutData['mission_title_mr'] : aboutData['mission_title_en'],
                    content: Text(
                      isMarathi ? aboutData['mission_content_mr'] : aboutData['mission_content_en'],
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    context,
                    title: isMarathi ? aboutData['features_title_mr'] : aboutData['features_title_en'],
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _buildBulletPoints(context, isMarathi ? aboutData['features_content_mr'] : aboutData['features_content_en']),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    context,
                    title: isMarathi ? aboutData['service_title_mr'] : aboutData['service_title_en'],
                    content: Text(
                      isMarathi ? aboutData['service_content_mr'] : aboutData['service_content_en'],
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
            );
          } else {
            return const Center(child: Text('No data found'));
          }
        },
      ),
    );
  }

  Widget _buildSectionCard(BuildContext context, {required String title, required Widget content}) {
    final theme = Theme.of(context);
    return Card(
      shape: theme.cardTheme.shape,
      color: theme.cardTheme.color,
      elevation: theme.cardTheme.elevation,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 16),
            content,
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBulletPoints(BuildContext context, List<dynamic> points) {
    final theme = Theme.of(context);
    return points.map((point) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• ', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.primary)),
            Expanded(
              child: Text(point, style: theme.textTheme.bodyLarge),
            ),
          ],
        ),
      );
    }).toList();
  }
}

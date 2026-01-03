import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';

class AboutAppScreen extends StatefulWidget {
  const AboutAppScreen({super.key});

  @override
  State<AboutAppScreen> createState() => _AboutAppScreenState();
}

class _AboutAppScreenState extends State<AboutAppScreen> {
  double _fontSize = 16.0;

  Future<String> _loadAboutContent(BuildContext context) async {
    final locale = Localizations.localeOf(context);
    final path = locale.languageCode == 'mr'
        ? 'resources/texts/about/about_app_mr.md'
        : 'resources/texts/about/about_app.md';
    return await rootBundle.loadString(path);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final markdownStyleSheet = MarkdownStyleSheet.fromTheme(theme).copyWith(
      p: theme.textTheme.bodyLarge?.copyWith(fontSize: _fontSize),
      h3: theme.textTheme.headlineSmall?.copyWith(fontSize: _fontSize + 6, fontWeight: FontWeight.bold),
      strong: theme.textTheme.bodyMedium?.copyWith(fontSize: _fontSize, fontWeight: FontWeight.bold),
      listBullet: theme.textTheme.bodyLarge?.copyWith(fontSize: _fontSize, fontWeight: FontWeight.bold),
    );

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
      body: FutureBuilder<String>(
        future: _loadAboutContent(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          return Markdown(
            data: snapshot.data ?? '',
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // Padding for FABs
            styleSheet: markdownStyleSheet,
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            mini: true,
            onPressed: () {
              setState(() {
                if (_fontSize < 30.0) _fontSize += 2;
              });
            },
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            mini: true,
            onPressed: () {
              setState(() {
                if (_fontSize > 10.0) _fontSize -= 2;
              });
            },
            child: const Icon(Icons.remove),
          ),
        ],
      ),
    );
  }
}

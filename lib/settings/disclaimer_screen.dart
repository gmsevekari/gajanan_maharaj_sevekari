import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';

class DisclaimerScreen extends StatefulWidget {
  const DisclaimerScreen({super.key});

  @override
  State<DisclaimerScreen> createState() => _DisclaimerScreenState();
}

class _DisclaimerScreenState extends State<DisclaimerScreen> {
  double _fontSize = 16.0;

  Future<String> _loadDisclaimer(BuildContext context) async {
    final langCode = Localizations.localeOf(context).languageCode;
    final path = langCode == 'mr'
        ? 'resources/texts/disclaimer/disclaimer_mr.md'
        : 'resources/texts/disclaimer/disclaimer.md';
    return await rootBundle.loadString(path);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);

    // Use the theme's default text color for perfect contrast in both light and dark modes.
    // This matches the pattern from bhajan_detail_screen.dart.
    final markdownStyleSheet = MarkdownStyleSheet.fromTheme(theme).copyWith(
      p: theme.textTheme.bodyLarge?.copyWith(fontSize: _fontSize),
      h3: theme.textTheme.headlineSmall?.copyWith(fontSize: _fontSize + 4, fontWeight: FontWeight.bold),
      strong: theme.textTheme.bodyMedium?.copyWith(fontSize: _fontSize, fontWeight: FontWeight.bold),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.disclaimer,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<String>(
        future: _loadDisclaimer(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          // NO CARD: Display directly on the scaffold background for theme-awareness.
          return Markdown(
            data: snapshot.data ?? '',
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // Padding for content and FABs
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

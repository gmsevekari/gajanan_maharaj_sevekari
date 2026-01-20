import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';

class AboutMaharajScreen extends StatefulWidget {
  const AboutMaharajScreen({super.key});

  @override
  State<AboutMaharajScreen> createState() => _AboutMaharajScreenState();
}

class _AboutMaharajScreenState extends State<AboutMaharajScreen> {
  double _fontSize = 18.0;

  void _changeFontSize(double delta) {
    setState(() {
      _fontSize = (_fontSize + delta).clamp(14.0, 32.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(localizations.aboutMaharajTitle, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.orange,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, Routes.home, (route) => false),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, Routes.settings),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        child: Column(
          children: [
            _buildTopSection(context, localizations),
            const SizedBox(height: 24),
            _buildExpansionCard(
              context,
              icon: Icons.book,
              title: localizations.cardTitleJeevanParichay,
              content: localizations.cardContentJeevanParichay,
            ),
            _buildExpansionCard(
              context,
              icon: Icons.history,
              title: localizations.cardTitlePragatItihas,
              content: localizations.cardContentPragatItihas,
            ),
            _buildExpansionCard(
              context,
              icon: Icons.lightbulb,
              title: localizations.cardTitleShikvan,
              content: localizations.cardContentShikvan,
            ),
            _buildExpansionCard(
              context,
              icon: Icons.temple_hindu,
              title: localizations.cardTitleSamadhi,
              content: localizations.cardContentSamadhi,
            ),
            const SizedBox(height: 32),
            Text(
              localizations.footerQuote,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: theme.colorScheme.secondary),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'add',
            mini: true,
            backgroundColor: Colors.orange.withAlpha(179),
            foregroundColor: Colors.white,
            onPressed: () => _changeFontSize(2.0),
            child: const Icon(Icons.add, size: 20),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'remove',
            mini: true,
            backgroundColor: Colors.orange.withAlpha(179),
            foregroundColor: Colors.white,
            onPressed: () => _changeFontSize(-2.0),
            child: const Icon(Icons.remove, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSection(BuildContext context, AppLocalizations localizations) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.orange.shade300, width: 3),
          ),
          child: const CircleAvatar(
            radius: 70,
            backgroundImage: AssetImage('resources/images/about/App_About.png'),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          localizations.aboutMaharajScreenTitle,
          style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_on, color: theme.colorScheme.secondary, size: 20),
            const SizedBox(width: 4),
            Text(
              localizations.aboutMaharajLocation,
              style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.secondary),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          localizations.aboutMaharajPragatDin,
          style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.secondary),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.orange,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            localizations.aboutMaharajChant,
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildExpansionCard(BuildContext context, {required IconData icon, required String title, required String content}) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: theme.cardTheme.shape,
      color: theme.cardTheme.color,
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(icon, color: Colors.orange[600]),
          title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.orange[800])),
          iconColor: theme.iconTheme.color,
          collapsedIconColor: theme.iconTheme.color,
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text(
              content,
              textAlign: TextAlign.justify,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: _fontSize, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

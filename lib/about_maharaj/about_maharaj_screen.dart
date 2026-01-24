import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/app_config.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';

class AboutMaharajScreen extends StatefulWidget {
  final DeityConfig deity;

  const AboutMaharajScreen({super.key, required this.deity});

  @override
  State<AboutMaharajScreen> createState() => _AboutMaharajScreenState();
}

class _AboutMaharajScreenState extends State<AboutMaharajScreen> {
  double _fontSize = 18.0;
  late Future<AboutDeity> _aboutDeityFuture;

  @override
  void initState() {
    super.initState();
    final path = 'resources/texts/${widget.deity.id}/about/${widget.deity.aboutFile}';
    _aboutDeityFuture = AboutDeity.fromFile(path);
  }

  void _changeFontSize(double delta) {
    setState(() {
      _fontSize = (_fontSize + delta).clamp(14.0, 32.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;

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
      body: FutureBuilder<AboutDeity>(
        future: _aboutDeityFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final about = snapshot.data!;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              child: Column(
                children: [
                  _buildTopSection(context, about, widget.deity.imagePath, locale),
                  const SizedBox(height: 24),
                  ...about.sections.map((section) => _buildExpansionCard(
                        context,
                        icon: _getIconForSection(section.titleEn),
                        title: locale == 'mr' ? section.titleMr : section.titleEn,
                        content: locale == 'mr' ? section.contentMr : section.contentEn,
                      )),
                  const SizedBox(height: 32),
                  Text(
                    locale == 'mr' ? about.footerQuoteMr : about.footerQuoteEn,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: theme.colorScheme.secondary),
                  ),
                ],
              ),
            );
          } else {
            return const Center(child: Text('No data'));
          }
        },
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

  Widget _buildTopSection(BuildContext context, AboutDeity about, String imagePath, String locale) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.orange.shade300, width: 3),
          ),
          child: ClipOval(
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
              width: 140,
              height: 140,
              alignment: Alignment.topCenter,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          locale == 'mr' ? about.titleMr : about.titleEn,
          style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_on, color: theme.colorScheme.secondary, size: 20),
            const SizedBox(width: 4),
            Text(
              locale == 'mr' ? about.locationMr : about.locationEn,
              style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.secondary),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          locale == 'mr' ? about.pragatDinMr : about.pragatDinEn,
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
            locale == 'mr' ? about.chantMr : about.chantEn,
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  IconData _getIconForSection(String titleEn) {
    switch (titleEn) {
      case 'Introduction to Life':
        return Icons.book;
      case 'History of Appearance':
        return Icons.history;
      case 'Teachings and Philosophy':
        return Icons.lightbulb;
      case 'Samadhi Details':
        return Icons.temple_hindu;
      default:
        return Icons.info;
    }
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

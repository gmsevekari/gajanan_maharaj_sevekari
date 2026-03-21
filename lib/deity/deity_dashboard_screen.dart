import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/app_config.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:gajanan_maharaj_sevekari/shared/global_search_delegate.dart';
import 'package:gajanan_maharaj_sevekari/aarti/aarti_screen.dart';
import 'package:gajanan_maharaj_sevekari/namavali/namavali_screen.dart';
import 'package:gajanan_maharaj_sevekari/shared/content_list_screen.dart';
import 'package:gajanan_maharaj_sevekari/shared/content_detail_screen.dart';

class DeityDashboardScreen extends StatelessWidget {
  final DeityConfig deity;

  const DeityDashboardScreen({super.key, required this.deity});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final String? deviceCountryCode =
        View.of(context).platformDispatcher.locale.countryCode;

    final deityName = locale == 'mr' ? deity.nameMr : deity.nameEn;

    final List<Widget> featureCards = [];

    // Nityopasana Items (Flattened)
    for (var id in deity.nityopasana.order) {
      final content = _getContent(deity.nityopasana, id);
      if (content == null) continue;

      featureCards.add(
        _buildGridItem(
          context,
          _getNityopasanaTitle(localizations, (content as dynamic).titleKey),
          _getNityopasanaIcon((content as dynamic).icon),
          () => _navigateToContent(
            context,
            deity,
            _getNityopasanaTitle(localizations, (content as dynamic).titleKey),
            content,
          ),
        ),
      );
    }

    // Only show Donations card if the donation info exists and the region matches
    if (deity.donationInfo != null &&
        (deity.donationInfo!.regions.isEmpty ||
            deity.donationInfo!.regions.contains(deviceCountryCode))) {
      featureCards.add(
        _buildGridItem(
          context,
          localizations.donationsTitle,
          Icons.volunteer_activism_outlined,
          () => Navigator.pushNamed(
            context,
            Routes.donations,
            arguments: deity,
          ),
        ),
      );
    }

    // Only show Signups card if the signup info exists and the region matches
    if (deity.signupInfo != null &&
        (deity.signupInfo!.regions.isEmpty ||
            deity.signupInfo!.regions.contains(deviceCountryCode))) {
      featureCards.add(
        _buildGridItem(
          context,
          localizations.signupsTitle,
          Icons.assignment_ind_outlined,
          () => Navigator.pushNamed(
            context,
            Routes.signups,
            arguments: deity,
          ),
        ),
      );
    }

    if (deity.songs != null) {
      featureCards.add(
        _buildGridItem(
          context,
          localizations.songTitle,
          Icons.library_music,
          () =>
              Navigator.pushNamed(context, Routes.songs, arguments: deity),
        ),
      );
    }

    if (deity.socialMediaLinks.isNotEmpty) {
      featureCards.add(
        _buildGridItem(
          context,
          localizations.socialMediaTitle,
          Icons.connect_without_contact,
          () => Navigator.pushNamed(
            context,
            Routes.socialMedia,
            arguments: deity,
          ),
        ),
      );
    }

    if (deity.aboutFile.isNotEmpty) {
      featureCards.add(
        _buildGridItem(
          context,
          _getAboutTitle(localizations, deity.aboutTitleKey),
          Icons.info_outline,
          () => Navigator.pushNamed(
            context,
            Routes.aboutMaharaj,
            arguments: deity,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(deityName),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: GlobalSearchDelegate(
                  hintText: localizations.searchHint,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              Routes.home,
              (route) => false,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, Routes.settings),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                alignment: WrapAlignment.center,
                children: featureCards,
              ),
              const SizedBox(
                height: 100,
              ), // Extra space to prevent bottom cards from cutting off on zoomed displays
            ],
          ),
        ),
      ),
    );
  }

  dynamic _getContent(NityopasanaConfig nityopasana, String id) {
    switch (id) {
      case 'granth':
        return nityopasana.granth;
      case 'stotras':
        return nityopasana.stotras;
      case 'bhajans':
        return nityopasana.bhajans;
      case 'aartis':
        return nityopasana.aartis;
      case 'namavali':
        return nityopasana.namavali;
      default:
        return null;
    }
  }

  String _getNityopasanaTitle(AppLocalizations localizations, String key) {
    switch (key) {
      case 'granthTitle':
        return localizations.granthTitle;
      case 'stotraTitle':
        return localizations.stotraTitle;
      case 'bhajanTitle':
        return localizations.bhajanTitle;
      case 'aartiTitle':
        return localizations.aartiTitle;
      case 'namavaliTitle':
        return localizations.namavaliTitle;
      default:
        return '';
    }
  }

  IconData _getNityopasanaIcon(String iconName) {
    const iconMap = {
      'menu_book_outlined': Icons.menu_book_outlined,
      'queue_music': Icons.queue_music,
      'lyrics_outlined': Icons.lyrics_outlined,
      'library_music_outlined': Icons.library_music_outlined,
      'format_list_numbered': Icons.format_list_numbered,
    };
    return iconMap[iconName] ?? Icons.info;
  }

  void _navigateToContent(
    BuildContext context,
    DeityConfig deity,
    String title,
    dynamic content,
  ) {
    Widget screen;
    if (content is AartiContent) {
      screen = AartiScreen(deity: deity);
    } else if (content is NamavaliContent) {
      screen = NamavaliScreen(deity: deity);
    } else {
      screen = ContentListScreen(
        deity: deity,
        title: title,
        contentType: ContentTypeExtension.fromString(
          (content as ContentContainer).contentType,
        ),
        content: content as ContentContainer,
      );
    }
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  String _getAboutTitle(AppLocalizations localizations, String key) {
    switch (key) {
      case 'aboutMaharajTitle':
        return localizations.aboutMaharajTitle;
      case 'aboutBabaTitle':
        return localizations.aboutBabaTitle;
      case 'aboutGanapatiTitle':
        return localizations.aboutGanapatiTitle;
      case 'aboutShriramTitle':
        return localizations.aboutShriramTitle;
      case 'aboutHanumanTitle':
        return localizations.aboutHanumanTitle;
      default:
        return localizations.aboutMaharajTitle; // Default fallback
    }
  }

  Widget _buildGridItem(
    BuildContext context,
    String title,
    dynamic icon,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);

    return SizedBox(
      width: (MediaQuery.of(context).size.width - 24) / 2,
      child: AspectRatio(
        aspectRatio: 1.4,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: [
              BoxShadow(
                color: theme.cardTheme.shadowColor!,
                offset: const Offset(0, 4),
                blurRadius: 0,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            color: theme.cardTheme.color,
            shape: theme.cardTheme.shape,
            child: InkWell(
              onTap: onTap,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon is IconData)
                    Icon(icon, size: 40.0, color: theme.iconTheme.color)
                  else if (icon is String)
                    Image.asset(icon, height: 40.0, width: 40.0),
                  const SizedBox(height: 8.0),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.orange[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

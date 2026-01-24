import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/app_config.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:url_launcher/url_launcher.dart';

class SocialMediaScreen extends StatelessWidget {
  final DeityConfig deity;
  const SocialMediaScreen({super.key, required this.deity});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.socialMedia, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                localizations.officialSocialMediaHandles,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 16),
              ...deity.socialMediaLinks.map((link) => SocialMediaCard(
                platform: _getPlatformName(localizations, link.platform),
                description: _getPlatformDescription(localizations, link.platform),
                icon: 'resources/images/${deity.id}/social/${link.icon}',
                url: link.url,
                color: Color(int.parse(link.color.substring(1, 7), radix: 16) + 0xFF000000),
              )),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: theme.colorScheme.secondary, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    localizations.officialLinks,
                    style: TextStyle(color: theme.colorScheme.secondary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPlatformName(AppLocalizations localizations, String platform) {
    switch (platform) {
      case 'facebook':
        return localizations.facebook;
      case 'youtube':
        return localizations.youtube;
      case 'instagram':
        return localizations.instagram;
      case 'google_photos':
        return localizations.googlePhotos;
      default:
        return '';
    }
  }

  String _getPlatformDescription(AppLocalizations localizations, String platform) {
    switch (platform) {
      case 'facebook':
        return localizations.officialPage;
      case 'youtube':
        return localizations.videosAndStreams;
      case 'instagram':
        return localizations.photosAndReels;
      case 'google_photos':
        return localizations.photoGallery;
      default:
        return '';
    }
  }
}

class SocialMediaCard extends StatelessWidget {
  const SocialMediaCard({
    super.key,
    required this.platform,
    required this.description,
    required this.icon,
    required this.url,
    required this.color,
  });

  final String platform;
  final String description;
  final String icon;
  final String url;
  final Color color;

  Future<void> _launchURL() async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 8.0,
      color: theme.cardTheme.color,
      shape: theme.cardTheme.shape,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: _launchURL,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.1),
                radius: 24,
                child: Image.asset(icon, height: 28, width: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      platform,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: theme.colorScheme.secondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: theme.colorScheme.primary, size: 16.0),
            ],
          ),
        ),
      ),
    );
  }
}

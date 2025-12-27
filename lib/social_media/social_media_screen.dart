import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:url_launcher/url_launcher.dart';

class SocialMediaScreen extends StatelessWidget {
  const SocialMediaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final List<Map<String, String>> socialMediaLinks = [
      {
        'platform': localizations.facebook,
        'description': localizations.officialPage,
        'icon': 'resources/images/social/Facebook.png',
        'url': 'https://www.facebook.com/profile.php?id=100069020920320',
        'color': '#3b5998', // Facebook Blue
      },
      {
        'platform': localizations.youtube,
        'description': localizations.videosAndStreams,
        'icon': 'resources/images/social/YouTube.png',
        'url': 'https://www.youtube.com/@GajananMaharajSeattle',
        'color': '#FF0000', // YouTube Red
      },
      {
        'platform': localizations.instagram,
        'description': localizations.photosAndReels,
        'icon': 'resources/images/social/Instagram.png',
        'url': 'https://www.instagram.com/gajanan_maharaj_parivar_wa',
        'color': '#E1306C', // Instagram Pink
      },
      {
        'platform': localizations.googlePhotos,
        'description': localizations.photoGallery,
        'icon': 'resources/images/social/Google_Photos.png',
        'url': 'https://photos.app.goo.gl/vxwABG9wP8avhdAg8',
        'color': '#DB4437', // Google Red
      },
      {
        'platform': localizations.whatsapp,
        'description': localizations.whatsappAdminContact,
        'icon': 'resources/images/social/WhatsApp.png',
        'url': 'https://wa.me/17738228475',
        'color': '#25D366', // WhatsApp Green
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.socialMedia, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
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
              ...socialMediaLinks.map((link) => SocialMediaCard(
                platform: link['platform']!,
                description: link['description']!,
                icon: link['icon']!,
                url: link['url']!,
                color: Color(int.parse(link['color']!.substring(1, 7), radix: 16) + 0xFF000000),
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
      color: Colors.orange[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: Colors.orange.withAlpha(128), width: 1),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: _launchURL,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.1),
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
              Icon(Icons.arrow_forward_ios, color: Colors.orange[400], size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

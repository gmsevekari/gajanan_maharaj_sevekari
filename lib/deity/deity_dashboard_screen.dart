import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/app_config.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';

class DeityDashboardScreen extends StatelessWidget {
  final DeityConfig deity;

  const DeityDashboardScreen({super.key, required this.deity});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final String? deviceCountryCode = View.of(context).platformDispatcher.locale.countryCode;

    final deityName = locale == 'mr' ? deity.nameMr : deity.nameEn;

    final List<Widget> featureCards = [];

    if (deity.nityopasana.order.isNotEmpty) {
      featureCards.add(_buildGridItem(context, localizations.nityopasanaTitle, 'resources/images/icon/Nitya_Smaran.png', Routes.nityopasana, arguments: deity));
    }

    // Only show Donations card if the donation info exists and the region matches
    if (deity.donationInfo != null && (deity.donationInfo!.regions.isEmpty || deity.donationInfo!.regions.contains(deviceCountryCode))) {
      featureCards.add(_buildGridItem(context, localizations.donationsTitle, Icons.volunteer_activism_outlined, Routes.donations, arguments: deity));
    }

    // Only show Signups card if the signup info exists and the region matches
    if (deity.signupInfo != null && (deity.signupInfo!.regions.isEmpty || deity.signupInfo!.regions.contains(deviceCountryCode))) {
      featureCards.add(_buildGridItem(context, localizations.signupsTitle, Icons.assignment_ind_outlined, Routes.signups, arguments: deity));
    }

    if (deity.aboutFile.isNotEmpty) {
      featureCards.add(_buildGridItem(context, _getAboutTitle(localizations, deity.aboutTitleKey), Icons.info_outline, Routes.aboutMaharaj, arguments: deity));
    }

    if (deity.socialMediaLinks.isNotEmpty) {
      featureCards.add(_buildGridItem(context, localizations.socialMediaTitle, Icons.connect_without_contact, Routes.socialMedia, arguments: deity));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(deityName),
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
          padding: const EdgeInsets.all(8.0),
          child: Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            alignment: WrapAlignment.center,
            children: featureCards,
          ),
        ),
      ),
    );
  }

  String _getAboutTitle(AppLocalizations localizations, String key) {
    switch (key) {
      case 'aboutMaharajTitle':
        return localizations.aboutMaharajTitle;
      case 'aboutBabaTitle':
        return localizations.aboutBabaTitle;
      default:
        return localizations.aboutMaharajTitle; // Default fallback
    }
  }

  Widget _buildGridItem(BuildContext context, String title, dynamic icon, String route, {Object? arguments}) {
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
              onTap: () => Navigator.pushNamed(context, route, arguments: arguments),
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

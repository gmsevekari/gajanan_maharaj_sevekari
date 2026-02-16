import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/app_config.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:url_launcher/url_launcher.dart';

class DonationsScreen extends StatelessWidget {
  final DeityConfig deity;
  const DonationsScreen({super.key, required this.deity});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final qrCodeImagePath = isDarkMode
        ? deity.donationInfo!.qrCodeDark
        : deity.donationInfo!.qrCodeLight;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.donationsTitle),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              localizations.donationInstruction,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.orange).copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // QR code image
            Image.asset(
              qrCodeImagePath,
            ),
            const SizedBox(height: 40),
            Card(
              elevation: theme.cardTheme.elevation,
              shape: theme.cardTheme.shape,
              color: theme.cardTheme.color,
              margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
              child: InkWell(
                onTap: () => _launchZelle(context, localizations, deity.donationInfo!.zelleUrl),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          localizations.donateViaZelle,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 16.0),
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, color: theme.colorScheme.primary, size: 16.0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _launchZelle(BuildContext context, AppLocalizations localizations, String zelleUrl) async {
    if (await canLaunchUrl(Uri.parse(zelleUrl))) {
      await launchUrl(Uri.parse(zelleUrl));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.couldNotOpenZelle)),
      );
    }
  }
}

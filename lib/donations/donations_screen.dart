import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:url_launcher/url_launcher.dart';

class DonationsScreen extends StatelessWidget {
  const DonationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final qrCodeImagePath = isDarkMode
        ? 'resources/images/qr_code/Zelle_QR_Code_Dark.png'
        : 'resources/images/qr_code/Zelle_QR_Code_Light.png';

    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: Colors.orange[50],
      foregroundColor: Colors.orange[600], // Lighter text/icon color
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: Colors.orange.withAlpha(128), width: 1),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    );

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
            ElevatedButton(
              style: buttonStyle,
              onPressed: () => _launchZelle(context, localizations),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      localizations.donateViaZelle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16.0),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _launchZelle(BuildContext context, AppLocalizations localizations) async {
    const zelleUrl = 'https://tinyurl.com/Sea-GM-Zelle-Pay';
    if (await canLaunchUrl(Uri.parse(zelleUrl))) {
      await launchUrl(Uri.parse(zelleUrl));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.couldNotOpenZelle)),
      );
    }
  }
}

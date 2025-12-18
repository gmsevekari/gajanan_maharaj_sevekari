import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/utils/routes.dart';
import 'package:url_launcher/url_launcher.dart';

class DonationsScreen extends StatelessWidget {
  const DonationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: Colors.orange[50],
      foregroundColor: Colors.orange[600], // Lighter text/icon color
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: Colors.orange.withAlpha(128), width: 1),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.donationsTitle, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        actions: [
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
              style: Theme
                  .of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: Colors.orange)
                  .copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // QR code image
            Image.asset(
              'resources/images/qr_code/Zelle_QR_Code.png',
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              style: buttonStyle,
              onPressed: () => _launchZelle(context, localizations),
              child: Text(
                localizations.donateViaZelle,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _launchZelle(BuildContext context, AppLocalizations localizations) async {
    const zelleUrl = 'https://enroll.zellepay.com/qr-codes?data=eyJuYW1lIjoiU0FJQkFCQSBTRUFUVExFIiwiYWN0aW9uIjoicGF5bWVudCIsInRva2VuIjoiZ2FqYW5hbm1haGFyYWpzZWF0dGxlQGdtYWlsLmNvbSJ9';
    if (await canLaunchUrl(Uri.parse(zelleUrl))) {
      await launchUrl(Uri.parse(zelleUrl));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.couldNotOpenZelle)),
      );
    }
  }
}

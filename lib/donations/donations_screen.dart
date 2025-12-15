import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/utils/constants.dart';
import 'package:url_launcher/url_launcher.dart';

class DonationsScreen extends StatelessWidget {
  const DonationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(Constants.donationsTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(
              child: Text(
                'Zelle QR Code Placeholder',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            // Placeholder for QR code image
            Container(
              height: 200,
              width: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(child: Text('QR Code Here')),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => _launchZelle(context),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Donate via Zelle to gajananmaharajseattle@gmail.com',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _launchZelle(BuildContext context) async {
    const zelleUrl = 'mailto:gajananmaharajseattle@gmail.com'; // Zelle URLs can be complex; this is a simple mailto link.
    if (await canLaunchUrl(Uri.parse(zelleUrl))) {
      await launchUrl(Uri.parse(zelleUrl));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Zelle.')),
      );
    }
  }
}

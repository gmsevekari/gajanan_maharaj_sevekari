import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/utils/constants.dart';

class AboutMaharajScreen extends StatelessWidget {
  const AboutMaharajScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(Constants.aboutMaharajTitle),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'Comprehensive information and history about Gajanan Maharaj will be displayed here. The content is presented in large, legible Marathi text, designed for easy reading by elderly users.',
          style: TextStyle(fontSize: 18.0),
        ),
      ),
    );
  }
}

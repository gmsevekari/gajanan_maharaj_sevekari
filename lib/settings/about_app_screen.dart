import 'package:flutter/material.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About App'),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('App Version: 1.0.0', style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Text('Developed by: Studio', style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            Text(
              'This app is dedicated to the devotees of Shri Gajanan Maharaj.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

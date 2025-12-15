import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/parayan/parayan_progress_checklist_screen.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/parayan/parayan_type.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/utils/constants.dart';

class ParayanScreen extends StatelessWidget {
  const ParayanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(Constants.parayanTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Choose Parayan Type:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            _buildParayanTypeCard(context, '1-Day Parayan', ParayanType.oneDay),
            _buildParayanTypeCard(context, '3-Day Parayan', ParayanType.threeDay),
          ],
        ),
      ),
    );
  }

  Widget _buildParayanTypeCard(BuildContext context, String title, ParayanType parayanType) {
    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ParayanProgressChecklistScreen(parayanType: parayanType),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

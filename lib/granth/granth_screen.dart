import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/granth/granth_adhyay_detail_screen.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';

class GranthScreen extends StatelessWidget {
  const GranthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.granthTitle),
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
      body: ListView.builder(
        itemCount: 21,
        itemBuilder: (context, index) {
          final adhyayNumber = index + 1;
          return Card(
            elevation: theme.cardTheme.elevation,
            color: theme.cardTheme.color,
            shape: theme.cardTheme.shape,
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.orange[300],
                child: Text(
                  '$adhyayNumber',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text('${localizations.adhyay} $adhyayNumber', style: TextStyle(color: Colors.orange[600], fontWeight: FontWeight.bold)),
              trailing: Icon(Icons.arrow_forward_ios, color: theme.colorScheme.primary, size: 16.0),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GranthAdhyayDetailScreen(adhyayNumber: adhyayNumber),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

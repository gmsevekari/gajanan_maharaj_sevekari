import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';

class VaariDetailScreen extends StatelessWidget {
  final String eventId;
  final String? prefilledJoinCode;

  const VaariDetailScreen({
    super.key,
    required this.eventId,
    this.prefilledJoinCode,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(localizations.vaariTitle)),
      body: Center(
        child: Text(localizations.vaariDetailPlaceholder(eventId)),
      ),
    );
  }
}

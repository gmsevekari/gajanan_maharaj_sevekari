import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';

class VaariListScreen extends StatefulWidget {
  final String? groupId;
  final String? groupName;

  const VaariListScreen({super.key, this.groupId, this.groupName});

  @override
  State<VaariListScreen> createState() => _VaariListScreenState();
}

class _VaariListScreenState extends State<VaariListScreen> {
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName ?? localizations.vaariTitle),
      ),
      body: Center(
        child: Text('Vaari List Screen Placeholder for Group: ${widget.groupId}'),
      ),
    );
  }
}

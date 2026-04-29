import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/models/admin_user.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';

class AddGroupAdminScreen extends StatefulWidget {
  final AdminUser currentAdmin;

  const AddGroupAdminScreen({
    super.key,
    required this.currentAdmin,
  });

  @override
  State<AddGroupAdminScreen> createState() => _AddGroupAdminScreenState();
}

class _AddGroupAdminScreenState extends State<AddGroupAdminScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.addGroupAdminTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              Routes.home,
              (route) => false,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, Routes.settings),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Text('Form Fields Coming Soon')),
            ],
          ),
        ),
      ),
    );
  }
}

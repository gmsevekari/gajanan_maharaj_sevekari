import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/providers/jap_mala_provider.dart';

class ManualCountEntryDialog extends StatefulWidget {
  final JapMalaProvider provider;

  const ManualCountEntryDialog({super.key, required this.provider});

  @override
  State<ManualCountEntryDialog> createState() => _ManualCountEntryDialogState();
}

class _ManualCountEntryDialogState extends State<ManualCountEntryDialog> {
  final _malaController = TextEditingController();
  final _japController = TextEditingController();

  @override
  void dispose() {
    _malaController.dispose();
    _japController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(localizations.manualEntryLabel),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _malaController,
            decoration: InputDecoration(
              labelText: localizations.malas,
              hintText: '0',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.refresh),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _japController,
            decoration: InputDecoration(
              labelText: localizations.jap,
              hintText: '0',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.touch_app),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          Builder(
            builder: (context) {
              final malas = int.tryParse(_malaController.text) ?? 0;
              final extraJap = int.tryParse(_japController.text) ?? 0;
              final total = (malas * JapMalaProvider.countsPerMala) + extraJap;

              return Text(
                '${localizations.count}: $total',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              );
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(localizations.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            final malas = int.tryParse(_malaController.text) ?? 0;
            final extraJap = int.tryParse(_japController.text) ?? 0;
            if (malas > 0 || extraJap > 0) {
              widget.provider.addManualCount(malas, extraJap);
            }
            Navigator.pop(context);
          },
          child: Text(localizations.ok),
        ),
      ],
    );
  }
}

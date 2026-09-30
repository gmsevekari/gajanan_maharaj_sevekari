import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/admin/widgets/participant_contact_actions.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_entry.dart';

class AdminEntryEditDialog extends StatefulWidget {
  final SignupEntry? entry;
  final void Function(
    String name,
    String? phone,
    String? email,
    double? pledge,
    String? note,
  )
  onSave;
  final VoidCallback? onDelete;

  const AdminEntryEditDialog({
    super.key,
    this.entry,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<AdminEntryEditDialog> createState() => _AdminEntryEditDialogState();
}

class _AdminEntryEditDialogState extends State<AdminEntryEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _pledgeController;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    _nameController = TextEditingController(text: entry?.name ?? '');
    _phoneController = TextEditingController(text: entry?.phone ?? '');
    _emailController = TextEditingController(text: entry?.email ?? '');
    _pledgeController = TextEditingController(
      text: entry?.pledgeAmount != null
          ? _formatPledgeAmount(entry!.pledgeAmount!)
          : '',
    );
    _noteController = TextEditingController(text: entry?.note ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _pledgeController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim().isEmpty
        ? null
        : _phoneController.text.trim();
    final email = _emailController.text.trim().isEmpty
        ? null
        : _emailController.text.trim();
    final note = _noteController.text.trim().isEmpty
        ? null
        : _noteController.text.trim();
    final pledgeText = _pledgeController.text.trim();
    final pledge = pledgeText.isNotEmpty ? double.tryParse(pledgeText) : null;

    widget.onSave(name, phone, email, pledge, note);
    Navigator.of(context).pop();
  }

  void _confirmDelete(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l10n.signupSheetRemoveEntryTitle),
        content: Text(l10n.signupSheetRemoveEntryConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(l10n.no),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop(); // close confirm dialog
              Navigator.of(context).pop(); // close edit dialog
              widget.onDelete?.call();
            },
            child: Text(
              l10n.yes,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isEditing = widget.entry != null;

    return AlertDialog(
      title: Text(
        isEditing
            ? l10n.signupSheetEditEntryTitle
            : l10n.signupSheetAddEntryTitle,
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isEditing &&
                  widget.entry?.phone != null &&
                  widget.entry!.phone!.isNotEmpty) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.entry!.phone!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.appColors.secondaryText,
                        ),
                      ),
                    ),
                    ParticipantContactActions(
                      phone: widget.entry!.phone!,
                      textTooltip: l10n.sendTextTooltip,
                      whatsAppTooltip: l10n.whatsapp,
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),
              ],
              TextFormField(
                key: const Key('entryNameField'),
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.signupSheetEntryNameLabel,
                  border: const OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return l10n.signupSheetEntryNameRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('entryPhoneField'),
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: l10n.signupSheetEntryPhoneLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('entryEmailField'),
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: l10n.signupSheetEntryEmailLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('entryPledgeField'),
                controller: _pledgeController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l10n.signupSheetEntryPledgeLabel,
                  border: const OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return null;
                  final parsed = double.tryParse(val.trim());
                  if (parsed == null || parsed < 0) {
                    return l10n.signupSheetSlotSuggestedAmountInvalid;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('entryNoteField'),
                controller: _noteController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: l10n.signupSheetEntryNoteLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (isEditing && widget.onDelete != null)
          TextButton(
            onPressed: () => _confirmDelete(context, l10n),
            child: Text(
              l10n.signupSheetRemoveEntryTitle,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: _handleSave,
          child: Text(l10n.signupSheetSaveButton),
        ),
      ],
    );
  }
}

/// Formats a pledge amount for pre-filling the edit field: whole numbers
/// show without a trailing ".0" (e.g. 51.0 -> "51"), fractional amounts
/// are preserved as-is (e.g. 50.5 -> "50.5").
String _formatPledgeAmount(double amount) {
  return amount % 1 == 0 ? amount.toInt().toString() : amount.toString();
}

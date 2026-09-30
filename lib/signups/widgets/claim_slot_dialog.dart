import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';
import 'package:gajanan_maharaj_sevekari/providers/signup_service.dart';

/// Lets a devotee claim one [slot] on a sign-up sheet. Reuses
/// AddStepsDialog's confirm-before-submit pattern: validate, show what was
/// entered, require an explicit Yes, then submit. slot_full and
/// invalid-join-code are shown as a visible in-dialog message rather than a
/// silent failure - unlike a launch failure elsewhere in this app, this is
/// a user-initiated action with real stakes.
class ClaimSlotDialog extends StatefulWidget {
  final String sheetId;
  final SignupSlot slot;
  final bool requiresJoinCode;
  final String? deviceId;
  final SignupService signupService;

  const ClaimSlotDialog({
    super.key,
    required this.sheetId,
    required this.slot,
    required this.requiresJoinCode,
    required this.deviceId,
    required this.signupService,
  });

  @override
  State<ClaimSlotDialog> createState() => _ClaimSlotDialogState();
}

class _ClaimSlotDialogState extends State<ClaimSlotDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _pledgeController = TextEditingController();
  final _noteController = TextEditingController();
  final _joinCodeController = TextEditingController();

  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _pledgeController.dispose();
    _noteController.dispose();
    _joinCodeController.dispose();
    super.dispose();
  }

  Future<bool?> _showConfirmationDialog(AppLocalizations l10n) {
    final name = _nameController.text.trim();
    final label = widget.slot.labelEn.isNotEmpty
        ? widget.slot.labelEn
        : widget.slot.labelMr;

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.signupSheetClaimConfirmTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${l10n.signupSheetEntryNameLabel}: $name',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text(l10n.signupSheetClaimConfirmQuestion),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.no),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.yes),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    final confirmed = await _showConfirmationDialog(l10n);
    if (confirmed != true || !mounted) return;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final pledgeText = _pledgeController.text.trim();
    Map<String, dynamic> result;
    try {
      result = await widget.signupService.claimSlot(
        sheetId: widget.sheetId,
        slotId: widget.slot.id!,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        pledgeAmount: pledgeText.isEmpty ? null : double.tryParse(pledgeText),
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        deviceId: widget.deviceId,
        joinCode: widget.requiresJoinCode
            ? _joinCodeController.text.trim().toUpperCase()
            : null,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorText = l10n.signupSheetClaimError;
      });
      return;
    }

    if (!mounted) return;

    if (result['success'] == true) {
      Navigator.pop(context, true);
      return;
    }

    setState(() {
      _isLoading = false;
      _errorText = switch (result['error']) {
        'slot_full' => l10n.signupSheetSlotFullError,
        'invalid_join_code' => l10n.invalidJoinCode,
        _ => l10n.signupSheetClaimError,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final showPledge = widget.slot.suggestedAmount != null;

    return AlertDialog(
      title: Text(l10n.signupSheetClaimSlotTitle),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                key: const Key('claimNameField'),
                controller: _nameController,
                maxLength: 100,
                decoration: InputDecoration(
                  labelText: l10n.signupSheetEntryNameLabel,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.signupSheetEntryNameRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('claimPhoneField'),
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 30,
                decoration: InputDecoration(
                  labelText: l10n.signupSheetEntryPhoneLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('claimEmailField'),
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                maxLength: 200,
                decoration: InputDecoration(
                  labelText: l10n.signupSheetEntryEmailLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              if (showPledge) ...[
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('claimPledgeField'),
                  controller: _pledgeController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.signupSheetEntryPledgeLabel,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    final amount = double.tryParse(value.trim());
                    if (amount == null || amount < 0) {
                      return l10n.signupSheetSlotSuggestedAmountInvalid;
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('claimNoteField'),
                controller: _noteController,
                maxLines: 2,
                maxLength: 500,
                decoration: InputDecoration(
                  labelText: l10n.signupSheetEntryNoteLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              if (widget.requiresJoinCode) ...[
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('claimJoinCodeField'),
                  controller: _joinCodeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: l10n.joinCodeLabel,
                    hintText: l10n.joinCodeHint,
                    prefixIcon: const Icon(Icons.vpn_key_outlined),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.joinCodeHint;
                    }
                    return null;
                  },
                ),
              ],
              if (_errorText != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorText!,
                  style: TextStyle(color: theme.appColors.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSubmit,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.signupSheetSaveButton),
        ),
      ],
    );
  }
}

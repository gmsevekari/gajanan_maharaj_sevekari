import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/admin/widgets/participant_contact_actions.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_entry.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_entry_details.dart';
import 'package:gajanan_maharaj_sevekari/utils/entry_validators.dart';
import 'package:gajanan_maharaj_sevekari/utils/form_utils.dart';
import 'package:gajanan_maharaj_sevekari/utils/group_utils.dart';
import 'package:gajanan_maharaj_sevekari/utils/phone_utils.dart';
import 'package:gajanan_maharaj_sevekari/widgets/english_only.dart';
import 'package:gajanan_maharaj_sevekari/widgets/phone_number_field.dart';

/// Add or edit a sign-up entry's details (name, phone, email, pledge amount,
/// note). Used by admins on the Entries screen and by devotees on
/// [MySignupsScreen]; devotees pass `showContactActions: false`,
/// `requirePhone: true` and no `onDelete`.
///
/// [onSave] returns null once the details are saved, which closes the dialog,
/// or a message to show under the form, which keeps the dialog open with
/// everything typed so far so it can be corrected and saved again.
class SignupEntryEditDialog extends StatefulWidget {
  final SignupEntry? entry;
  final Future<String?> Function(SignupEntryDetails details) onSave;
  final VoidCallback? onDelete;

  /// Offers "Release Device Link" (after a confirmation): for an admin
  /// editing an entry that belongs to a device, so its devotee can claim it
  /// again from another one. Null leaves the action out.
  final VoidCallback? onReleaseDevice;

  /// Show the entry's phone with Text / WhatsApp buttons above the form.
  /// For admins reaching a devotee; off when devotees edit their own entry.
  final bool showContactActions;

  /// Require a phone number. Devotees can't clear theirs: claiming an entry
  /// later finds it by phone. Admins often add phoned-in entries without one.
  final bool requirePhone;

  /// Country code prefilled for a new number (and for an existing one saved
  /// without a code). The caller resolves it from the sign-up's group.
  final String? defaultCountryCode;

  const SignupEntryEditDialog({
    super.key,
    this.entry,
    required this.onSave,
    this.onDelete,
    this.onReleaseDevice,
    this.showContactActions = true,
    this.requirePhone = false,
    this.defaultCountryCode,
  });

  @override
  State<SignupEntryEditDialog> createState() => _SignupEntryEditDialogState();
}

class _SignupEntryEditDialogState extends State<SignupEntryEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _countryCodeController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _pledgeController;
  late final TextEditingController _noteController;
  bool _saving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    _nameController = TextEditingController(text: entry?.name ?? '');
    final phone = splitPhone(
      entry?.phone,
      widget.defaultCountryCode ?? GroupConstants.defaultCountryCode,
    );
    _countryCodeController = TextEditingController(text: phone.code);
    _phoneController = TextEditingController(text: phone.number);
    _emailController = TextEditingController(text: entry?.email ?? '');
    _pledgeController = TextEditingController(
      text: entry?.pledgeAmount != null
          ? formatPledgeAmount(entry!.pledgeAmount!)
          : '',
    );
    _noteController = TextEditingController(text: entry?.note ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _countryCodeController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _pledgeController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String? _textOrNull(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : text;
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      revealFirstInvalidField(_formKey.currentContext);
      return;
    }

    final pledgeText = _pledgeController.text.trim();
    final details = SignupEntryDetails(
      name: _nameController.text.trim(),
      phone: joinPhone(_countryCodeController.text, _phoneController.text),
      email: _textOrNull(_emailController),
      pledgeAmount: pledgeText.isEmpty ? null : parsePledgeAmount(pledgeText),
      note: _textOrNull(_noteController),
    );

    setState(() {
      _saving = true;
      _saveError = null;
    });
    final error = await widget.onSave(details);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _saving = false;
      _saveError = error;
    });
  }

  void _confirmRelease(BuildContext context, AppLocalizations l10n) {
    showEnglishDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l10n.signupReleaseDeviceConfirmTitle),
        content: Text(l10n.signupReleaseDeviceConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(l10n.no),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop(); // close confirm dialog
              Navigator.of(context).pop(); // close edit dialog
              widget.onReleaseDevice?.call();
            },
            child: Text(l10n.yes),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, AppLocalizations l10n) {
    showEnglishDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l10n.signupRemoveEntryTitle),
        content: Text(l10n.signupRemoveEntryConfirm),
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

  /// Field styling with the maxLength counter hidden: the limit is still
  /// enforced, and a stacked form fits above the keyboard on a phone.
  InputDecoration _decoration(String label) => InputDecoration(
    labelText: label,
    counterText: '',
    border: const OutlineInputBorder(),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isEditing = widget.entry != null;

    return AlertDialog(
      title: Text(
        isEditing ? l10n.signupEditEntryTitle : l10n.signupAddEntryTitle,
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.showContactActions &&
                  isEditing &&
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
                maxLength: SignupEntry.maxNameLength,
                decoration: _decoration(l10n.signupEntryNameLabel),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return l10n.signupEntryNameRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              PhoneNumberField(
                codeKey: const Key('entryCountryCodeField'),
                numberKey: const Key('entryPhoneField'),
                codeController: _countryCodeController,
                numberController: _phoneController,
                label: l10n.signupEntryPhoneLabel,
                required: widget.requirePhone,
                requiredMessage: l10n.phoneRequired,
                invalidMessage: l10n.invalidPhoneError,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('entryEmailField'),
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                maxLength: SignupEntry.maxEmailLength,
                decoration: _decoration(l10n.signupEntryEmailLabel),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return null;
                  return isValidEmail(val) ? null : l10n.invalidEmail;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('entryPledgeField'),
                controller: _pledgeController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: _decoration(l10n.signupEntryPledgeLabel),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return null;
                  return parsePledgeAmount(val) == null
                      ? l10n.signupSlotSuggestedAmountInvalid
                      : null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('entryNoteField'),
                controller: _noteController,
                maxLines: 2,
                maxLength: SignupEntry.maxNoteLength,
                decoration: _decoration(l10n.signupEntryNoteLabel),
              ),
              if (widget.onReleaseDevice != null) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: _saving
                        ? null
                        : () => _confirmRelease(context, l10n),
                    icon: const Icon(Icons.link_off),
                    label: Text(l10n.signupReleaseDeviceButton),
                  ),
                ),
              ],
              if (_saveError != null) ...[
                const SizedBox(height: 12),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    _saveError!,
                    key: const Key('entrySaveError'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        if (isEditing && widget.onDelete != null)
          TextButton(
            onPressed: _saving ? null : () => _confirmDelete(context, l10n),
            child: Text(
              l10n.signupRemoveEntryTitle,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _handleSave,
          child: Text(l10n.signupSaveButton),
        ),
      ],
    );
  }
}

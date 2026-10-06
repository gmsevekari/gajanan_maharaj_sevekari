import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/claim_entries_result.dart';
import 'package:gajanan_maharaj_sevekari/providers/signup_service.dart';
import 'package:gajanan_maharaj_sevekari/utils/form_utils.dart';
import 'package:gajanan_maharaj_sevekari/utils/group_utils.dart';
import 'package:gajanan_maharaj_sevekari/utils/phone_utils.dart';
import 'package:gajanan_maharaj_sevekari/widgets/phone_number_field.dart';

/// "Claim my sign up": a devotee types the phone number they signed up with
/// (and the join code, when the sign-up needs one) and every entry made with
/// that number is linked to this device, like Find My Adhyays in Parayan.
///
/// Closes with `true` when entries were linked. Anything else - no entry for
/// that number, an entry another device already holds, a wrong join code, a
/// failed call - is shown under the form with what was typed kept, and
/// nothing is changed.
class ClaimMySignupDialog extends StatefulWidget {
  final String signupId;
  final String deviceId;
  final bool requiresJoinCode;
  final SignupService signupService;

  /// Country code the number starts with; the caller resolves it from the
  /// sign-up's group.
  final String? defaultCountryCode;

  const ClaimMySignupDialog({
    super.key,
    required this.signupId,
    required this.deviceId,
    required this.requiresJoinCode,
    required this.signupService,
    this.defaultCountryCode,
  });

  @override
  State<ClaimMySignupDialog> createState() => _ClaimMySignupDialogState();
}

class _ClaimMySignupDialogState extends State<ClaimMySignupDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _countryCodeController;
  final _phoneController = TextEditingController();
  final _joinCodeController = TextEditingController();

  bool _isLoading = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _countryCodeController = TextEditingController(
      text: widget.defaultCountryCode ?? GroupConstants.defaultCountryCode,
    );
  }

  @override
  void dispose() {
    _countryCodeController.dispose();
    _phoneController.dispose();
    _joinCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) {
      revealFirstInvalidField(_formKey.currentContext);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    String? error;
    try {
      final result = await widget.signupService.claimMyEntries(
        signupId: widget.signupId,
        phone: joinPhone(_countryCodeController.text, _phoneController.text)!,
        deviceId: widget.deviceId,
        joinCode: widget.requiresJoinCode
            ? _joinCodeController.text.trim().toUpperCase()
            : null,
      );
      if (!mounted) return;
      if (result.status == ClaimEntriesStatus.success) {
        Navigator.pop(context, true);
        return;
      }
      error = switch (result.status) {
        ClaimEntriesStatus.notFound => l10n.signupClaimMySignupNotFound,
        ClaimEntriesStatus.alreadyClaimed =>
          l10n.signupClaimMySignupAlreadyClaimed,
        ClaimEntriesStatus.invalidJoinCode => l10n.invalidJoinCode,
        ClaimEntriesStatus.success => null,
      };
    } catch (exception) {
      debugPrint('ClaimMySignupDialog claim failed: $exception');
      if (!mounted) return;
      error = l10n.signupClaimMySignupError;
    }

    setState(() {
      _isLoading = false;
      _errorText = error;
    });
  }

  /// Compact field styling: dense, with the maxLength counter hidden.
  InputDecoration _decoration(
    String label, {
    String? hint,
    Widget? prefixIcon,
  }) => InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: prefixIcon,
    isDense: true,
    counterText: '',
    border: const OutlineInputBorder(),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(l10n.signupClaimMySignupButton),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.signupClaimMySignupHint,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.appColors.secondaryText,
                ),
              ),
              const SizedBox(height: 12),
              PhoneNumberField(
                codeKey: const Key('claimMyCountryCodeField'),
                numberKey: const Key('claimMyPhoneField'),
                codeController: _countryCodeController,
                numberController: _phoneController,
                label: l10n.phoneNumberHint,
                requiredMessage: l10n.phoneRequired,
                invalidMessage: l10n.invalidPhoneError,
              ),
              if (widget.requiresJoinCode) ...[
                const SizedBox(height: 8),
                TextFormField(
                  key: const Key('claimMyJoinCodeField'),
                  controller: _joinCodeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: _decoration(
                    l10n.joinCodeLabel,
                    hint: l10n.joinCodeHint,
                    prefixIcon: const Icon(Icons.vpn_key_outlined),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? l10n.joinCodeHint
                      : null,
                ),
              ],
              if (_errorText != null) ...[
                const SizedBox(height: 12),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    _errorText!,
                    style: TextStyle(color: theme.appColors.error),
                  ),
                ),
              ],
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Center(child: CircularProgressIndicator()),
                ),
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
          child: Text(l10n.submitLabel),
        ),
      ],
    );
  }
}

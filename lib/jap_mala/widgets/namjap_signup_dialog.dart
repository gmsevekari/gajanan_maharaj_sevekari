import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/models/group_namjap_event.dart';
import 'package:gajanan_maharaj_sevekari/providers/group_namjap_provider.dart';
import 'package:gajanan_maharaj_sevekari/utils/unique_id_service.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/utils/group_utils.dart';

class NamjapSignupDialog extends StatefulWidget {
  final GroupNamjapEvent event;
  final bool isEdit;
  final String? prefilledJoinCode;

  const NamjapSignupDialog({
    super.key,
    required this.event,
    this.isEdit = false,
    this.prefilledJoinCode,
  });

  @override
  State<NamjapSignupDialog> createState() => _NamjapSignupDialogState();
}

class _NamjapSignupDialogState extends State<NamjapSignupDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _countryCodeController = TextEditingController(text: '+91');
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<GroupNamjapProvider>();

    // Set default based on groupId
    final defaultCode = GroupUtils.getDefaultCountryCode(widget.event.groupId);
    _countryCodeController.text = defaultCode;

    if (provider.hasProfile) {
      _nameController.text = provider.memberName ?? '';

      final fullPhone = provider.phone ?? '';
      final countryCodes = ['+91', '+1', '+44', '+61', '+971'];
      for (var code in countryCodes) {
        if (fullPhone.startsWith(code)) {
          _countryCodeController.text = code;
          _phoneController.text = fullPhone.substring(code.length);
          break;
        }
      }
      if (_phoneController.text.isEmpty && fullPhone.isNotEmpty) {
        _phoneController.text = fullPhone;
      }
    }

    if (widget.prefilledJoinCode != null) {
      _codeController.text = widget.prefilledJoinCode!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _countryCodeController.dispose();
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final provider = context.read<GroupNamjapProvider>();
      final deviceId = await UniqueIdService.getUniqueId();

      final newName = _nameController.text.trim();
      final oldName = provider.memberName;

      // If updating and name changed, delete the old record first
      if (widget.isEdit && oldName != null && oldName != newName) {
        await provider.deleteSignUp(widget.event.id, deviceId);
      }

      final success = await provider.signUp(
        eventId: widget.event.id,
        joinCode: widget.isEdit
            ? widget.event.joinCode
            : _codeController.text.trim(),
        memberName: newName,
        phone:
            '${_countryCodeController.text.trim()}${_phoneController.text.trim()}',
        deviceId: deviceId,
      );

      if (mounted) {
        if (success) {
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.invalidJoinCode),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleDelete() async {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.deleteSignupConfirmTitle),
        content: Text(localizations.deleteSignupConfirmMessageNamjap),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(localizations.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: theme.appColors.error),
            child: Text(localizations.deleteSignupLabel),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final provider = context.read<GroupNamjapProvider>();
      final deviceId = await UniqueIdService.getUniqueId();

      await provider.deleteSignUp(widget.event.id, deviceId);
      if (mounted) {
        Navigator.pop(context, {'deleted': true});
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(
        widget.isEdit ? localizations.editLabel : localizations.signUp,
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: localizations.memberName,
                  hintText: 'e.g. Rahul Patil',
                ),
                validator: (value) => (value == null || value.isEmpty)
                    ? localizations.fieldRequired
                    : null,
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 70,
                    child: TextFormField(
                      controller: _countryCodeController,
                      decoration: const InputDecoration(
                        labelText: 'Code',
                        hintText: '+91',
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) =>
                          (value == null || !value.startsWith('+'))
                          ? '!'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: localizations.phone,
                        hintText: '10-digit number',
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return localizations.fieldRequired;
                        }

                        final code = _countryCodeController.text.trim();
                        int minLength = 10;

                        if (code == '+65') {
                          minLength = 8;
                        } else if (code == '+27' || code == '+971') {
                          minLength = 9;
                        }

                        // Strip non-digits just in case user added spaces
                        final digitCount = value
                            .replaceAll(RegExp(r'\D'), '')
                            .length;

                        if (digitCount < minLength) {
                          return localizations.invalidPhone;
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              if (!widget.isEdit) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _codeController,
                  decoration: InputDecoration(
                    labelText: localizations.joinCodeLabel,
                    hintText: 'Enter 6-character code',
                  ),
                  textCapitalization: TextCapitalization.characters,
                  keyboardType: TextInputType.text,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return localizations.fieldRequired;
                    }
                    if (value.trim().length != 6) {
                      return 'Code must be 6 characters';
                    }
                    return null;
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        if (widget.isEdit)
          TextButton(
            onPressed: _isLoading ? null : _handleDelete,
            style: TextButton.styleFrom(foregroundColor: theme.appColors.error),
            child: Text(localizations.deleteSignupLabel),
          ),
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text(localizations.cancel),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSignUp,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  widget.isEdit
                      ? localizations.updateLabel
                      : localizations.submitLabel,
                ),
        ),
      ],
    );
  }
}

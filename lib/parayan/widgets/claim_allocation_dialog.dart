import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/providers/parayan_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gajanan_maharaj_sevekari/notifications/notification_constants.dart';
import 'package:gajanan_maharaj_sevekari/utils/notification_service_helper.dart';
import 'package:gajanan_maharaj_sevekari/utils/group_utils.dart';

class ClaimAllocationDialog extends StatefulWidget {
  final String eventId;
  final String deviceId;
  final int daysCount;
  final ParayanService parayanService;
  final String? groupId;
  final String? expectedJoinCode;

  const ClaimAllocationDialog({
    super.key,
    required this.eventId,
    required this.deviceId,
    required this.daysCount,
    required this.parayanService,
    this.groupId,
    this.expectedJoinCode,
  });

  @override
  State<ClaimAllocationDialog> createState() => _ClaimAllocationDialogState();
}

class _ClaimAllocationDialogState extends State<ClaimAllocationDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _countryCodeController;
  final _phoneController = TextEditingController();
  final _joinCodeController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final defaultCode = GroupUtils.getDefaultCountryCode(widget.groupId);
    _countryCodeController = TextEditingController(text: defaultCode);
  }

  @override
  void dispose() {
    _countryCodeController.dispose();
    _phoneController.dispose();
    _joinCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleClaim({bool overwrite = false}) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final fullPhone =
        '${_countryCodeController.text.trim()}${_phoneController.text.trim()}';

    // Validate Join Code if applicable
    if (widget.groupId == GroupConstants.seattle) {
      final enteredCode = _joinCodeController.text.trim();
      if (enteredCode != widget.expectedJoinCode) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.invalidJoinCode),
            ),
          );
        }
        return;
      }
    }

    try {
      final result = await widget.parayanService.claimAllocation(
        eventId: widget.eventId,
        phone: fullPhone,
        deviceId: widget.deviceId,
        overwrite: overwrite,
      );

      final status = result['status'];

      if (!mounted) return;

      if (status == 'SUCCESS') {
        final localizations = AppLocalizations.of(context)!;

        // Subscribe to topics
        final prefs = await SharedPreferences.getInstance();
        final parayanRemindersEnabled =
            prefs.getBool(NotificationConstants.parayanRemindersPrefKey) ??
            true;

        if (parayanRemindersEnabled) {
          final List<String> topics = [];
          for (int i = 1; i <= widget.daysCount; i++) {
            topics.add(
              NotificationConstants.getParayanReminderTopic(widget.eventId, i),
            );
          }
          await NotificationServiceHelper.addPendingSubscriptions(topics);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(localizations.claimSuccessMessage)),
          );
          Navigator.pop(context, true);
        }
      } else if (status == 'CONFLICT') {
        _showConflictDialog(fullPhone);
      } else if (status == 'NOT_FOUND') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.noAllocationFound),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showConflictDialog(String phone) {
    final localizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.alreadyLinkedPrompt),
        content: Text(phone),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.no),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close confirm dialog
              _handleClaim(overwrite: true); // Retry with overwrite
            },
            child: Text(localizations.yes),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(localizations.findMyAllocationLabel),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                        (value == null || !value.startsWith('+')) ? '!' : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: localizations.phoneNumberHint,
                      hintText: '1234567890',
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return localizations.invalidPhoneError;
                      }

                      // Strip non-digits to count actual numbers
                      final digitCount = value.replaceAll(RegExp(r'\D'), '').length;

                      // Global minimum length of 8 digits for all countries
                      if (digitCount < 8) {
                        return localizations.invalidPhoneError;
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            if (widget.groupId == GroupConstants.seattle) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _joinCodeController,
                decoration: InputDecoration(
                  labelText: localizations.joinCodeLabel,
                  hintText: localizations.joinCodeHint,
                  prefixIcon: const Icon(Icons.vpn_key_outlined),
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return localizations.joinCodeHint;
                  }
                  if (value.trim() != widget.expectedJoinCode) {
                    return localizations.invalidJoinCode;
                  }
                  return null;
                },
              ),
            ],
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 16.0),
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text(localizations.cancel),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : () => _handleClaim(),
          child: Text(localizations.submitLabel),
        ),
      ],
    );
  }
}

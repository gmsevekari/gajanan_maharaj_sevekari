import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/parayan_event.dart';
import 'package:gajanan_maharaj_sevekari/models/parayan_participant.dart';
import 'package:gajanan_maharaj_sevekari/providers/parayan_service.dart';
import 'package:gajanan_maharaj_sevekari/notifications/notification_constants.dart';
import 'package:gajanan_maharaj_sevekari/utils/unique_id_service.dart';
import 'package:gajanan_maharaj_sevekari/parayan/parayan_type.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gajanan_maharaj_sevekari/utils/notification_service_helper.dart';

class ParayanSignupScreen extends StatefulWidget {
  final ParayanEvent event;
  final ParayanHousehold? existingEnrollment;

  const ParayanSignupScreen({
    super.key,
    required this.event,
    this.existingEnrollment,
  });

  @override
  State<ParayanSignupScreen> createState() => _ParayanSignupScreenState();
}

class _ParayanSignupScreenState extends State<ParayanSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _parayanService = ParayanService();

  final List<TextEditingController> _nameControllers = [
    TextEditingController(),
  ];
  final _phoneController = TextEditingController();
  String _selectedCountryCode = '+1';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingEnrollment != null) {
      final household = widget.existingEnrollment!;
      _nameControllers.clear();
      for (var member in household.members.values) {
        _nameControllers.add(TextEditingController(text: member.name));
      }
      if (_nameControllers.isEmpty) {
        _nameControllers.add(TextEditingController());
      }

      // Attempt to split country code from phone
      var rawPhone = household.phone;
      final countryCodes = ['+91', '+1', '+44', '+61', '+971'];
      for (var code in countryCodes) {
        if (rawPhone.startsWith(code)) {
          _selectedCountryCode = code;
          rawPhone = rawPhone.substring(code.length).trim();
          break;
        }
      }
      _phoneController.text = rawPhone;
    }
  }

  @override
  void dispose() {
    for (var controller in _nameControllers) {
      controller.dispose();
    }
    _phoneController.dispose();
    super.dispose();
  }

  void _addNameField() {
    if (_nameControllers.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Localizations.localeOf(context).languageCode == 'mr'
                ? "एका घरात जास्तीत जास्त ५ सदस्य असू शकतात"
                : "Maximum 5 members allowed per household",
          ),
        ),
      );
      return;
    }
    setState(() {
      _nameControllers.add(TextEditingController());
    });
  }

  void _removeNameField(int index) {
    if (_nameControllers.length > 1) {
      setState(() {
        _nameControllers[index].dispose();
        _nameControllers.removeAt(index);
      });
    }
  }

  Future<void> _submit() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final deviceId = await UniqueIdService.getUniqueId();

      final names = _nameControllers
          .map((c) => c.text.trim())
          .where((name) => name.isNotEmpty)
          .toList();

      if (names.isEmpty) {
        throw Exception("Please enter at least one name");
      }

      await _parayanService.enrollParticipants(
        eventId: widget.event.id,
        type: widget.event.type,
        deviceId: deviceId,
        names: names,
        phone: '$_selectedCountryCode ${_phoneController.text.trim()}',
      );

      // Subscribe to topics in the background via NotificationServiceHelper
      SharedPreferences.getInstance().then((prefs) {
        final parayanRemindersEnabled =
            prefs.getBool(NotificationConstants.parayanRemindersPrefKey) ?? true;
        if (parayanRemindersEnabled) {
          final List<String> topics = [];
          if (widget.event.type == ParayanType.oneDay ||
              widget.event.type == ParayanType.guruPushya) {
            topics.add(NotificationConstants.getParayanReminderTopic(
              widget.event.id,
              1,
            ));
          } else {
            topics.add(NotificationConstants.getParayanReminderTopic(widget.event.id, 1));
            topics.add(NotificationConstants.getParayanReminderTopic(widget.event.id, 2));
            topics.add(NotificationConstants.getParayanReminderTopic(widget.event.id, 3));
          }
          NotificationServiceHelper.addPendingSubscriptions(topics);
        }
      });

      if (!mounted) return;

      // Navigate to confirmation
      Navigator.pop(context, true);
      final localizations = AppLocalizations.of(context);
      if (localizations != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.parayanJoinedSuccess)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (localizations == null) return const SizedBox.shrink();

    final isMarathi = localizations.localeName == 'mr';

    final isEditMode = widget.existingEnrollment != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditMode
              ? localizations.editEnrollmentLabel
              : localizations.joinParayanLabel,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    isMarathi ? widget.event.titleMr : widget.event.titleEn,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isMarathi
                        ? widget.event.descriptionMr
                        : widget.event.descriptionEn,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Household Members Header
                  Row(
                    children: [
                      Text(
                        isMarathi ? "कुटुंबातील सदस्य" : "Household Members",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (_nameControllers.length < 5)
                        TextButton.icon(
                          onPressed: _addNameField,
                          icon: const Icon(Icons.add_circle_outline),
                          label: Text(isMarathi ? "जोडा" : "Add"),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Name fields
                  ..._nameControllers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final controller = entry.value;
                    final isExistingMember =
                        widget.existingEnrollment != null &&
                        index < widget.existingEnrollment!.members.length;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: controller,
                              enabled: !isExistingMember,
                              decoration: InputDecoration(
                                labelText: "${localizations.name} ${index + 1}",
                                icon: Icon(
                                  Icons.person,
                                  color: isExistingMember
                                      ? theme.hintColor
                                      : theme.colorScheme.primary,
                                ),
                                filled: isExistingMember,
                                fillColor: isExistingMember
                                    ? theme.disabledColor.withValues(alpha: 0.05)
                                    : null,
                              ),
                              style: isExistingMember
                                  ? TextStyle(color: theme.hintColor)
                                  : null,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return localizations.parayanNameRequired;
                                }
                                // Duplicate name check within household
                                final otherNames = _nameControllers
                                    .where((c) => c != controller)
                                    .map((c) => c.text.trim().toLowerCase())
                                    .toList();
                                if (otherNames.contains(
                                  value.trim().toLowerCase(),
                                )) {
                                  return isMarathi
                                      ? "हे नाव आधीच वापरले आहे"
                                      : "Duplicate name within household";
                                }
                                return null;
                              },
                            ),
                          ),
                          if (_nameControllers.length > 1 && !isExistingMember)
                            IconButton(
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                color: Colors.red,
                              ),
                              onPressed: () => _removeNameField(index),
                              padding: const EdgeInsets.only(top: 12),
                            ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 24),
                  Divider(color: Colors.grey.withValues(alpha: 0.2)),
                  const SizedBox(height: 24),

                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: isMarathi ? "फोन नंबर" : "Phone Number",
                      icon: const Icon(Icons.phone),
                      hintText: isMarathi ? "१०-अंकी नंबर" : "10-digit number",
                      prefixIcon: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCountryCode,
                            items: ['+91', '+1', '+44', '+61', '+971'].map((
                              String value,
                            ) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedCountryCode = newValue;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return localizations.phoneRequired;
                      }
                      final phoneRegex = RegExp(r'^[0-9]{10}$');
                      if (!phoneRegex.hasMatch(
                        value.trim().replaceAll(RegExp(r'[\s\-\(\)]'), ''),
                      )) {
                        return localizations.invalidPhone;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      isEditMode
                          ? localizations.updateEnrollmentLabel
                          : localizations.joinParayanLabel,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

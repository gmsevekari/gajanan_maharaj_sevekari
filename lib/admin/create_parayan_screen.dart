import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gajanan_maharaj_sevekari/admin/admin_audit_service.dart';
import 'package:gajanan_maharaj_sevekari/admin/parayan_admin_detail_screen.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/admin_user.dart';
import 'package:gajanan_maharaj_sevekari/models/parayan_event.dart';
import 'package:gajanan_maharaj_sevekari/parayan/parayan_type.dart';
import 'package:gajanan_maharaj_sevekari/providers/parayan_service.dart';
import 'package:intl/intl.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:uuid/uuid.dart';

class CreateParayanScreen extends StatefulWidget {
  final AdminUser? adminUser;

  const CreateParayanScreen({super.key, this.adminUser});

  @override
  State<CreateParayanScreen> createState() => _CreateParayanScreenState();
}

class _CreateParayanScreenState extends State<CreateParayanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _parayanService = ParayanService();

  final _titleEnController = TextEditingController();
  final _titleMrController = TextEditingController();
  final _descriptionEnController = TextEditingController();
  final _descriptionMrController = TextEditingController();
  ParayanType _selectedType = ParayanType.oneDay;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  bool _isEndDateSetManually = false;
  String? _selectedGroupId;
  String _selectedTimezone = 'America/Los_Angeles';

  final List<Map<String, String>> _timezones = [
    {'label': 'Seattle (Pacific Time)', 'value': 'America/Los_Angeles'},
    {'label': 'India (IST)', 'value': 'Asia/Kolkata'},
  ];

  bool _isLoading = false;

  @override
  void dispose() {
    _titleEnController.dispose();
    _titleMrController.dispose();
    _descriptionEnController.dispose();
    _descriptionMrController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime(BuildContext context, bool isStartDate) async {
    final initialDate = isStartDate ? _startDate : _endDate;
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (pickedDate == null) return;

    if (!mounted) return;
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );

    if (pickedTime != null) {
      setState(() {
        final newDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        if (isStartDate) {
          _startDate = newDateTime;
          if (_selectedType == ParayanType.threeDay) {
            final targetEnd = _startDate.add(const Duration(days: 2));
            _endDate = DateTime(
              targetEnd.year,
              targetEnd.month,
              targetEnd.day,
              23,
              59,
              59,
            );
          } else if (_selectedType == ParayanType.oneDay) {
            _endDate = DateTime(
              _startDate.year,
              _startDate.month,
              _startDate.day,
              23,
              59,
              59,
            );
          }
        } else {
          _endDate = newDateTime;
          _isEndDateSetManually = true;
        }
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_selectedType == ParayanType.threeDay) {
            final targetEnd = _startDate.add(const Duration(days: 2));
            _endDate = DateTime(
              targetEnd.year,
              targetEnd.month,
              targetEnd.day,
              23,
              59,
              59,
            );
          } else if (_selectedType == ParayanType.oneDay) {
            _endDate = DateTime(
              _startDate.year,
              _startDate.month,
              _startDate.day,
              23,
              59,
              59,
            );
          }
        } else {
          _endDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            23,
            59,
            59,
          );
          _isEndDateSetManually = true;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Guru Pushya mandatory end date validation
    if (_selectedType == ParayanType.guruPushya && !_isEndDateSetManually) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.guruPushyaEndDateRequired,
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final localizations = AppLocalizations.of(context)!;

    setState(() {
      _isLoading = true;
    });

    try {
      // Fixed reminder times: 1 PM, 4 PM, 7 PM
      final List<String> formattedTimes = ["13:00", "16:00", "19:00"];

      if (_selectedGroupId == null) {
        throw Exception("Group ID is required to create a Parayan event.");
      }
      final String groupId = _selectedGroupId!;
      final String dateStr = DateFormat('yyyy-MM-dd').format(_startDate);
      final String eventId = "${groupId}-${dateStr}-${_selectedType.name}";

      // Check for duplicate
      final bool alreadyExists = await _parayanService.exists(eventId);
      if (alreadyExists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.parayanAlreadyExists),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final event = ParayanEvent(
        id: eventId,
        titleEn: _titleEnController.text.trim(),
        titleMr: _titleMrController.text.trim(),
        descriptionEn: _descriptionEnController.text.trim(),
        descriptionMr: _descriptionMrController.text.trim(),
        type: _selectedType,
        startDate: _startDate,
        endDate: _endDate,
        status: 'upcoming',
        reminderTimes: formattedTimes,
        createdAt: DateTime.now(),
        sentReminders: const {},
        joinCode: const Uuid().v4().substring(0, 6).toUpperCase(),
        groupId: groupId,
        timezone: _selectedTimezone,
      );

      await _parayanService.createEvent(event);
      await AdminAuditService.logAction(
        action: 'CREATE_PARAYAN_EVENT',
        details: {
          'event_id': event.id,
          'title_en': event.titleEn,
          'title_mr': event.titleMr,
          'type': event.type.toString(),
          'start_date': event.startDate.toIso8601String(),
        },
      );
      if (!mounted) return;

      final isMarathi = Localizations.localeOf(context).languageCode == 'mr';
      final eventTitle = isMarathi ? event.titleMr : event.titleEn;

      // Navigate to detail screen and show snackbar
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ParayanAdminDetailScreen(event: event),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "${isMarathi ? 'पारायण " $eventTitle " यशस्वीरीत्या तयार केले आहे.' : 'Parayan " $eventTitle " has been created successfully.'}",
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Alphanumeric + spaces + Marathi (Devanagari) characters
    final List<TextInputFormatter> alphanumericFormatter = [
      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9 \u0900-\u097F]')),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(localizations.createParayanTitle)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildGroupSelection(localizations, theme),
                  const SizedBox(height: 16),
                  // --- Status (Label) ---
                  Row(
                    children: [
                      Text(
                        "${localizations.statusLabel}: ",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          localizations.statusUpcoming,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // --- English Details ---
                  Text(
                    localizations.englishDetailsHeader,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _titleEnController,
                    inputFormatters: alphanumericFormatter,
                    decoration: InputDecoration(
                      labelText: localizations.parayanNameLabel,
                      hintText: localizations.parayanNameHint,
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? localizations.parayanNameRequired
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionEnController,
                    inputFormatters: alphanumericFormatter,
                    decoration: InputDecoration(
                      labelText: localizations.parayanDescriptionLabel,
                      hintText: localizations.parayanDescriptionHint,
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),

                  // --- Marathi Details ---
                  Text(
                    localizations.marathiDetailsHeader,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _titleMrController,
                    // Note: Marathi characters are not in a-zA-Z0-9 space,
                    // but user requested "alphanumeric characters and spaces" ONLY.
                    // Strictly following that for Marathi field too as requested.
                    inputFormatters: alphanumericFormatter,
                    decoration: InputDecoration(
                      labelText: localizations.parayanNameMrLabel,
                      hintText: localizations.parayanNameMrHint,
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? localizations.parayanNameMrRequired
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionMrController,
                    inputFormatters: alphanumericFormatter,
                    decoration: InputDecoration(
                      labelText: localizations.parayanDescriptionMrLabel,
                      hintText: localizations.parayanDescriptionMrHint,
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),

                  const Divider(),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<ParayanType>(
                    value: _selectedType,
                    decoration: InputDecoration(
                      labelText: localizations.parayanTypeLabel,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: ParayanType.oneDay,
                        child: Text(localizations.oneDayParayan),
                      ),
                      DropdownMenuItem(
                        value: ParayanType.threeDay,
                        child: Text(localizations.threeDayParayan),
                      ),
                      DropdownMenuItem(
                        value: ParayanType.guruPushya,
                        child: Text(localizations.guruPushyaParayan),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedType = value;
                          if (_selectedType == ParayanType.threeDay) {
                            final targetEnd = _startDate.add(
                              const Duration(days: 2),
                            );
                            _endDate = DateTime(
                              targetEnd.year,
                              targetEnd.month,
                              targetEnd.day,
                              23,
                              59,
                              59,
                            );
                          } else if (_selectedType == ParayanType.oneDay) {
                            _endDate = DateTime(
                              _startDate.year,
                              _startDate.month,
                              _startDate.day,
                              23,
                              59,
                              59,
                            );
                          } else if (_selectedType == ParayanType.guruPushya) {
                            _isEndDateSetManually = false;
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: _selectedTimezone,
                    decoration: const InputDecoration(labelText: 'Timezone'),
                    items: _timezones.map((tz) {
                      return DropdownMenuItem(
                        value: tz['value'],
                        child: Text(tz['label']!),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedTimezone = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  if (_selectedType == ParayanType.oneDay)
                    ListTile(
                      title: Text(localizations.parayanDateLabel),
                      subtitle: Text(
                        DateFormat('MMM d, yyyy').format(_startDate),
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectDate(context, true),
                    )
                  else ...[
                    ListTile(
                      title: Text(localizations.startDateLabel),
                      subtitle: Text(
                        _selectedType == ParayanType.guruPushya
                            ? DateFormat(
                                'MMM d, yyyy - hh:mm a',
                              ).format(_startDate)
                            : DateFormat('MMM d, yyyy').format(_startDate),
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectedType == ParayanType.guruPushya
                          ? _selectDateTime(context, true)
                          : _selectDate(context, true),
                    ),
                    if (_selectedType == ParayanType.threeDay)
                      ListTile(
                        title: Text(localizations.endDateLabel),
                        subtitle: Text(
                          DateFormat('MMM d, yyyy').format(_endDate),
                        ),
                        enabled: false,
                      )
                    else // guruPushya
                      ListTile(
                        title: Text(localizations.endDateLabel),
                        subtitle: Text(
                          DateFormat('MMM d, yyyy - hh:mm a').format(_endDate),
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () => _selectDateTime(context, false),
                      ),
                  ],

                  const SizedBox(height: 24),

                  // --- Fixed Reminders Label ---
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.appColors.primarySwatch.withValues(
                        alpha: 0.05,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.appColors.primarySwatch.withValues(
                          alpha: 0.2,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.notifications_active,
                              color: theme.appColors.primarySwatch,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              localizations.reminderTimeLabel,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.appColors.primarySwatch[800],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          localizations.remindersFixedLabel,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.appColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      localizations.createParayanButton,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildGroupSelection(
    AppLocalizations localizations,
    ThemeData theme,
  ) {
    // If admin has a fixed group, show it as a label
    if (widget.adminUser?.groupId != null) {
      final groupId = widget.adminUser!.groupId!;
      _selectedGroupId = groupId; // Set it once

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.3,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.business, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.parayanGroupLabel,
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    groupId, // In a real app, map this to a friendly name from config
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Otherwise show a fallback error if no group is pre-selected
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text(
            "Error: Missing Parayan Group",
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Please navigate from a specific group coordination dashboard.",
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

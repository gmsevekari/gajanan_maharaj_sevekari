import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/utils/locale_extensions.dart';
import 'package:gajanan_maharaj_sevekari/utils/date_time_utils.dart';
import 'package:flutter/services.dart';
import 'package:gajanan_maharaj_sevekari/admin/admin_audit_service.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/admin_user.dart';
import 'package:gajanan_maharaj_sevekari/models/parayan_event.dart';
import 'package:gajanan_maharaj_sevekari/parayan/parayan_type.dart';
import 'package:gajanan_maharaj_sevekari/providers/parayan_service.dart';
import 'package:intl/intl.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:uuid/uuid.dart';

class AdminParayanCreateScreen extends StatefulWidget {
  final AdminUser? adminUser;
  final ParayanService? parayanService;

  const AdminParayanCreateScreen({
    super.key,
    this.adminUser,
    this.parayanService,
  });

  @override
  State<AdminParayanCreateScreen> createState() =>
      _AdminParayanCreateScreenState();
}

class _AdminParayanCreateScreenState extends State<AdminParayanCreateScreen> {
  static final _alphanumericRegExp = RegExp('[a-zA-Z0-9 \u0900-\u097F]');

  final _formKey = GlobalKey<FormState>();
  late final ParayanService _parayanService;

  final _titleEnController = TextEditingController();
  final _titleMrController = TextEditingController();
  final _descriptionEnController = TextEditingController();
  final _descriptionMrController = TextEditingController();
  ParayanType _selectedType = ParayanType.oneDay;
  late DateTime _startDate;
  late DateTime _endDate;
  bool _isEndDateSetManually = false;
  String? _selectedGroupId;
  String _selectedTimezone = 'America/Los_Angeles';

  bool _isLoading = false;
  bool _is4DayParayan = false;
  String _selectedExtraDayTithi = 'dashami';

  @override
  void initState() {
    super.initState();
    _parayanService = widget.parayanService ?? ParayanService();
    _selectedGroupId = widget.adminUser?.groupId;
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day);
    _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
  }

  @override
  void dispose() {
    _titleEnController.dispose();
    _titleMrController.dispose();
    _descriptionEnController.dispose();
    _descriptionMrController.dispose();
    super.dispose();
  }

  /// Computes the end date based on the parayan type and start date.
  static DateTime _computeEndDate(
    ParayanType type,
    DateTime startDate, {
    bool is4DayParayan = false,
  }) {
    switch (type) {
      case ParayanType.threeDay:
        final targetEnd = startDate.add(Duration(days: is4DayParayan ? 3 : 2));
        return DateTime(
          targetEnd.year,
          targetEnd.month,
          targetEnd.day,
          23,
          59,
          59,
        );
      case ParayanType.oneDay:
        return DateTime(
          startDate.year,
          startDate.month,
          startDate.day,
          23,
          59,
          59,
        );
      case ParayanType.guruPushya:
        return startDate;
    }
  }

  Future<void> _selectDateTime(bool isStartDate) async {
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

    if (pickedTime == null) return;
    if (!mounted) return;

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
        _endDate = _computeEndDate(
          _selectedType,
          _startDate,
          is4DayParayan: _is4DayParayan,
        );
      } else {
        _endDate = newDateTime;
        _isEndDateSetManually = true;
      }
    });
  }

  Future<void> _selectDate(bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked == null) return;
    if (!mounted) return;

    setState(() {
      if (isStartDate) {
        _startDate = picked;
        _endDate = _computeEndDate(
          _selectedType,
          _startDate,
          is4DayParayan: _is4DayParayan,
        );
      } else {
        _endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
        _isEndDateSetManually = true;
      }
    });
  }

  Future<void> _submit() async {
    final localizations = AppLocalizations.of(context)!;
    final adminUser = widget.adminUser;

    // Security guard for null adminUser
    if (adminUser == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.missingAdminError),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    // Chronological validation
    if (_endDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.endDateBeforeStartDateError),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    // Guru Pushya mandatory end date validation
    if (_selectedType == ParayanType.guruPushya && !_isEndDateSetManually) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.guruPushyaEndDateRequired),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Fixed reminder times: 1 PM, 4 PM, 7 PM
      final List<String> formattedTimes = ["13:00", "16:00", "19:00"];

      if (_selectedGroupId == null) {
        throw Exception(localizations.groupIdRequiredError);
      }
      final String groupId = _selectedGroupId!;
      final String dateStr = DateFormat('yyyy-MM-dd').format(_startDate);
      final String eventId = "$groupId-$dateStr-${_selectedType.name}";

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

      final startUtc = _convertToUtc(_startDate, _selectedTimezone);
      final endUtc = _convertToUtc(_endDate, _selectedTimezone);

      final event = ParayanEvent(
        id: eventId,
        titleEn: _titleEnController.text.trim(),
        titleMr: _titleMrController.text.trim(),
        descriptionEn: _descriptionEnController.text.trim(),
        descriptionMr: _descriptionMrController.text.trim(),
        type: _selectedType,
        startDate: startUtc,
        endDate: endUtc,
        status: 'upcoming',
        reminderTimes: formattedTimes,
        createdAt: DateTime.now(),
        sentReminders: const {},
        joinCode: const Uuid().v4().substring(0, 6).toUpperCase(),
        groupId: groupId,
        timezone: _selectedTimezone,
        is4DayParayan: _is4DayParayan,
        extraDayTithi: _is4DayParayan ? _selectedExtraDayTithi : null,
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

      final messenger = ScaffoldMessenger.of(context);
      final isMarathi = Localizations.localeOf(context).useMarathiContent;
      final eventTitle = isMarathi ? event.titleMr : event.titleEn;

      // Navigate to detail screen and show snackbar
      Navigator.pushReplacementNamed(
        context,
        Routes.adminParayanDetail,
        arguments: event,
      );

      messenger.showSnackBar(
        SnackBar(
          content: Text(localizations.parayanCreatedSuccess(eventTitle)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.failedToCreateParayan),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  DateTime _convertToUtc(DateTime localTime, String timezone) {
    if (timezone == 'Asia/Kolkata') {
      return DateTime.utc(
        localTime.year,
        localTime.month,
        localTime.day,
        localTime.hour,
        localTime.minute,
        localTime.second,
      ).subtract(const Duration(hours: 5, minutes: 30));
    } else {
      // America/Los_Angeles (Pacific Time)
      final isDst = _isPacificDST(localTime);
      final offsetHours = isDst ? 7 : 8;
      return DateTime.utc(
        localTime.year,
        localTime.month,
        localTime.day,
        localTime.hour,
        localTime.minute,
        localTime.second,
      ).add(Duration(hours: offsetHours));
    }
  }

  bool _isPacificDST(DateTime date) {
    if (date.month < 3 || date.month > 11) return false;
    if (date.month > 3 && date.month < 11) return true;

    if (date.month == 3) {
      final march1 = DateTime(date.year, 3, 1);
      final daysToFirstSunday = (7 - march1.weekday) % 7;
      final secondSundayDay = 1 + daysToFirstSunday + 7;
      if (date.day < secondSundayDay) return false;
      if (date.day > secondSundayDay) return true;
      return date.hour >= 2;
    }

    if (date.month == 11) {
      final nov1 = DateTime(date.year, 11, 1);
      final daysToFirstSunday = (7 - nov1.weekday) % 7;
      final firstSundayDay = 1 + daysToFirstSunday;
      if (date.day < firstSundayDay) return true;
      if (date.day > firstSundayDay) return false;
      return date.hour < 2;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final List<TextInputFormatter> alphanumericFormatter = [
      FilteringTextInputFormatter.allow(_alphanumericRegExp),
    ];

    if (_selectedGroupId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(localizations.createParayanTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  localizations.missingParayanGroupError,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  localizations.navigateFromDashboardPrompt,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final List<Map<String, String>> timezones = [
      {'label': localizations.timezoneSeattle, 'value': 'America/Los_Angeles'},
      {'label': localizations.timezoneIndia, 'value': 'Asia/Kolkata'},
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
                    initialValue: _selectedType,
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
                          _endDate = _computeEndDate(
                            _selectedType,
                            _startDate,
                            is4DayParayan: _is4DayParayan,
                          );
                          if (_selectedType == ParayanType.guruPushya) {
                            _isEndDateSetManually = false;
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  if (_selectedType == ParayanType.threeDay) ...[
                    SwitchListTile(
                      title: Text(localizations.is4DayParayanLabel),
                      subtitle: Text(localizations.is4DayParayanSubtitle),
                      value: _is4DayParayan,
                      onChanged: (bool value) {
                        setState(() {
                          _is4DayParayan = value;
                          _endDate = _computeEndDate(
                            _selectedType,
                            _startDate,
                            is4DayParayan: _is4DayParayan,
                          );
                        });
                      },
                    ),
                    if (_is4DayParayan) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedExtraDayTithi,
                        decoration: InputDecoration(
                          labelText: localizations.extraDayTithiLabel,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'dashami',
                            child: Text(localizations.dashamiOptionLabel),
                          ),
                          DropdownMenuItem(
                            value: 'ekadashi',
                            child: Text(localizations.ekadashiOptionLabel),
                          ),
                          DropdownMenuItem(
                            value: 'dwadashi',
                            child: Text(localizations.dwadashiOptionLabel),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedExtraDayTithi = value;
                            });
                          }
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],

                  DropdownButtonFormField<String>(
                    initialValue: _selectedTimezone,
                    decoration: InputDecoration(
                      labelText: localizations.timezoneLabel,
                    ),
                    items: timezones.map((tz) {
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
                        formatDateMedium(
                          _startDate,
                          Localizations.localeOf(context).languageCode,
                        ),
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectDate(true),
                    )
                  else ...[
                    ListTile(
                      title: Text(localizations.startDateLabel),
                      subtitle: Text(
                        formatDateMedium(
                          _startDate,
                          Localizations.localeOf(context).languageCode,
                          includeTime: _selectedType == ParayanType.guruPushya,
                        ),
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectedType == ParayanType.guruPushya
                          ? _selectDateTime(true)
                          : _selectDate(true),
                    ),
                    if (_selectedType == ParayanType.threeDay)
                      ListTile(
                        title: Text(localizations.endDateLabel),
                        subtitle: Text(
                          formatDateMedium(
                            _endDate,
                            Localizations.localeOf(context).languageCode,
                          ),
                        ),
                        enabled: false,
                      )
                    else // guruPushya
                      ListTile(
                        title: Text(localizations.endDateLabel),
                        subtitle: Text(
                          formatDateMedium(
                            _endDate,
                            Localizations.localeOf(context).languageCode,
                            includeTime: true,
                          ),
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () => _selectDateTime(false),
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

  Widget _buildGroupSelection(AppLocalizations localizations, ThemeData theme) {
    final groupId = _selectedGroupId!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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
                  groupId,
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
}

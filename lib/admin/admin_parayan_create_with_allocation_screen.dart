import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gajanan_maharaj_sevekari/utils/locale_extensions.dart';
import 'package:gajanan_maharaj_sevekari/admin/admin_audit_service.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/admin_user.dart';
import 'package:gajanan_maharaj_sevekari/models/parayan_event.dart';
import 'package:gajanan_maharaj_sevekari/models/parayan_participant.dart';
import 'package:gajanan_maharaj_sevekari/parayan/parayan_type.dart';
import 'package:gajanan_maharaj_sevekari/providers/parayan_service.dart';
import 'package:gajanan_maharaj_sevekari/utils/group_utils.dart';
import 'package:gajanan_maharaj_sevekari/utils/adhyay_utils.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class AdminParayanCreateWithAllocationScreen extends StatefulWidget {
  final AdminUser? adminUser;
  final ParayanService? parayanService;

  const AdminParayanCreateWithAllocationScreen({
    super.key,
    this.adminUser,
    this.parayanService,
  });

  @override
  State<AdminParayanCreateWithAllocationScreen> createState() =>
      _AdminParayanCreateWithAllocationScreenState();
}

class _AdminParayanCreateWithAllocationScreenState
    extends State<AdminParayanCreateWithAllocationScreen> {
  final _formKey = GlobalKey<FormState>();
  late final ParayanService _parayanService;

  final _titleEnController = TextEditingController();
  final _titleMrController = TextEditingController();

  String _descriptionEn = '';
  String _descriptionMr = '';

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  bool _isLoading = false;
  bool _fetchingLastParayan = true;

  List<ParayanEvent> _gunjanEvents = [];
  ParayanEvent? _selectedLastParayan;

  bool _is4DayParayan = false;
  String _selectedExtraDayTithi = 'dashami';

  @override
  void initState() {
    super.initState();
    _parayanService = widget.parayanService ?? ParayanService();
    _loadGunjanEvents();
  }

  @override
  void dispose() {
    _titleEnController.dispose();
    _titleMrController.dispose();
    super.dispose();
  }

  Future<void> _loadGunjanEvents() async {
    try {
      final events = await _parayanService.getGunjanEvents();
      if (!mounted) return;
      setState(() {
        _gunjanEvents = events;
        _fetchingLastParayan = false;
        if (events.isNotEmpty) {
          final lastEvent = events.first;
          _selectedLastParayan = lastEvent;
          _descriptionEn = lastEvent.descriptionEn;
          _descriptionMr = lastEvent.descriptionMr;
          _titleEnController.text = lastEvent.titleEn;
          _titleMrController.text = lastEvent.titleMr;
          _updateEndDates(lastEvent.type);
        }
      });
    } catch (e) {
      debugPrint('Failed to load last parayan events: $e');
      if (!mounted) return;
      setState(() {
        _fetchingLastParayan = false;
      });
      final localizations = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.failedToLoadEvents),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _updateEndDates(ParayanType type) {
    if (type == ParayanType.threeDay) {
      final targetEnd = _startDate.add(Duration(days: _is4DayParayan ? 3 : 2));
      _endDate = DateTime(
        targetEnd.year,
        targetEnd.month,
        targetEnd.day,
        23,
        59,
        59,
      );
    } else {
      _endDate = DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
        23,
        59,
        59,
      );
    }
  }

  void _onLastParayanSelected(ParayanEvent lastEvent) {
    setState(() {
      _selectedLastParayan = lastEvent;
      _descriptionEn = lastEvent.descriptionEn;
      _descriptionMr = lastEvent.descriptionMr;
      _titleEnController.text = lastEvent.titleEn;
      _titleMrController.text = lastEvent.titleMr;
      _updateEndDates(lastEvent.type);
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        _startDate = DateTime(picked.year, picked.month, picked.day, 0, 0, 0);
        if (_selectedLastParayan != null) {
          _updateEndDates(_selectedLastParayan!.type);
        }
      });
    }
  }

  List<Map<String, dynamic>> _buildNewParticipants(
    List<ParayanMember> lastParticipants,
    Timestamp nowTs,
  ) {
    final List<Map<String, dynamic>> newParticipants = [];
    for (int i = 0; i < lastParticipants.length; i++) {
      final lastParticipant = lastParticipants[i];
      final nextAdhyays = getNextAdhyays(lastParticipant.assignedAdhyays);

      final completionsMap = <String, bool>{};
      for (int k = 0; k < nextAdhyays.length; k++) {
        completionsMap[(k + 1).toString()] = false;
      }

      final sanitizedName = lastParticipant.name.replaceAll(
        RegExp(r'\s+'),
        '_',
      );
      final rawPhone = lastParticipant.phone ?? 'Unknown';
      final sanitizedPhone = rawPhone.replaceAll(RegExp(r'[^a-zA-Z0-9+]'), '_');
      // Added index suffix to prevent collisions for same phone+name in same second
      final docId =
          "ADMIN_${sanitizedPhone}_${sanitizedName}_${nowTs.seconds}_$i";

      newParticipants.add({
        'docId': docId,
        'name': lastParticipant.name,
        'memberName': lastParticipant.name,
        'deviceId': lastParticipant.deviceId,
        'phone': lastParticipant.phone,
        'globalIndex': lastParticipant.globalIndex,
        'groupNumber': lastParticipant.groupNumber,
        'assignedAdhyays': nextAdhyays,
        'completions': completionsMap,
        'joinedAt': nowTs,
      });
    }
    return newParticipants;
  }

  ParayanEvent _buildNewEvent({
    required String eventId,
    required String groupId,
    required ParayanType eventType,
    required DateTime startUtc,
    required DateTime endUtc,
    required bool is4DayParayan,
    required String? extraDayTithi,
  }) {
    final List<String> formattedTimes = const ["13:00", "16:00", "19:00"];
    return ParayanEvent(
      id: eventId,
      titleEn: _titleEnController.text.trim(),
      titleMr: _titleMrController.text.trim(),
      descriptionEn: _descriptionEn,
      descriptionMr: _descriptionMr,
      type: eventType,
      startDate: startUtc,
      endDate: endUtc,
      status: 'upcoming',
      reminderTimes: formattedTimes,
      createdAt: DateTime.now(),
      sentReminders: const {},
      joinCode: const Uuid().v4().substring(0, 6).toUpperCase(),
      groupId: groupId,
      timezone: 'Asia/Kolkata',
      is4DayParayan: is4DayParayan,
      extraDayTithi: extraDayTithi,
    );
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
    if (_selectedLastParayan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.selectPreviousParayanError),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final String groupId = GroupConstants.gunjan;
      final String dateStr = DateFormat('yyyy-MM-dd').format(_startDate);
      final ParayanType eventType = _selectedLastParayan!.type;
      final String eventId = "$groupId-$dateStr-${eventType.name}";

      final bool alreadyExists = await _parayanService.exists(eventId);
      if (alreadyExists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.duplicateDateError),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final lastParticipants = await _parayanService.getParticipantsOnce(
        _selectedLastParayan!.id,
      );

      final nowTs = Timestamp.now();
      final newParticipants = _buildNewParticipants(lastParticipants, nowTs);

      final startUtc = DateTime.utc(
        _startDate.year,
        _startDate.month,
        _startDate.day,
      ).subtract(const Duration(hours: 5, minutes: 30));

      final endUtc = DateTime.utc(
        _endDate.year,
        _endDate.month,
        _endDate.day,
        23,
        59,
        59,
      ).subtract(const Duration(hours: 5, minutes: 30));

      final event = _buildNewEvent(
        eventId: eventId,
        groupId: groupId,
        eventType: eventType,
        startUtc: startUtc,
        endUtc: endUtc,
        is4DayParayan: _is4DayParayan,
        extraDayTithi: _is4DayParayan ? _selectedExtraDayTithi : null,
      );

      await _parayanService.createEventWithParticipants(
        event: event,
        participants: newParticipants,
      );

      await AdminAuditService.logAction(
        action: 'CREATE_PARAYAN_WITH_ALLOCATION',
        details: {
          'event_id': event.id,
          'last_event_id': _selectedLastParayan!.id,
          'title_en': event.titleEn,
          'type': event.type.toString(),
          'start_date': event.startDate.toIso8601String(),
          'participants_count': newParticipants.length,
        },
      );

      if (!mounted) return;

      final isMarathi = Localizations.localeOf(context).useMarathiContent;
      final eventTitle = isMarathi ? event.titleMr : event.titleEn;

      // Show snackbar BEFORE navigation to ensure it displays on the new screen correctly
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.createParayanSuccess(eventTitle)),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacementNamed(
        context,
        Routes.adminParayanDetail,
        arguments: event,
      );
    } catch (e) {
      debugPrint('Failed to create parayan: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.failedToCreateParayan),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isMarathi = Localizations.localeOf(context).useMarathiContent;

    return Scaffold(
      appBar: AppBar(title: Text(localizations.createParayanWithAllocation)),
      body: _fetchingLastParayan
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ParayanSourceCard(
                      gunjanEvents: _gunjanEvents,
                      selectedLastParayan: _selectedLastParayan,
                      isMarathi: isMarathi,
                      localizations: localizations,
                      onChanged: (value) {
                        if (value != null) {
                          _onLastParayanSelected(value);
                        }
                      },
                    ),
                    if (_selectedLastParayan != null) ...[
                      _EnglishDetailsSection(
                        titleController: _titleEnController,
                        description: _descriptionEn,
                        localizations: localizations,
                      ),
                      const SizedBox(height: 20.0),
                      _MarathiDetailsSection(
                        titleController: _titleMrController,
                        description: _descriptionMr,
                        localizations: localizations,
                      ),
                      const SizedBox(height: 20.0),
                      _DatePickerCard(
                        startDate: _startDate,
                        isMarathi: isMarathi,
                        localizations: localizations,
                        onTap: () => _selectDate(context),
                      ),
                      const SizedBox(height: 20.0),
                      SwitchListTile(
                        title: Text(isMarathi ? '४ दिवसांचे पारायण?' : 'Is this a 4-day parayan?'),
                        subtitle: Text(isMarathi
                            ? 'जर तिथी (दशमी/एकादशी/द्वादशी) २ दिवस असेल तर निवडा'
                            : 'Select if a tithi (dashami/ekadashi/dwadashi) spans 2 days'),
                        value: _is4DayParayan,
                        onChanged: (bool value) {
                          setState(() {
                            _is4DayParayan = value;
                            _updateEndDates(_selectedLastParayan!.type);
                          });
                        },
                      ),
                      if (_is4DayParayan) ...[
                        const SizedBox(height: 12.0),
                        DropdownButtonFormField<String>(
                          value: _selectedExtraDayTithi,
                          decoration: InputDecoration(
                            labelText: isMarathi ? '२ दिवस असणारी तिथी' : 'Tithi spanning 2 days',
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'dashami',
                              child: Text(isMarathi ? 'दशमी (दिवस १)' : 'Dashami (Day 1)'),
                            ),
                            DropdownMenuItem(
                              value: 'ekadashi',
                              child: Text(isMarathi ? 'एकादशी (दिवस २)' : 'Ekadashi (Day 2)'),
                            ),
                            DropdownMenuItem(
                              value: 'dwadashi',
                              child: Text(isMarathi ? 'द्वादशी (दिवस ३)' : 'Dwadashi (Day 3)'),
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
                      const SizedBox(height: 24.0),
                      _SubmitButton(
                        isLoading: _isLoading,
                        onSubmit: _submit,
                        localizations: localizations,
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}

class _ParayanSourceCard extends StatelessWidget {
  final List<ParayanEvent> gunjanEvents;
  final ParayanEvent? selectedLastParayan;
  final bool isMarathi;
  final AppLocalizations localizations;
  final ValueChanged<ParayanEvent?> onChanged;

  const _ParayanSourceCard({
    required this.gunjanEvents,
    required this.selectedLastParayan,
    required this.isMarathi,
    required this.localizations,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.selectLastParayan,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12.0),
            gunjanEvents.isEmpty
                ? Text(
                    localizations.noPreviousParayansFound,
                    style: TextStyle(color: theme.colorScheme.error),
                  )
                : DropdownButtonFormField<ParayanEvent>(
                    value: selectedLastParayan,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: localizations.lastParayanLabel,
                      border: const OutlineInputBorder(),
                    ),
                    items: gunjanEvents.map((event) {
                      final dateStr = DateFormat.yMMMd().format(
                        event.startDate,
                      );
                      return DropdownMenuItem<ParayanEvent>(
                        value: event,
                        child: Text(
                          '${isMarathi ? event.titleMr : event.titleEn} ($dateStr)',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: onChanged,
                  ),
          ],
        ),
      ),
    );
  }
}

class _EnglishDetailsSection extends StatelessWidget {
  final TextEditingController titleController;
  final String description;
  final AppLocalizations localizations;

  const _EnglishDetailsSection({
    required this.titleController,
    required this.description,
    required this.localizations,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.englishDetailsHeader,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8.0),
        TextFormField(
          controller: titleController,
          decoration: InputDecoration(
            labelText: localizations.parayanNameLabel,
            border: const OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return localizations.parayanNameRequired;
            }
            return null;
          },
        ),
        const SizedBox(height: 12.0),
        Text(
          '${localizations.parayanDescriptionLabel}:',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4.0),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Text(description),
        ),
      ],
    );
  }
}

class _MarathiDetailsSection extends StatelessWidget {
  final TextEditingController titleController;
  final String description;
  final AppLocalizations localizations;

  const _MarathiDetailsSection({
    required this.titleController,
    required this.description,
    required this.localizations,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.marathiDetailsHeader,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8.0),
        TextFormField(
          controller: titleController,
          decoration: InputDecoration(
            labelText: localizations.parayanNameMrLabel,
            border: const OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return localizations.parayanNameMrRequired;
            }
            return null;
          },
        ),
        const SizedBox(height: 12.0),
        Text(
          '${localizations.parayanDescriptionMrLabel}:',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4.0),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Text(description),
        ),
      ],
    );
  }
}

class _DatePickerCard extends StatelessWidget {
  final DateTime startDate;
  final bool isMarathi;
  final AppLocalizations localizations;
  final VoidCallback onTap;

  const _DatePickerCard({
    required this.startDate,
    required this.isMarathi,
    required this.localizations,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 24.0),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: ListTile(
        title: Text(
          localizations.startDateLabel,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(DateFormat.yMMMMd().format(startDate)),
        trailing: const Icon(Icons.calendar_today),
        onTap: onTap,
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onSubmit;
  final AppLocalizations localizations;

  const _SubmitButton({
    required this.isLoading,
    required this.onSubmit,
    required this.localizations,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      height: 50.0,
      child: ElevatedButton(
        onPressed: isLoading ? null : onSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 24.0,
                height: 24.0,
                child: CircularProgressIndicator(
                  color: theme.colorScheme.onPrimary,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                localizations.createWithAllocationButton,
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}

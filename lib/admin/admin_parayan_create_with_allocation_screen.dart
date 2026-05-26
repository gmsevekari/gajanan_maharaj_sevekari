import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gajanan_maharaj_sevekari/utils/locale_extensions.dart';
import 'package:gajanan_maharaj_sevekari/admin/admin_audit_service.dart';
import 'package:gajanan_maharaj_sevekari/admin/admin_parayan_detail_screen.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/admin_user.dart';
import 'package:gajanan_maharaj_sevekari/models/parayan_event.dart';
import 'package:gajanan_maharaj_sevekari/parayan/parayan_type.dart';
import 'package:gajanan_maharaj_sevekari/providers/parayan_service.dart';
import 'package:gajanan_maharaj_sevekari/utils/group_utils.dart';
import 'package:gajanan_maharaj_sevekari/utils/adhyay_utils.dart';
import 'package:intl/intl.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
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
  
  // descriptions are copied from last parayan and shown as label (not editable text field)
  String _descriptionEn = '';
  String _descriptionMr = '';

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  bool _isLoading = false;
  bool _fetchingLastParayan = true;

  List<ParayanEvent> _gunjanEvents = [];
  ParayanEvent? _selectedLastParayan;

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
      setState(() {
        _gunjanEvents = events;
        _fetchingLastParayan = false;
        if (events.isNotEmpty) {
          _selectedLastParayan = events.first;
          _onLastParayanSelected(events.first);
        }
      });
    } catch (e) {
      setState(() {
        _fetchingLastParayan = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load last parayan events: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _onLastParayanSelected(ParayanEvent lastEvent) {
    setState(() {
      _descriptionEn = lastEvent.descriptionEn;
      _descriptionMr = lastEvent.descriptionMr;

      // English: Copy from previous and show as a label
      _titleEnController.text = lastEvent.titleEn;
      
      // Marathi: Copy from previous and show as a label
      _titleMrController.text = lastEvent.titleMr;

      // Automatically setup end date based on type
      if (lastEvent.type == ParayanType.threeDay) {
        final targetEnd = _startDate.add(const Duration(days: 2));
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
        _startDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          0,
          0,
          0,
        );
        if (_selectedLastParayan?.type == ParayanType.threeDay) {
          final targetEnd = _startDate.add(const Duration(days: 2));
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
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLastParayan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select the previous parayan to copy allocation from.'),
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
      final String groupId = GroupConstants.gunjan;
      final String dateStr = DateFormat('yyyy-MM-dd').format(_startDate);
      final ParayanType eventType = _selectedLastParayan!.type;
      final String eventId = "$groupId-$dateStr-${eventType.name}";

      // Check for duplicate start date
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

      // Fetch participants of last event to rotate adhyays
      final lastParticipants =
          await _parayanService.getParticipantsOnce(_selectedLastParayan!.id);

      final List<Map<String, dynamic>> newParticipants = [];
      final nowTs = Timestamp.now();

      for (final lastParticipant in lastParticipants) {
        // compute next adhyays
        final nextAdhyays = getNextAdhyays(lastParticipant.assignedAdhyays);
        
        final completionsMap = <String, bool>{};
        for (int i = 0; i < nextAdhyays.length; i++) {
          completionsMap[(i + 1).toString()] = false;
        }

        final sanitizedName = lastParticipant.name.replaceAll(RegExp(r'\s+'), '_');
        final phone = lastParticipant.phone ?? 'Unknown';
        final docId = "ADMIN_${phone}_${sanitizedName}_${nowTs.seconds}";

        newParticipants.add({
          'docId': docId,
          'name': lastParticipant.name,
          'deviceId': lastParticipant.deviceId,
          'phone': lastParticipant.phone,
          'globalIndex': lastParticipant.globalIndex,
          'groupNumber': lastParticipant.groupNumber,
          'assignedAdhyays': nextAdhyays,
          'completions': completionsMap,
          'joinedAt': nowTs,
        });
      }

      // Construct start and end dates directly in UTC matching the India (Asia/Kolkata) timezone representation.
      // India is UTC+5:30. So 00:00:00 local time in India is 18:30:00 UTC of the previous day.
      final startUtc = DateTime.utc(_startDate.year, _startDate.month, _startDate.day)
          .subtract(const Duration(hours: 5, minutes: 30));
      
      // 23:59:59 local time in India is 18:29:59 UTC.
      final endUtc = DateTime.utc(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59)
          .subtract(const Duration(hours: 5, minutes: 30));

      final List<String> formattedTimes = ["13:00", "16:00", "19:00"];
      final event = ParayanEvent(
        id: eventId,
        titleEn: _titleEnController.text.trim(),
        titleMr: _titleMrController.text.trim(),
        descriptionEn: _descriptionEn,
        descriptionMr: _descriptionMr,
        type: eventType,
        startDate: startUtc,
        endDate: endUtc,
        status: 'upcoming', // Approved to set upcoming on creation
        reminderTimes: formattedTimes,
        createdAt: DateTime.now(),
        sentReminders: const {},
        joinCode: const Uuid().v4().substring(0, 6).toUpperCase(),
        groupId: groupId,
        timezone: 'Asia/Kolkata', // Hard-coded for Gunjan
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

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AdminParayanDetailScreen(event: event),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isMarathi
                ? 'अलोकेशनसह पारायण "$eventTitle" यशस्वीरीत्या तयार केले आहे.'
                : 'Parayan "$eventTitle" with allocation has been created successfully.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create parayan: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isMarathi = Localizations.localeOf(context).useMarathiContent;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.createParayanWithAllocation),
      ),
      body: _fetchingLastParayan
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
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
                            _gunjanEvents.isEmpty
                                ? Text(
                                    'No previous Gunjan parayans found to copy from.',
                                    style: TextStyle(color: theme.colorScheme.error),
                                  )
                                : DropdownButtonFormField<ParayanEvent>(
                                    value: _selectedLastParayan,
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      labelText: localizations.lastParayanLabel,
                                      border: const OutlineInputBorder(),
                                    ),
                                    items: _gunjanEvents.map((event) {
                                      final dateStr = DateFormat.yMMMd().format(event.startDate);
                                      return DropdownMenuItem<ParayanEvent>(
                                        value: event,
                                        child: Text(
                                          '${isMarathi ? event.titleMr : event.titleEn} ($dateStr)',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        _onLastParayanSelected(value);
                                      }
                                    },
                                  ),
                          ],
                        ),
                      ),
                    ),
                    if (_selectedLastParayan != null) ...[
                      // English Details
                      Text(
                        localizations.englishDetailsHeader,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      TextFormField(
                        controller: _titleEnController,
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
                        child: Text(_descriptionEn),
                      ),
                      const SizedBox(height: 20.0),

                      // Marathi Details
                      Text(
                        localizations.marathiDetailsHeader,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      TextFormField(
                        controller: _titleMrController,
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
                        child: Text(_descriptionMr),
                      ),
                      const SizedBox(height: 20.0),

                      // Date Selection
                      Card(
                        margin: const EdgeInsets.only(bottom: 24.0),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: ListTile(
                          title: Text(
                            isMarathi ? 'सुरुवात तारीख' : 'Start Date',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            DateFormat.yMMMMd().format(_startDate),
                          ),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: () => _selectDate(context),
                        ),
                      ),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 50.0,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  localizations.createWithAllocationButton,
                                  style: const TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}

import 'dart:math';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/vaari_event.dart';
import 'package:gajanan_maharaj_sevekari/providers/vaari_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gajanan_maharaj_sevekari/models/admin_user.dart';

class AdminVaariCreateScreen extends StatefulWidget {
  final AdminUser adminUser;
  final FirebaseFirestore? firestore;

  const AdminVaariCreateScreen({
    super.key,
    required this.adminUser,
    this.firestore,
  });

  @override
  State<AdminVaariCreateScreen> createState() => _AdminVaariCreateScreenState();
}

class _AdminVaariCreateScreenState extends State<AdminVaariCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameEnController = TextEditingController();
  final _nameMrController = TextEditingController();
  final _descEnController = TextEditingController();
  final _descMrController = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  String _selectedTimezone = 'America/Los_Angeles';
  String _selectedUnit = 'km';
  bool _isLoading = false;

  final List<Map<String, String>> _timezones = [
    {'label': 'Seattle (Pacific Time)', 'value': 'America/Los_Angeles'},
    {'label': 'India (IST)', 'value': 'Asia/Kolkata'},
  ];

  final List<Map<String, String>> _units = [
    {'label': 'Kilometers (km)', 'value': 'km'},
    {'label': 'Miles (mi)', 'value': 'mi'},
  ];

  late final FirebaseFirestore _firestore;
  late final VaariService _service;

  @override
  void initState() {
    super.initState();
    _firestore = widget.firestore ?? FirebaseFirestore.instance;
    _service = VaariService(firestore: _firestore);
  }

  @override
  void dispose() {
    _nameEnController.dispose();
    _nameMrController.dispose();
    _descEnController.dispose();
    _descMrController.dispose();
    super.dispose();
  }

  String _generateJoinCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: isStart
          ? DateTime.now().subtract(const Duration(days: 30))
          : _startDate,
      lastDate: DateTime(2030),
    );

    if (pickedDate != null) {
      setState(() {
        if (isStart) {
          _startDate = pickedDate;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 1));
          }
        } else {
          _endDate = pickedDate;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final dateStr = DateFormat('yyyyMMdd').format(_startDate);
      final groupId = widget.adminUser.groupId;
      if (groupId == null) {
        throw Exception('Group ID is required to create an event');
      }

      final joinCode = _generateJoinCode();
      final docId = '${groupId}_${dateStr}_$joinCode';

      final newEvent = VaariEvent(
        id: docId,
        nameEn: _nameEnController.text.trim(),
        nameMr: _nameMrController.text.trim(),
        descriptionEn: _descEnController.text.trim(),
        descriptionMr: _descMrController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        status: 'upcoming',
        groupId: groupId,
        timezone: _selectedTimezone,
        totalSteps: 0,
        totalDistance: 0.0,
        distanceUnit: _selectedUnit,
        joinCode: joinCode,
        createdAt: DateTime.now(),
      );

      await _service.createEvent(newEvent);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.vaariCreateSuccess),
          ),
        );
        Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(localizations.createVaariTitle)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameEnController,
                      decoration: const InputDecoration(
                        labelText: 'Event Name (English)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter English name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameMrController,
                      decoration: const InputDecoration(
                        labelText: 'कार्यक्रम नाव (मराठी)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'कृपया मराठी नाव प्रविष्ट करा';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descEnController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description (English)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter English description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descMrController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'वर्णन (मराठी)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'कृपया मराठी वर्णन प्रविष्ट करा';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedTimezone,
                      decoration: const InputDecoration(
                        labelText: 'Timezone',
                        border: OutlineInputBorder(),
                      ),
                      items: _timezones
                          .map(
                            (tz) => DropdownMenuItem(
                              value: tz['value'],
                              child: Text(tz['label']!),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedTimezone = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedUnit,
                      decoration: const InputDecoration(
                        labelText: 'Distance Unit',
                        border: OutlineInputBorder(),
                      ),
                      items: _units
                          .map(
                            (u) => DropdownMenuItem(
                              value: u['value'],
                              child: Text(u['label']!),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedUnit = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              'Start: ${DateFormat('yyyy-MM-dd').format(_startDate)}',
                            ),
                            onPressed: () => _selectDate(context, true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              'End: ${DateFormat('yyyy-MM-dd').format(_endDate)}',
                            ),
                            onPressed: () => _selectDate(context, false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(localizations.finishOnboarding),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

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
  final _targetDistanceController = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  String _selectedTimezone = 'America/Los_Angeles';
  String _selectedUnit = 'km';
  bool _isLoading = false;


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
    _targetDistanceController.dispose();
    super.dispose();
  }

  String _generateJoinCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random.secure();
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
          _endDate = pickedDate.isBefore(_startDate)
              ? _startDate.add(const Duration(days: 1))
              : pickedDate;
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

      final targetDistance =
          double.tryParse(_targetDistanceController.text.trim()) ?? 0.0;

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
        targetDistance: targetDistance,
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
      debugPrint('AdminVaariCreateScreen._submit error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.vaariCreateError),
          ),
        );
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

    final timezones = [
      {'label': localizations.timezoneSeattle, 'value': 'America/Los_Angeles'},
      {'label': localizations.timezoneIndia, 'value': 'Asia/Kolkata'},
    ];
    final units = [
      {'label': localizations.distanceUnitKilometers, 'value': 'km'},
      {'label': localizations.distanceUnitMiles, 'value': 'mi'},
    ];

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
                      decoration: InputDecoration(
                        labelText: localizations.adminVaariNameEnLabel,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return localizations.adminVaariNameEnRequired;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameMrController,
                      decoration: InputDecoration(
                        labelText: localizations.adminVaariNameMrLabel,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return localizations.adminVaariNameMrRequired;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descEnController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: localizations.adminVaariDescEnLabel,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return localizations.adminVaariDescEnRequired;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descMrController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: localizations.adminVaariDescMrLabel,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return localizations.adminVaariDescMrRequired;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedTimezone,
                      decoration: InputDecoration(
                        labelText: localizations.timezoneLabel,
                        border: const OutlineInputBorder(),
                      ),
                      items: timezones
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
                      decoration: InputDecoration(
                        labelText: localizations.distanceUnitDropdownLabel,
                        border: const OutlineInputBorder(),
                      ),
                      items: units
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
                    TextFormField(
                      key: const Key('targetDistanceField'),
                      controller: _targetDistanceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: localizations.adminVaariTargetDistance,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return localizations.adminVaariTargetDistanceRequired;
                        }
                        if (double.tryParse(value) == null ||
                            double.parse(value) <= 0) {
                          return localizations.adminVaariInvalidTargetDistance;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              '${localizations.startDateLabel}: ${DateFormat('yyyy-MM-dd').format(_startDate)}',
                            ),
                            onPressed: () => _selectDate(context, true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              '${localizations.endDateLabel}: ${DateFormat('yyyy-MM-dd').format(_endDate)}',
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
                      child: Text(localizations.adminVaariSaveEvent),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

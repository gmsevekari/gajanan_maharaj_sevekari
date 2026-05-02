import 'dart:math';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/group_namjap_event.dart';
import 'package:gajanan_maharaj_sevekari/providers/group_namjap_service.dart';
import 'package:gajanan_maharaj_sevekari/utils/group_utils.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gajanan_maharaj_sevekari/models/admin_user.dart';

class CreateGroupNamjapScreen extends StatefulWidget {
  final AdminUser adminUser;
  final FirebaseFirestore? firestore;
  const CreateGroupNamjapScreen({
    super.key,
    required this.adminUser,
    this.firestore,
  });

  @override
  State<CreateGroupNamjapScreen> createState() =>
      _CreateGroupNamjapScreenState();
}

class _CreateGroupNamjapScreenState extends State<CreateGroupNamjapScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameEnController = TextEditingController();
  final _nameMrController = TextEditingController();
  final _sankalpEnController = TextEditingController();
  final _sankalpMrController = TextEditingController();
  final _mantraController = TextEditingController();
  final _targetCountController = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  String _selectedTimezone = 'America/Los_Angeles';
  bool _isLoading = false;

  final List<Map<String, String>> _timezones = [
    {'label': 'Seattle (Pacific Time)', 'value': 'America/Los_Angeles'},
    {'label': 'India (IST)', 'value': 'Asia/Kolkata'},
  ];

  late final FirebaseFirestore _firestore;
  late final GroupNamjapService _service;

  @override
  void initState() {
    super.initState();
    _firestore = widget.firestore ?? FirebaseFirestore.instance;
    _service = GroupNamjapService(firestore: _firestore);
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
      firstDate: isStart ? DateTime.now() : _startDate,
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
      final target = _targetCountController.text.trim();
      final docId = '${groupId}_${dateStr}_$target';

      final newEvent = GroupNamjapEvent(
        id: docId,
        nameEn: _nameEnController.text.trim(),
        nameMr: _nameMrController.text.trim(),
        sankalpEn: _sankalpEnController.text.trim(),
        sankalpMr: _sankalpMrController.text.trim(),
        mantra: _mantraController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        targetCount: int.parse(_targetCountController.text.trim()),
        totalCount: 0,
        joinCode: _generateJoinCode(),
        status: 'upcoming',
        groupId: groupId,
        timezone: _selectedTimezone,
        createdAt: DateTime.now(),
      );

      await _service.createEvent(newEvent);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.groupNamjapCreateSuccess,
            ),
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
      appBar: AppBar(title: Text(localizations.createGroupNamjapTitle)),
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
                        labelText: localizations.groupNamjapNameEn,
                      ),
                      validator: (v) =>
                          v!.isEmpty ? localizations.groupNamjapRequired : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameMrController,
                      decoration: InputDecoration(
                        labelText: localizations.groupNamjapNameMr,
                      ),
                      validator: (v) =>
                          v!.isEmpty ? localizations.groupNamjapRequired : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _sankalpEnController,
                      decoration: InputDecoration(
                        labelText: localizations.groupNamjapSankalpEn,
                      ),
                      validator: (v) =>
                          v!.isEmpty ? localizations.groupNamjapRequired : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _sankalpMrController,
                      decoration: InputDecoration(
                        labelText: localizations.groupNamjapSankalpMr,
                      ),
                      validator: (v) =>
                          v!.isEmpty ? localizations.groupNamjapRequired : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _mantraController,
                      decoration: InputDecoration(
                        labelText: localizations.groupNamjapMantra,
                      ),
                      validator: (v) =>
                          v!.isEmpty ? localizations.groupNamjapRequired : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _targetCountController,
                      decoration: InputDecoration(
                        labelText: localizations.groupNamjapTargetCount,
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return localizations.groupNamjapRequired;
                        if (int.tryParse(v) == null)
                          return localizations.groupNamjapMustBeNumber;
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedTimezone,
                      decoration: InputDecoration(
                        labelText: localizations.groupNamjapTimezone,
                      ),
                      items: _timezones.map((tz) {
                        return DropdownMenuItem(
                          value: tz['value'],
                          child: Text(tz['label']!),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedTimezone = v);
                      },
                    ),
                    const SizedBox(height: 24),
                    ListTile(
                      title: Text(localizations.groupNamjapStartDate),
                      subtitle: Text("${_startDate.toLocal()}".split(' ')[0]),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectDate(context, true),
                    ),
                    ListTile(
                      title: Text(localizations.groupNamjapEndDate),
                      subtitle: Text("${_endDate.toLocal()}".split(' ')[0]),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectDate(context, false),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _submit,
                      child: Text(
                        localizations.createGroupNamjapTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/parayan_event.dart';
import 'package:gajanan_maharaj_sevekari/parayan/parayan_type.dart';
import 'package:gajanan_maharaj_sevekari/providers/parayan_service.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class CreateParayanScreen extends StatefulWidget {
  const CreateParayanScreen({super.key});

  @override
  State<CreateParayanScreen> createState() => _CreateParayanScreenState();
}

class _CreateParayanScreenState extends State<CreateParayanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _parayanService = ParayanService();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  ParayanType _selectedType = ParayanType.oneDay;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  final List<TimeOfDay> _reminderTimes = [const TimeOfDay(hour: 20, minute: 0)];

  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
            _endDate = _startDate.add(const Duration(days: 2));
          } else {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, int index) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTimes[index],
    );
    if (picked != null) {
      setState(() {
        _reminderTimes[index] = picked;
      });
    }
  }

  void _addReminderTime() {
    setState(() {
      _reminderTimes.add(const TimeOfDay(hour: 20, minute: 0));
    });
  }

  void _removeReminderTime(int index) {
    if (_reminderTimes.length > 1) {
      setState(() {
        _reminderTimes.removeAt(index);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final List<String> formattedTimes = _reminderTimes.map((time) {
        return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
      }).toList();

      final event = ParayanEvent(
        id: const Uuid().v4(),
        titleEn: _titleController.text,
        titleMr: _titleController.text,
        descriptionEn: _descriptionController.text,
        descriptionMr: _descriptionController.text,
        type: _selectedType,
        startDate: _startDate,
        endDate: _endDate,
        status: 'upcoming',
        reminderTimes: formattedTimes,
        createdAt: DateTime.now(),
      );

      await _parayanService.createEvent(event);
      if (!mounted) return;
      Navigator.pop(context);
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

    return Scaffold(
      appBar: AppBar(title: Text(localizations.createParayanTitle)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: localizations.parayanNameLabel,
                      hintText: localizations.parayanNameHint,
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? localizations.parayanNameRequired
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: localizations.parayanDescriptionLabel,
                      hintText: localizations.parayanDescriptionHint,
                    ),
                    maxLines: 3,
                  ),
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
                          if (_selectedType == ParayanType.threeDay) {
                            _endDate = _startDate.add(const Duration(days: 2));
                          } else {
                            _endDate = _startDate;
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: Text(localizations.startDateLabel),
                    subtitle: Text(
                      DateFormat('MMM d, yyyy').format(_startDate),
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _selectDate(context, true),
                  ),
                  if (_selectedType == ParayanType.oneDay)
                    ListTile(
                      title: Text(localizations.endDateLabel),
                      subtitle: Text(
                        DateFormat('MMM d, yyyy').format(_endDate),
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectDate(context, false),
                    )
                  else
                    ListTile(
                      title: Text(localizations.endDateLabel),
                      subtitle: Text(
                        DateFormat('MMM d, yyyy').format(_endDate),
                      ),
                      enabled: false,
                    ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        localizations.reminderTimeLabel,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _addReminderTime,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Time'),
                      ),
                    ],
                  ),
                  ..._reminderTimes.asMap().entries.map((entry) {
                    final index = entry.key;
                    final time = entry.value;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(time.format(context)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.access_time),
                            onPressed: () => _selectTime(context, index),
                          ),
                          if (_reminderTimes.length > 1)
                            IconButton(
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                color: Colors.red,
                              ),
                              onPressed: () => _removeReminderTime(index),
                            ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(localizations.createParayanButton),
                  ),
                ],
              ),
            ),
    );
  }
}

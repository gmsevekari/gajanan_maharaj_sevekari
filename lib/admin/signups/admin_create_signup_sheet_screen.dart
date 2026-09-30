import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/widgets/slot_form_row.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/admin_user.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_sheet.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';
import 'package:gajanan_maharaj_sevekari/providers/signup_service.dart';
import 'package:gajanan_maharaj_sevekari/utils/join_code_generator.dart';

class _SlotFormRowData {
  final TextEditingController labelEnController = TextEditingController();
  final TextEditingController labelMrController = TextEditingController();
  final TextEditingController capacityController = TextEditingController();
  final TextEditingController suggestedAmountController =
      TextEditingController();
  DateTime? date;

  void dispose() {
    labelEnController.dispose();
    labelMrController.dispose();
    capacityController.dispose();
    suggestedAmountController.dispose();
  }
}

class AdminCreateSignupSheetScreen extends StatefulWidget {
  final AdminUser adminUser;

  /// Injected for testing; defaults to [FirebaseFirestore.instance].
  @visibleForTesting
  final FirebaseFirestore? firestore;

  const AdminCreateSignupSheetScreen({
    super.key,
    required this.adminUser,
    this.firestore,
  });

  @override
  State<AdminCreateSignupSheetScreen> createState() =>
      _AdminCreateSignupSheetScreenState();
}

class _AdminCreateSignupSheetScreenState
    extends State<AdminCreateSignupSheetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleEnController = TextEditingController();
  final _titleMrController = TextEditingController();
  final _descEnController = TextEditingController();
  final _descMrController = TextEditingController();

  bool _requiresJoinCode = false;
  bool _isLoading = false;
  String? _slotsError;
  final List<_SlotFormRowData> _slots = [];

  late final FirebaseFirestore _firestore;
  late final SignupService _service;

  @override
  void initState() {
    super.initState();
    _firestore = widget.firestore ?? FirebaseFirestore.instance;
    _service = SignupService(firestore: _firestore);
  }

  @override
  void dispose() {
    _titleEnController.dispose();
    _titleMrController.dispose();
    _descEnController.dispose();
    _descMrController.dispose();
    for (final slot in _slots) {
      slot.dispose();
    }
    super.dispose();
  }

  void _addSlot() {
    setState(() {
      _slots.add(_SlotFormRowData());
      _slotsError = null;
    });
  }

  void _removeSlot(int index) {
    setState(() {
      _slots.removeAt(index).dispose();
    });
  }

  void _moveSlotUp(int index) {
    setState(() {
      final slot = _slots.removeAt(index);
      _slots.insert(index - 1, slot);
    });
  }

  void _moveSlotDown(int index) {
    setState(() {
      final slot = _slots.removeAt(index);
      _slots.insert(index + 1, slot);
    });
  }

  Future<void> _submit() async {
    final localizations = AppLocalizations.of(context)!;
    final formValid = _formKey.currentState!.validate();
    final hasSlots = _slots.isNotEmpty;

    setState(() {
      _slotsError = hasSlots
          ? null
          : localizations.signupSheetSlotsRequiredError;
    });

    if (!formValid || !hasSlots) return;

    setState(() => _isLoading = true);

    try {
      final groupId = widget.adminUser.groupId;
      if (groupId == null) {
        throw Exception('Group ID is required to create a sign-up sheet');
      }

      final now = DateTime.now();
      final sheet = SignupSheet(
        titleEn: _titleEnController.text.trim(),
        titleMr: _titleMrController.text.trim(),
        descriptionEn: _descEnController.text.trim(),
        descriptionMr: _descMrController.text.trim(),
        groupId: groupId,
        requiresJoinCode: _requiresJoinCode,
        joinCode: _requiresJoinCode ? generateJoinCode() : null,
        createdAt: now,
        updatedAt: now,
        createdBy: widget.adminUser.email,
      );

      final slots = [
        for (var i = 0; i < _slots.length; i++)
          SignupSlot(
            labelEn: _slots[i].labelEnController.text.trim(),
            labelMr: _slots[i].labelMrController.text.trim(),
            date: _slots[i].date,
            capacity: int.parse(_slots[i].capacityController.text.trim()),
            suggestedAmount: double.tryParse(
              _slots[i].suggestedAmountController.text.trim(),
            ),
            sortOrder: i,
            createdAt: now,
          ),
      ];

      await _service.createSheetWithSlots(sheet, slots);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.signupSheetCreateSuccess)),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('AdminCreateSignupSheetScreen._submit error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.signupSheetCreateError)),
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

    return Scaffold(
      appBar: AppBar(title: Text(localizations.adminCreateSignupSheetTitle)),
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
                      key: const Key('titleEnField'),
                      controller: _titleEnController,
                      decoration: InputDecoration(
                        labelText: localizations.signupSheetTitleEnLabel,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return localizations.signupSheetTitleEnRequired;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('titleMrField'),
                      controller: _titleMrController,
                      decoration: InputDecoration(
                        labelText: localizations.signupSheetTitleMrLabel,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return localizations.signupSheetTitleMrRequired;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('descEnField'),
                      controller: _descEnController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: localizations.signupSheetDescEnLabel,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('descMrField'),
                      controller: _descMrController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: localizations.signupSheetDescMrLabel,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _requiresJoinCode,
                      title: Text(
                        localizations.signupSheetRequiresJoinCodeLabel,
                      ),
                      onChanged: (value) {
                        setState(() => _requiresJoinCode = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      localizations.signupSheetSlotsHeading,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (_slots.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(localizations.signupSheetNoSlotsMessage),
                      )
                    else
                      for (var i = 0; i < _slots.length; i++)
                        SlotFormRow(
                          key: ValueKey(_slots[i]),
                          index: i,
                          labelEnController: _slots[i].labelEnController,
                          labelMrController: _slots[i].labelMrController,
                          capacityController: _slots[i].capacityController,
                          suggestedAmountController:
                              _slots[i].suggestedAmountController,
                          date: _slots[i].date,
                          onDateChanged: (date) {
                            setState(() => _slots[i].date = date);
                          },
                          onRemove: () => _removeSlot(i),
                          onMoveUp: i == 0 ? null : () => _moveSlotUp(i),
                          onMoveDown: i == _slots.length - 1
                              ? null
                              : () => _moveSlotDown(i),
                        ),
                    if (_slotsError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 8),
                        child: Text(
                          _slotsError!,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.add),
                      label: Text(localizations.signupSheetAddSlotButton),
                      onPressed: _addSlot,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(localizations.signupSheetSaveButton),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

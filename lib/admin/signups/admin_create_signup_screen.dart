import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/widgets/fitted_app_bar_title.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/widgets/slot_form_row.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/admin_user.dart';
import 'package:gajanan_maharaj_sevekari/models/signup.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';
import 'package:gajanan_maharaj_sevekari/providers/signup_service.dart';
import 'package:gajanan_maharaj_sevekari/utils/form_utils.dart';
import 'package:gajanan_maharaj_sevekari/utils/join_code_generator.dart';
import 'package:gajanan_maharaj_sevekari/utils/slot_schedule.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gajanan_maharaj_sevekari/widgets/english_only.dart';

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

class AdminCreateSignupScreen extends StatefulWidget {
  final AdminUser adminUser;

  /// Injected for testing; defaults to [FirebaseFirestore.instance].
  @visibleForTesting
  final FirebaseFirestore? firestore;

  /// Injected for testing; defaults to [FirebaseStorage.instance].
  @visibleForTesting
  final FirebaseStorage? storage;

  /// Injected for testing.
  @visibleForTesting
  final SignupService? signupService;

  const AdminCreateSignupScreen({
    super.key,
    required this.adminUser,
    this.firestore,
    this.storage,
    this.signupService,
  });

  @override
  State<AdminCreateSignupScreen> createState() =>
      _AdminCreateSignupScreenState();
}

class _AdminCreateSignupScreenState extends State<AdminCreateSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleEnController = TextEditingController();
  final _titleMrController = TextEditingController();
  final _descEnController = TextEditingController();
  final _descMrController = TextEditingController();

  bool _requiresJoinCode = false;
  bool _isLoading = false;
  String? _slotsError;
  final List<_SlotFormRowData> _slots = [];

  Uint8List? _headerImageBytes;
  String? _headerImageContentType;
  String? _imageError;

  late final SignupService _service;

  @override
  void initState() {
    super.initState();
    // Only constructs a real SignupService (and only then touches
    // FirebaseFirestore.instance/FirebaseStorage.instance as fallbacks)
    // when no signupService override is supplied - a test that injects
    // one shouldn't need Firebase initialized at all.
    _service =
        widget.signupService ??
        SignupService(firestore: widget.firestore, storage: widget.storage);
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

  Future<void> _pickImage() async {
    final localizations = lookupAppLocalizations(const Locale('en'));
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    if (!mounted) return;

    if (bytes.length > SignupService.maxHeaderImageBytes) {
      setState(() => _imageError = localizations.signupImageTooLargeError);
      return;
    }

    setState(() {
      _headerImageBytes = bytes;
      _headerImageContentType = picked.mimeType ?? 'image/jpeg';
      _imageError = null;
    });
  }

  void _removeImage() {
    setState(() {
      _headerImageBytes = null;
      _headerImageContentType = null;
      _imageError = null;
    });
  }

  Future<void> _submit() async {
    final localizations = lookupAppLocalizations(const Locale('en'));
    final formValid = _formKey.currentState!.validate();
    final hasSlots = _slots.isNotEmpty;

    setState(() {
      _slotsError = hasSlots ? null : localizations.signupSlotsRequiredError;
    });

    if (!formValid) revealFirstInvalidField(_formKey.currentContext);
    if (!formValid || !hasSlots) return;

    setState(() => _isLoading = true);

    // Hoisted above the try so the catch block can clean up an uploaded
    // image if the signup itself fails to save afterward - otherwise that
    // upload would be orphaned in Storage with nothing ever referencing it.
    String? signupId;
    try {
      final groupId = widget.adminUser.groupId;
      if (groupId == null) {
        throw Exception('Group ID is required to create a sign-up signup');
      }

      String? headerImageUrl;
      if (_headerImageBytes != null) {
        signupId = _service.newSignupId();
        headerImageUrl = await _service.uploadHeaderImage(
          signupId: signupId,
          bytes: _headerImageBytes!,
          contentType: _headerImageContentType!,
        );
      }

      final now = DateTime.now();
      final signup = Signup(
        id: signupId,
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
        headerImageUrl: headerImageUrl,
      );

      final slots = [
        for (var i = 0; i < _slots.length; i++) _buildSlot(i, now),
      ];

      await _service.createSignupWithSlots(signup, slots);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.signupCreateSuccess)),
        );
        Navigator.pop(context);
      }
    } on Exception catch (e) {
      // Deliberately catches Exception, not Error: an Error subtype here
      // (e.g. ArgumentError from a future bug) should crash visibly during
      // development rather than being masked behind this generic message.
      if (kDebugMode) {
        debugPrint('AdminCreateSignupScreen._submit error: $e');
      }
      if (signupId != null) {
        // Best-effort: an uploaded image whose signup never got created
        // would otherwise sit in Storage unreferenced forever. A cleanup
        // failure here doesn't change the user-facing outcome - the
        // original error below is what matters either way.
        try {
          await _service.deleteHeaderImageFile(signupId);
        } on Exception catch (_) {}
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.signupCreateError)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// The slot for form row [index]. The form has validated that a date was
  /// picked, so resolving can't fail here; that would be a programming error.
  SignupSlot _buildSlot(int index, DateTime now) {
    final row = _slots[index];
    final schedule = resolveSlotSchedule(
      SlotScheduleInput(startDate: row.date),
    );
    if (schedule is! SlotScheduleResolved) {
      throw StateError('Slot ${index + 1} has no valid schedule: $schedule');
    }
    return SignupSlot(
      labelEn: row.labelEnController.text.trim(),
      labelMr: row.labelMrController.text.trim(),
      startAt: schedule.startAt,
      endAt: schedule.endAt,
      capacity: int.parse(row.capacityController.text.trim()),
      suggestedAmount: double.tryParse(
        row.suggestedAmountController.text.trim(),
      ),
      sortOrder: index,
      createdAt: now,
    );
  }

  @override
  Widget build(BuildContext context) => EnglishOnly(builder: _buildScreen);

  Widget _buildScreen(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: FittedAppBarTitle(localizations.adminCreateSignupTitle),
      ),
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
                        labelText: localizations.signupTitleEnLabel,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return localizations.signupTitleEnRequired;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('titleMrField'),
                      controller: _titleMrController,
                      decoration: InputDecoration(
                        labelText: localizations.signupTitleMrLabel,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('descEnField'),
                      controller: _descEnController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: localizations.signupDescEnLabel,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('descMrField'),
                      controller: _descMrController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: localizations.signupDescMrLabel,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      localizations.signupHeaderImageLabel,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (_headerImageBytes != null)
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              _headerImageBytes!,
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: IconButton(
                              key: const Key('removeHeaderImageButton'),
                              icon: const Icon(Icons.close),
                              tooltip: localizations.signupRemoveImageButton,
                              style: IconButton.styleFrom(
                                backgroundColor: theme.colorScheme.surface,
                              ),
                              onPressed: _removeImage,
                            ),
                          ),
                        ],
                      )
                    else
                      OutlinedButton.icon(
                        key: const Key('addHeaderImageButton'),
                        icon: const Icon(Icons.image_outlined),
                        label: Text(localizations.signupAddImageButton),
                        onPressed: _pickImage,
                      ),
                    if (_imageError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _imageError!,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _requiresJoinCode,
                      title: Text(localizations.signupRequiresJoinCodeLabel),
                      onChanged: (value) {
                        setState(() => _requiresJoinCode = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      localizations.signupSlotsHeading,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (_slots.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(localizations.signupNoSlotsMessage),
                      )
                    else
                      for (var i = 0; i < _slots.length; i++)
                        SlotFormRow(
                          key: ObjectKey(_slots[i]),
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
                      label: Text(localizations.signupAddSlotButton),
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
                      child: Text(localizations.signupSaveButton),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

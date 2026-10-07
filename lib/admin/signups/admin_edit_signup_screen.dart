import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/widgets/unsaved_changes_guard.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup.dart';
import 'package:gajanan_maharaj_sevekari/providers/signup_service.dart';
import 'package:gajanan_maharaj_sevekari/utils/form_utils.dart';
import 'package:gajanan_maharaj_sevekari/utils/join_code_generator.dart';
import 'package:gajanan_maharaj_sevekari/widgets/english_only.dart';
import 'package:gajanan_maharaj_sevekari/widgets/fitted_app_bar_title.dart';

/// An admin changing a sign-up's title, description and whether it needs a
/// join code. Reached from the Edit button on [AdminSignupDetailScreen]; closes
/// with `true` once saved. Its status, group and header image are changed
/// elsewhere on the detail page, and its slots on the Slots page.
///
/// Turning the join code on makes a new code and turning it off removes it, so
/// the admin is asked to confirm either - links shared earlier stop matching.
class AdminEditSignupScreen extends StatefulWidget {
  final Signup signup;

  /// Injected for testing; defaults to [FirebaseFirestore.instance].
  @visibleForTesting
  final FirebaseFirestore? firestore;

  /// Injected for testing.
  @visibleForTesting
  final SignupService? signupService;

  const AdminEditSignupScreen({
    super.key,
    required this.signup,
    this.firestore,
    this.signupService,
  });

  @override
  State<AdminEditSignupScreen> createState() => _AdminEditSignupScreenState();
}

class _AdminEditSignupScreenState extends State<AdminEditSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  late final SignupService _service;
  late final TextEditingController _titleEn;
  late final TextEditingController _titleMr;
  late final TextEditingController _descEn;
  late final TextEditingController _descMr;
  late bool _requiresJoinCode;

  bool _saving = false;
  bool _dirty = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final signup = widget.signup;
    _service =
        widget.signupService ?? SignupService(firestore: widget.firestore);
    _titleEn = TextEditingController(text: signup.titleEn);
    _titleMr = TextEditingController(text: signup.titleMr);
    _descEn = TextEditingController(text: signup.descriptionEn);
    _descMr = TextEditingController(text: signup.descriptionMr);
    _requiresJoinCode = signup.requiresJoinCode;
    for (final controller in [_titleEn, _titleMr, _descEn, _descMr]) {
      controller.addListener(_refreshDirty);
    }
  }

  @override
  void dispose() {
    _titleEn.dispose();
    _titleMr.dispose();
    _descEn.dispose();
    _descMr.dispose();
    super.dispose();
  }

  /// Whether anything differs from the sign-up as it was opened. Changing a
  /// field back to what it was clears this again.
  bool get _hasChanges {
    final signup = widget.signup;
    return _titleEn.text != signup.titleEn ||
        _titleMr.text != signup.titleMr ||
        _descEn.text != signup.descriptionEn ||
        _descMr.text != signup.descriptionMr ||
        _requiresJoinCode != signup.requiresJoinCode;
  }

  /// Called when anything is edited: refreshes whether there are unsaved
  /// changes, and drops the message from a failed save, which no longer
  /// describes what is on screen.
  void _refreshDirty() {
    final dirty = _hasChanges;
    if (dirty != _dirty || _errorText != null) {
      setState(() {
        _dirty = dirty;
        _errorText = null;
      });
    }
  }

  void _setRequiresJoinCode(bool value) {
    _requiresJoinCode = value;
    _refreshDirty();
    setState(() {});
  }

  /// Asks the admin to confirm switching the join code on or off. True if
  /// they did, or if the switch is as it was.
  Future<bool> _confirmJoinCodeChange(AppLocalizations l10n) async {
    if (_requiresJoinCode == widget.signup.requiresJoinCode) return true;
    final turningOn = _requiresJoinCode;
    final confirmed = await showEnglishDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          turningOn ? l10n.signupJoinCodeOnTitle : l10n.signupJoinCodeOffTitle,
        ),
        content: Text(
          turningOn
              ? l10n.signupJoinCodeOnMessage
              : l10n.signupJoinCodeOffMessage,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.signupSaveButton),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  /// Writes the changes. Returns the message to show if they couldn't be
  /// saved, or null once they are.
  Future<String?> _persist(AppLocalizations l10n) async {
    final signup = widget.signup;
    try {
      await _service.updateSignupDetails(
        signup.id!,
        titleEn: _titleEn.text.trim(),
        titleMr: _titleMr.text.trim(),
        descriptionEn: _descEn.text.trim(),
        descriptionMr: _descMr.text.trim(),
        requiresJoinCode: _requiresJoinCode,
        joinCode: joinCodeAfterEdit(
          wasRequired: signup.requiresJoinCode,
          currentCode: signup.joinCode,
          nowRequired: _requiresJoinCode,
        ),
      );
      return null;
    } on Exception catch (e) {
      debugPrint('AdminEditSignupScreen save failed: $e');
      return l10n.signupUpdateError;
    }
  }

  Future<void> _save(AppLocalizations l10n) async {
    if (_saving) return;
    if (!_hasChanges) {
      // Nothing to write; closing without `true` means no confirmation.
      Navigator.pop(context, false);
      return;
    }
    if (!_formKey.currentState!.validate()) {
      revealFirstInvalidField(_formKey.currentContext);
      return;
    }
    if (!await _confirmJoinCodeChange(l10n) || !mounted) return;

    setState(() {
      _saving = true;
      _errorText = null;
    });
    String? error;
    var finished = false;
    try {
      error = await _persist(l10n);
      finished = true;
    } finally {
      // Also runs when an Error escapes, so the screen is never left
      // spinning behind a button that can't be pressed.
      if (mounted && (!finished || error != null)) {
        setState(() {
          _saving = false;
          _errorText = error;
        });
      }
    }
    if (error == null && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => EnglishOnly(builder: _buildScreen);

  Widget _buildScreen(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return UnsavedChangesGuard(
      hasUnsavedChanges: _dirty,
      busy: _saving,
      child: Scaffold(
        appBar: AppBar(title: FittedAppBarTitle(l10n.signupEditSignupTitle)),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _field(
                  'titleEnField',
                  _titleEn,
                  l10n.signupTitleEnLabel,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? l10n.signupTitleEnRequired
                      : null,
                ),
                _field('titleMrField', _titleMr, l10n.signupTitleMrLabel),
                _field(
                  'descEnField',
                  _descEn,
                  l10n.signupDescEnLabel,
                  maxLines: 3,
                ),
                _field(
                  'descMrField',
                  _descMr,
                  l10n.signupDescMrLabel,
                  maxLines: 3,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _requiresJoinCode,
                  title: Text(l10n.signupRequiresJoinCodeLabel),
                  onChanged: _saving ? null : _setRequiresJoinCode,
                ),
                const SizedBox(height: 16),
                if (_errorText != null) _buildError(context),
                _buildSaveButton(context, l10n),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    String key,
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    FormFieldValidator<String>? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      key: Key(key),
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: validator,
    ),
  );

  Widget _buildError(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Semantics(
      liveRegion: true,
      child: Text(
        _errorText!,
        style: TextStyle(color: Theme.of(context).appColors.error),
      ),
    ),
  );

  Widget _buildSaveButton(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return ElevatedButton(
      onPressed: _saving ? null : () => _save(l10n),
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: _saving
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(l10n.signupSaveButton),
    );
  }
}

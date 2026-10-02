import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_entry.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_sheet.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';
import 'package:gajanan_maharaj_sevekari/providers/signup_service.dart';
import 'package:gajanan_maharaj_sevekari/signups/widgets/claim_slot_dialog.dart';
import 'package:gajanan_maharaj_sevekari/signups/widgets/my_signups_section.dart';
import 'package:gajanan_maharaj_sevekari/signups/widgets/signup_slot_tile.dart';
import 'package:gajanan_maharaj_sevekari/utils/unique_id_service.dart';

class SignupSheetDetailScreen extends StatefulWidget {
  final String? sheetId;

  /// Injected for testing; defaults to fetching the real device ID.
  @visibleForTesting
  final String? deviceId;

  /// Injected for testing; defaults to [FirebaseFirestore.instance].
  @visibleForTesting
  final FirebaseFirestore? firestore;

  /// Injected for testing.
  @visibleForTesting
  final SignupService? signupService;

  const SignupSheetDetailScreen({
    super.key,
    this.sheetId,
    this.deviceId,
    this.firestore,
    this.signupService,
  });

  @override
  State<SignupSheetDetailScreen> createState() =>
      _SignupSheetDetailScreenState();
}

class _SignupSheetDetailScreenState extends State<SignupSheetDetailScreen> {
  late final SignupService _service;
  String? _deviceId;
  String _sheetId = '';
  Stream<SignupSheet?>? _sheetStream;
  Stream<List<SignupSlot>>? _slotsStream;
  Stream<List<SignupEntry>>? _entriesStream;

  @override
  void initState() {
    super.initState();
    _service =
        widget.signupService ?? SignupService(firestore: widget.firestore);
    _deviceId = widget.deviceId;
    if (_deviceId == null) {
      _getDeviceId();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newId = _getEffectiveSheetId(context);
    if (newId != _sheetId) {
      _sheetId = newId;
      _sheetStream = _service.getSheetById(_sheetId);
      _slotsStream = _service.getSlots(_sheetId);
      _updateEntriesStream();
    }
  }

  /// Caches the "my entries" stream by field, like [_sheetStream]/
  /// [_slotsStream], instead of creating it inline in build() - otherwise
  /// every rebuild would tear down and resubscribe it, resetting "My
  /// Signups" to loading and churning a Firestore listener for no reason.
  void _updateEntriesStream() {
    if (_deviceId != null) {
      _entriesStream = _service.getEntriesByDevice(_sheetId, _deviceId!);
    }
  }

  Future<void> _getDeviceId() async {
    final id = await UniqueIdService.getUniqueId();
    if (mounted) {
      setState(() {
        _deviceId = id;
        _updateEntriesStream();
      });
    }
  }

  String _getEffectiveSheetId(BuildContext context) {
    if (widget.sheetId != null && widget.sheetId!.isNotEmpty) {
      return widget.sheetId!;
    }
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    return args?['sheetId'] as String? ?? '';
  }

  Future<void> _claimSlot(
    SignupSheet sheet,
    SignupSlot slot,
    AppLocalizations l10n,
  ) async {
    final claimed = await showDialog<bool>(
      context: context,
      builder: (_) => ClaimSlotDialog(
        sheetId: _sheetId,
        slot: slot,
        requiresJoinCode: sheet.requiresJoinCode,
        deviceId: _deviceId,
        signupService: _service,
      ),
    );

    if (claimed == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.signupClaimSuccess)));
    }
  }

  void _confirmCancelEntry(SignupEntry entry, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l10n.signupCancelSignupConfirmTitle),
        content: Text(l10n.signupCancelSignupConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(l10n.no),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              _cancelEntry(entry, l10n);
            },
            child: Text(
              l10n.yes,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelEntry(SignupEntry entry, AppLocalizations l10n) async {
    try {
      await _service.cancelEntry(_sheetId, entry.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.signupCancelSignupSuccess)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.signupCancelSignupError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isMarathi = Localizations.localeOf(context).languageCode == 'mr';

    return StreamBuilder<SignupSheet?>(
      stream: _sheetStream,
      builder: (context, sheetSnapshot) {
        if (_deviceId == null ||
            sheetSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.signupsListTitle)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final sheet = sheetSnapshot.data;
        if (sheet == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.signupsListTitle)),
            body: Center(
              child: Text(
                l10n.signupNotFound,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.appColors.secondaryText,
                ),
              ),
            ),
          );
        }

        final title = isMarathi
            ? (sheet.titleMr.isNotEmpty ? sheet.titleMr : sheet.titleEn)
            : (sheet.titleEn.isNotEmpty ? sheet.titleEn : sheet.titleMr);
        final desc = isMarathi
            ? (sheet.descriptionMr.isNotEmpty
                  ? sheet.descriptionMr
                  : sheet.descriptionEn)
            : (sheet.descriptionEn.isNotEmpty
                  ? sheet.descriptionEn
                  : sheet.descriptionMr);

        return Scaffold(
          appBar: AppBar(title: Text(title)),
          body: StreamBuilder<List<SignupSlot>>(
            stream: _slotsStream,
            builder: (context, slotsSnapshot) {
              final slots = slotsSnapshot.data ?? const [];

              return StreamBuilder<List<SignupEntry>>(
                stream: _entriesStream,
                builder: (context, myEntriesSnapshot) {
                  final myEntries = myEntriesSnapshot.data ?? const [];

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (sheet.headerImageUrl != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            sheet.headerImageUrl!,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            semanticLabel: l10n.signupHeaderImageLabel,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  height: 180,
                                  width: double.infinity,
                                  color: theme.appColors.secondaryText
                                      .withValues(alpha: 0.1),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    color: theme.appColors.secondaryText,
                                  ),
                                ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (desc.isNotEmpty) ...[
                        Text(
                          desc,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.appColors.secondaryText,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      MySignupsSection(
                        entries: myEntries,
                        onCancelEntry: (entry) =>
                            _confirmCancelEntry(entry, l10n),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l10n.signupSlotsHeading,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final slot in slots)
                        SignupSlotTile(
                          slot: slot,
                          onTap: slot.claimedCount >= slot.capacity
                              ? null
                              : () => _claimSlot(sheet, slot, l10n),
                        ),
                    ],
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

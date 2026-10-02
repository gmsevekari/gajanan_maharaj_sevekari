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
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:gajanan_maharaj_sevekari/utils/unique_id_service.dart';
import 'package:gajanan_maharaj_sevekari/widgets/themed_icon.dart';

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
      // All entries, not just this device's - the slot tiles below need
      // every devotee's name to show who's signed up, and "My Signups" is
      // just this same stream filtered client-side by deviceId, so one
      // listener covers both instead of running two.
      _entriesStream = _service.getAllEntries(_sheetId);
    }
  }

  Future<void> _getDeviceId() async {
    final id = await UniqueIdService.getUniqueId();
    if (mounted) {
      setState(() => _deviceId = id);
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

  List<Widget> _buildAppBarActions(BuildContext context) => [
    IconButton(
      icon: const ThemedIcon(LogicalIcon.home),
      onPressed: () => Navigator.pushNamedAndRemoveUntil(
        context,
        Routes.home,
        (route) => false,
      ),
    ),
    IconButton(
      icon: const ThemedIcon(LogicalIcon.settings),
      onPressed: () => Navigator.pushNamed(context, Routes.settings),
    ),
  ];

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
            appBar: AppBar(
              title: Text(l10n.signupsListTitle),
              actions: _buildAppBarActions(context),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final sheet = sheetSnapshot.data;
        if (sheet == null) {
          return Scaffold(
            appBar: AppBar(
              title: Text(l10n.signupsListTitle),
              actions: _buildAppBarActions(context),
            ),
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
          appBar: AppBar(
            title: Text(title),
            actions: _buildAppBarActions(context),
          ),
          body: StreamBuilder<List<SignupSlot>>(
            stream: _slotsStream,
            builder: (context, slotsSnapshot) {
              final slots = slotsSnapshot.data ?? const [];

              return StreamBuilder<List<SignupEntry>>(
                stream: _entriesStream,
                builder: (context, entriesSnapshot) {
                  final allEntries = entriesSnapshot.data ?? const [];
                  final myEntries = allEntries
                      .where((e) => e.deviceId == _deviceId)
                      .toList();

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (sheet.headerImageUrl != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: ConstrainedBox(
                            // No fixed height: the image lays out at its
                            // own resolution (width-matched, aspect-ratio
                            // preserved) so nothing is cropped, with this
                            // minimum only as a floor for small images and
                            // a stable placeholder while loading.
                            constraints: const BoxConstraints(minHeight: 180),
                            child: Image.network(
                              sheet.headerImageUrl!,
                              width: double.infinity,
                              fit: BoxFit.fitWidth,
                              semanticLabel: l10n.signupHeaderImageLabel,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return Container(
                                  constraints: const BoxConstraints(
                                    minHeight: 180,
                                  ),
                                  width: double.infinity,
                                  alignment: Alignment.center,
                                  child: const CircularProgressIndicator(),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    constraints: const BoxConstraints(
                                      minHeight: 180,
                                    ),
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
                        slots: slots,
                        onCancelEntry: (entry) =>
                            _confirmCancelEntry(entry, l10n),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l10n.signupSlotsSectionHeading,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final slot in slots)
                        SignupSlotTile(
                          slot: slot,
                          entries: allEntries
                              .where((e) => e.slotId == slot.id)
                              .toList(),
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

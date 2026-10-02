import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/widgets/admin_entry_edit_dialog.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/widgets/admin_slot_entries_section.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/widgets/signup_sheet_actions_row.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/widgets/signup_sheet_export_card.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/widgets/signup_sheet_header_image_card.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/widgets/signup_sheet_join_code_card.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/widgets/signup_sheet_overview_card.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/widgets/signup_sheet_status_section.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/admin_user.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_entry.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_sheet.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';
import 'package:gajanan_maharaj_sevekari/providers/app_config_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/signup_service.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

class AdminSignupSheetDetailScreen extends StatefulWidget {
  final String? sheetId;
  final AdminUser? adminUser;

  /// Injected for testing; defaults to [FirebaseFirestore.instance].
  @visibleForTesting
  final FirebaseFirestore? firestore;

  /// Injected for testing.
  @visibleForTesting
  final SignupService? signupService;

  /// Injected for testing; defaults to [FirebaseStorage.instance]. Only
  /// used when [signupService] is not provided.
  @visibleForTesting
  final FirebaseStorage? storage;

  /// Overrides the export screenshot capture; injected for testing since
  /// [ScreenshotController.capture] returns null in the widget-test
  /// environment (no real rendering surface), making the real
  /// file-write/share logic otherwise unreachable in tests. Defaults to
  /// the real [ScreenshotController.capture].
  @visibleForTesting
  final Future<Uint8List?> Function()? exportCapture;

  const AdminSignupSheetDetailScreen({
    super.key,
    this.sheetId,
    this.adminUser,
    this.firestore,
    this.signupService,
    this.storage,
    this.exportCapture,
  });

  @override
  State<AdminSignupSheetDetailScreen> createState() =>
      _AdminSignupSheetDetailScreenState();
}

class _AdminSignupSheetDetailScreenState
    extends State<AdminSignupSheetDetailScreen> {
  static const double _offscreenExportOffset = 9999;

  late final SignupService _service;
  final ScreenshotController _exportController = ScreenshotController();
  bool _isProcessing = false;
  bool _isProcessingImage = false;
  String _sheetId = '';
  Stream<SignupSheet?>? _sheetStream;
  Stream<List<SignupSlot>>? _slotsStream;
  Stream<List<SignupEntry>>? _entriesStream;

  @override
  void initState() {
    super.initState();
    _service =
        widget.signupService ??
        SignupService(firestore: widget.firestore, storage: widget.storage);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newId = _getEffectiveSheetId(context);
    if (newId != _sheetId) {
      _sheetId = newId;
      _sheetStream = _service.getSheetById(_sheetId);
      _slotsStream = _service.getSlots(_sheetId);
      _entriesStream = _service.getAllEntries(_sheetId);
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

  AdminUser _getEffectiveAdminUser(BuildContext context) {
    if (widget.adminUser != null) {
      return widget.adminUser!;
    }
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    return args?['adminUser'] as AdminUser? ??
        const AdminUser(email: '', roles: []);
  }

  Future<void> _shareDeepLink(
    SignupSheet sheet,
    AppLocalizations l10n,
    bool isMarathi,
  ) async {
    final title = isMarathi
        ? (sheet.titleMr.isNotEmpty ? sheet.titleMr : sheet.titleEn)
        : (sheet.titleEn.isNotEmpty ? sheet.titleEn : sheet.titleMr);
    final joinCodePart = sheet.requiresJoinCode && sheet.joinCode != null
        ? '\n${l10n.signupSheetJoinCodePrefix}${sheet.joinCode}'
        : '';
    final codeQuery = sheet.requiresJoinCode && sheet.joinCode != null
        ? '?joinCode=${sheet.joinCode}'
        : '';
    final url =
        'https://gajananmaharajsevekari.org/signup/${sheet.id}$codeQuery';

    final text =
        '${l10n.signupSheetSharePrefix}: $title$joinCodePart\n\n${l10n.signupSheetShareLinkPrefix}: $url';

    await SharePlus.instance.share(ShareParams(text: text));
  }

  Future<void> _duplicateSheet(
    SignupSheet sheet,
    AdminUser adminUser,
    AppLocalizations l10n,
  ) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final newSheetId = await _service.duplicateSheet(sheet.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l10n.signupSheetDuplicateSuccess)),
        );
      Navigator.pushReplacementNamed(
        context,
        Routes.adminSignupSheetDetail,
        arguments: {'sheetId': newSheetId, 'adminUser': adminUser},
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.signupSheetDuplicateError)));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _updateStatus(
    SignupSheet sheet,
    SignupSheetStatus newStatus,
    AppLocalizations l10n,
  ) async {
    try {
      await _service.updateSheetStatus(sheet.id!, newStatus);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.statusUpdateSuccess)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l10n.signupSheetStatusUpdateError)),
        );
    }
  }

  Future<void> _exportSummaryImage(
    SignupSheet sheet,
    List<SignupSlot> slots,
    List<SignupEntry> entries,
    AppLocalizations l10n,
  ) async {
    try {
      final capture = widget.exportCapture ?? _exportController.capture;
      final imageBytes = await capture();
      if (imageBytes == null) return;

      final tempDir = await getTemporaryDirectory();
      final file = await File(
        '${tempDir.path}/signup_sheet_${sheet.id ?? "summary"}.png',
      ).writeAsBytes(imageBytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: l10n.signupSheetExportSummaryTitle,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.signupSheetExportFailed)));
    }
  }

  void _showAddEntryDialog(
    SignupSheet sheet,
    SignupSlot slot,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (_) => AdminEntryEditDialog(
        onSave: (name, phone, email, pledge, note) async {
          try {
            final res = await _service.adminAddEntry(
              sheetId: sheet.id!,
              slotId: slot.id!,
              name: name,
              phone: phone,
              email: email,
              pledgeAmount: pledge,
              note: note,
            );
            if (!mounted) return;
            if (res['success'] == true) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(content: Text(l10n.signupSheetEntryAddSuccess)),
                );
            } else if (res['error'] == 'slot_full') {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(content: Text(l10n.signupSheetSlotFullError)),
                );
            } else {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(content: Text(l10n.signupSheetEntryAddError)),
                );
            }
          } catch (_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text(l10n.signupSheetEntryAddError)),
              );
          }
        },
      ),
    );
  }

  void _showEditEntryDialog(
    SignupSheet sheet,
    SignupEntry entry,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (_) => AdminEntryEditDialog(
        entry: entry,
        onSave: (name, phone, email, pledge, note) async {
          try {
            await _service.updateEntry(
              sheet.id!,
              entry.copyWith(
                name: name,
                phone: phone,
                email: email,
                pledgeAmount: pledge,
                note: note,
              ),
            );
            if (!mounted) return;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text(l10n.signupSheetEntryEditSuccess)),
              );
          } catch (_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text(l10n.signupSheetEntryEditError)),
              );
          }
        },
        onDelete: () => _removeEntry(sheet, entry, l10n),
      ),
    );
  }

  Future<void> _removeEntry(
    SignupSheet sheet,
    SignupEntry entry,
    AppLocalizations l10n,
  ) async {
    try {
      await _service.adminRemoveEntry(sheet.id!, entry.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l10n.signupSheetEntryRemoveSuccess)),
        );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l10n.signupSheetEntryRemoveError)),
        );
    }
  }

  void _confirmRemoveEntry(
    SignupSheet sheet,
    SignupEntry entry,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l10n.signupSheetRemoveEntryTitle),
        content: Text(l10n.signupSheetRemoveEntryConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(l10n.no),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              _removeEntry(sheet, entry, l10n);
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

  Future<void> _pickAndUploadImage(
    SignupSheet sheet,
    AppLocalizations l10n,
  ) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    if (!mounted) return;

    if (bytes.length > SignupService.maxHeaderImageBytes) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l10n.signupSheetImageTooLargeError)),
        );
      return;
    }

    setState(() => _isProcessingImage = true);
    try {
      final url = await _service.uploadHeaderImage(
        sheetId: sheet.id!,
        bytes: bytes,
        contentType: picked.mimeType ?? 'image/jpeg',
      );
      await _service.updateHeaderImageUrl(sheet.id!, url);
    } on Exception catch (_) {
      // Deliberately catches Exception, not Error: an Error subtype here
      // (e.g. a null-check failure from a future bug) should crash
      // visibly during development rather than being masked behind this
      // generic message.
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(l10n.signupSheetImageUploadError)),
          );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingImage = false);
      }
    }
  }

  Future<void> _removeImage(SignupSheet sheet, AppLocalizations l10n) async {
    setState(() => _isProcessingImage = true);
    try {
      await _service.removeHeaderImage(sheet.id!);
    } on Exception catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(l10n.signupSheetImageRemoveError)),
          );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingImage = false);
      }
    }
  }

  void _confirmRemoveImage(SignupSheet sheet, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l10n.signupSheetRemoveImageConfirmTitle),
        content: Text(l10n.signupSheetRemoveImageConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(l10n.no),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              _removeImage(sheet, l10n);
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final adminUser = _getEffectiveAdminUser(context);
    final isMarathi = Localizations.localeOf(context).languageCode == 'mr';

    final appConfig = context.watch<AppConfigProvider>().appConfig;
    final group = appConfig?.gajananMaharajGroups
        .where((g) => g.id == adminUser.groupId)
        .firstOrNull;
    final groupName = group != null
        ? (isMarathi
              ? (group.nameMr.isNotEmpty ? group.nameMr : group.nameEn)
              : (group.nameEn.isNotEmpty ? group.nameEn : group.nameMr))
        : '';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.adminSignupSheetDetailTitle)),
      body: StreamBuilder<SignupSheet?>(
        stream: _sheetStream,
        builder: (context, sheetSnapshot) {
          if (sheetSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final sheet = sheetSnapshot.data;
          if (sheet == null) {
            return Center(
              child: Text(
                l10n.signupSheetNotFound,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.appColors.secondaryText,
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

          return StreamBuilder<List<SignupSlot>>(
            stream: _slotsStream,
            builder: (context, slotsSnapshot) {
              final slots = slotsSnapshot.data ?? const [];

              return StreamBuilder<List<SignupEntry>>(
                stream: _entriesStream,
                builder: (context, entriesSnapshot) {
                  final entries = entriesSnapshot.data ?? const [];
                  final totalCapacity = slots.fold<int>(
                    0,
                    (total, s) => total + s.capacity,
                  );

                  return Stack(
                    children: [
                      // Offscreen export target for screenshot
                      Positioned(
                        left: -_offscreenExportOffset,
                        top: -_offscreenExportOffset,
                        child: Screenshot(
                          controller: _exportController,
                          child: SignupSheetExportCard(
                            sheet: sheet,
                            slots: slots,
                            totalClaims: entries.length,
                            totalCapacity: totalCapacity,
                            groupName: groupName,
                            l10n: l10n,
                            theme: theme,
                            langCode: isMarathi ? 'mr' : 'en',
                          ),
                        ),
                      ),
                      ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          SignupSheetOverviewCard(
                            title: title,
                            description: desc,
                            groupName: groupName,
                          ),
                          const SizedBox(height: 12),
                          SignupSheetHeaderImageCard(
                            headerImageUrl: sheet.headerImageUrl,
                            // Covers both the upload and remove flows: the
                            // card hides its buttons whenever this is true,
                            // so a remove-confirm tap can't race a replace
                            // tap (or vice versa) against the same object.
                            isUploading: _isProcessingImage,
                            onPickImage: () => _pickAndUploadImage(sheet, l10n),
                            onRemoveImage: sheet.headerImageUrl == null
                                ? null
                                : () => _confirmRemoveImage(sheet, l10n),
                          ),
                          if (sheet.requiresJoinCode &&
                              sheet.joinCode != null) ...[
                            const SizedBox(height: 12),
                            SignupSheetJoinCodeCard(joinCode: sheet.joinCode!),
                          ],
                          const SizedBox(height: 12),
                          SignupSheetStatusSection(
                            currentStatus: sheet.status,
                            onStatusChanged: (newStatus) =>
                                _updateStatus(sheet, newStatus, l10n),
                          ),
                          const SizedBox(height: 12),
                          SignupSheetActionsRow(
                            onDuplicate: () =>
                                _duplicateSheet(sheet, adminUser, l10n),
                            onShare: () =>
                                _shareDeepLink(sheet, l10n, isMarathi),
                            onExport: () => _exportSummaryImage(
                              sheet,
                              slots,
                              entries,
                              l10n,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            l10n.signupSheetSlotsSectionHeading,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...slots.map((slot) {
                            final slotEntries = entries
                                .where((e) => e.slotId == slot.id)
                                .toList();
                            return AdminSlotEntriesSection(
                              slot: slot,
                              entries: slotEntries,
                              onAddEntry: (s) =>
                                  _showAddEntryDialog(sheet, s, l10n),
                              onEditEntry: (e, _) =>
                                  _showEditEntryDialog(sheet, e, l10n),
                              onRemoveEntry: (e) =>
                                  _confirmRemoveEntry(sheet, e, l10n),
                            );
                          }),
                        ],
                      ),
                      if (_isProcessing)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.3),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

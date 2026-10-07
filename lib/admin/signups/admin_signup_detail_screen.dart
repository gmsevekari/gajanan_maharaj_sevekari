import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gajanan_maharaj_sevekari/widgets/fitted_app_bar_title.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/admin_edit_signup_screen.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/admin_signup_entries_screen.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/admin_signup_slots_screen.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/signup_entries_export_pages.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/widgets/export_slots_dialog.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/widgets/signup_actions_row.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/widgets/signup_entries_export_card.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/widgets/signup_export_card.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/widgets/signup_header_image_card.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/widgets/signup_overview_card.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/widgets/signup_status_section.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/admin_user.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_entry.dart';
import 'package:gajanan_maharaj_sevekari/models/signup.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';
import 'package:gajanan_maharaj_sevekari/providers/app_config_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/signup_service.dart';
import 'package:gajanan_maharaj_sevekari/signups/widgets/signup_nav_card.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:gajanan_maharaj_sevekari/widgets/themed_icon.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gajanan_maharaj_sevekari/widgets/english_only.dart';

class AdminSignupDetailScreen extends StatefulWidget {
  final String? signupId;
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

  /// Overrides how a sign-ups image is rendered from its card and pixel
  /// ratio; injected for testing. Defaults to
  /// [ScreenshotController.captureFromLongWidget].
  @visibleForTesting
  final Future<Uint8List> Function(Widget card, double pixelRatio)?
  entriesExportCapture;

  const AdminSignupDetailScreen({
    super.key,
    this.signupId,
    this.adminUser,
    this.firestore,
    this.signupService,
    this.storage,
    this.exportCapture,
    this.entriesExportCapture,
  });

  @override
  State<AdminSignupDetailScreen> createState() =>
      _AdminSignupDetailScreenState();
}

class _AdminSignupDetailScreenState extends State<AdminSignupDetailScreen> {
  static const double _offscreenExportOffset = 9999;

  static const Duration _entriesExportDelay = Duration(milliseconds: 200);

  late final SignupService _service;
  final ScreenshotController _exportController = ScreenshotController();
  bool _isProcessing = false;
  bool _isProcessingImage = false;
  String _signupId = '';
  Stream<Signup?>? _signupStream;
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
    final newId = _getEffectiveSignupId(context);
    if (newId != _signupId) {
      _signupId = newId;
      _signupStream = _service.getSignupById(_signupId);
      _slotsStream = _service.getSlots(_signupId);
      _entriesStream = _service.getAllEntries(_signupId);
    }
  }

  String _getEffectiveSignupId(BuildContext context) {
    if (widget.signupId != null && widget.signupId!.isNotEmpty) {
      return widget.signupId!;
    }
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    return args?['signupId'] as String? ?? '';
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
    Signup signup,
    AppLocalizations l10n,
    bool isMarathi,
  ) async {
    final title = isMarathi
        ? (signup.titleMr.isNotEmpty ? signup.titleMr : signup.titleEn)
        : (signup.titleEn.isNotEmpty ? signup.titleEn : signup.titleMr);
    final joinCodePart = signup.requiresJoinCode && signup.joinCode != null
        ? '\n${l10n.signupJoinCodePrefix}${signup.joinCode}'
        : '';
    final codeQuery = signup.requiresJoinCode && signup.joinCode != null
        ? '?joinCode=${signup.joinCode}'
        : '';
    final url =
        'https://gajananmaharajsevekari.org/signup/${signup.id}$codeQuery';

    final text =
        '${l10n.signupSharePrefix}: $title$joinCodePart\n\n${l10n.signupShareLinkPrefix}: $url';

    await SharePlus.instance.share(ShareParams(text: text));
  }

  Future<void> _editSignup(Signup signup) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AdminEditSignupScreen(signup: signup, signupService: _service),
      ),
    );
    if (saved != true || !mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            lookupAppLocalizations(const Locale('en')).signupUpdateSuccess,
          ),
        ),
      );
  }

  Future<void> _duplicateSignup(
    Signup signup,
    AdminUser adminUser,
    AppLocalizations l10n,
  ) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final newSignupId = await _service.duplicateSignup(signup.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.signupDuplicateSuccess)));
      Navigator.pushReplacementNamed(
        context,
        Routes.adminSignupDetail,
        arguments: {'signupId': newSignupId, 'adminUser': adminUser},
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.signupDuplicateError)));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _confirmDeleteSignup(Signup signup, AppLocalizations l10n) {
    showEnglishDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l10n.signupDeleteConfirmTitle),
        content: Text(l10n.signupDeleteConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              _deleteSignup(signup, l10n);
            },
            child: Text(
              l10n.delete,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSignup(Signup signup, AppLocalizations l10n) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      await _service.deleteSignup(signup.id!);
      if (!mounted) return;
      // Grab the messenger and navigator before popping: this screen's
      // context is gone afterwards, but the snackbar belongs to the
      // surviving ScaffoldMessenger and should show on the previous screen.
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.signupDeleteSuccess)));
    } on Exception catch (_) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.signupDeleteError)));
    }
  }

  Future<void> _updateStatus(
    Signup signup,
    SignupStatus newStatus,
    AppLocalizations l10n,
  ) async {
    try {
      await _service.updateSignupStatus(signup.id!, newStatus);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.statusUpdateSuccess)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.signupStatusUpdateError)));
    }
  }

  Future<void> _exportSummaryImage(
    Signup signup,
    List<SignupSlot> slots,
    List<SignupEntry> entries,
    AppLocalizations l10n,
  ) async {
    try {
      final capture = widget.exportCapture ?? _exportController.capture;
      final imageBytes = await capture();
      if (imageBytes == null) return;

      await _shareImages({
        'signup_${signup.id ?? "summary"}.png': imageBytes,
      }, text: l10n.signupExportSummaryTitle);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.signupExportFailed)));
    }
  }

  /// Saves each of [images] (PNG bytes by file name) and opens the share
  /// sheet with all of them.
  Future<void> _shareImages(
    Map<String, Uint8List> images, {
    required String text,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final files = [
      for (final image in images.entries)
        XFile(
          (await File(
            '${tempDir.path}/${image.key}',
          ).writeAsBytes(image.value)).path,
        ),
    ];
    await SharePlus.instance.share(ShareParams(files: files, text: text));
  }

  /// Asks which upcoming slots to include, then shares an image of the
  /// entries table for them: the same Date / Title / Name table devotees see.
  /// A long list is split over several images (see [paginateSignupExport]).
  Future<void> _exportSignupEntries(
    Signup signup,
    String title,
    String groupName,
    List<SignupSlot> slots,
    List<SignupEntry> entries,
    AppLocalizations l10n,
  ) async {
    if (_isProcessing) return;
    final chosen = await showExportSlotsDialog(
      context: context,
      slots: slots,
      now: DateTime.now(),
    );
    if (chosen == null || !mounted) return;

    final pages = paginateSignupExport(slots: chosen, entries: entries);
    if (pages.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.signupExportNoEntries)));
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final id = signup.id ?? 'export';
      final images = await _renderEntryPages(pages, title, groupName);
      if (!mounted) return;
      await _shareImages({
        for (var i = 0; i < images.length; i++)
          'signup_entries_$id${images.length > 1 ? '_${i + 1}' : ''}.png':
              images[i],
      }, text: title);
    } catch (e) {
      debugPrint('Sign-ups export failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.signupExportFailed)));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  /// One PNG per page, in order.
  Future<List<Uint8List>> _renderEntryPages(
    List<SignupExportPage> pages,
    String title,
    String groupName,
  ) async {
    final capture = widget.entriesExportCapture ?? _captureEntriesCard;
    final images = <Uint8List>[];
    for (var i = 0; i < pages.length; i++) {
      // The screen may have been closed while an earlier image was drawn.
      if (!mounted) return images;
      final card = SignupEntriesExportCard.scoped(
        context,
        SignupEntriesExportCard(
          title: title,
          groupName: groupName,
          entries: pages[i].entries,
          slots: pages[i].slots,
          part: i + 1,
          totalParts: pages.length,
        ),
      );
      images.add(await capture(card, pages[i].pixelRatio));
    }
    return images;
  }

  Future<Uint8List> _captureEntriesCard(Widget card, double pixelRatio) =>
      ScreenshotController().captureFromLongWidget(
        card,
        context: context,
        pixelRatio: pixelRatio,
        delay: _entriesExportDelay,
      );

  Future<void> _pickAndUploadImage(Signup signup, AppLocalizations l10n) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    if (!mounted) return;

    if (bytes.length > SignupService.maxHeaderImageBytes) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.signupImageTooLargeError)));
      return;
    }

    setState(() => _isProcessingImage = true);
    try {
      final url = await _service.uploadHeaderImage(
        signupId: signup.id!,
        bytes: bytes,
        contentType: picked.mimeType ?? 'image/jpeg',
      );
      await _service.updateHeaderImageUrl(signup.id!, url);
    } on Exception catch (_) {
      // Deliberately catches Exception, not Error: an Error subtype here
      // (e.g. a null-check failure from a future bug) should crash
      // visibly during development rather than being masked behind this
      // generic message.
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.signupImageUploadError)));
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingImage = false);
      }
    }
  }

  Future<void> _removeImage(Signup signup, AppLocalizations l10n) async {
    setState(() => _isProcessingImage = true);
    try {
      await _service.removeHeaderImage(signup.id!);
    } on Exception catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.signupImageRemoveError)));
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingImage = false);
      }
    }
  }

  void _confirmRemoveImage(Signup signup, AppLocalizations l10n) {
    showEnglishDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l10n.signupRemoveImageConfirmTitle),
        content: Text(l10n.signupRemoveImageConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(l10n.no),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              _removeImage(signup, l10n);
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

  void _openSlots(Signup signup) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminSignupSlotsScreen(
          signupId: _signupId,
          signup: signup,
          firestore: widget.firestore,
          signupService: _service,
        ),
      ),
    );
  }

  void _openEntries(Signup signup) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminSignupEntriesScreen(
          signupId: _signupId,
          signup: signup,
          firestore: widget.firestore,
          signupService: _service,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => EnglishOnly(builder: _buildScreen);

  Widget _buildScreen(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final adminUser = _getEffectiveAdminUser(context);
    final isMarathi = contentIsMarathi(context);

    final appConfig = context.watch<AppConfigProvider>().appConfig;
    final group = appConfig?.gajananMaharajGroups
        .where((g) => g.id == adminUser.groupId)
        .firstOrNull;
    final groupName = group != null
        ? (isMarathi
              ? (group.nameMr.isNotEmpty ? group.nameMr : group.nameEn)
              : (group.nameEn.isNotEmpty ? group.nameEn : group.nameMr))
        : '';

    return StreamBuilder<Signup?>(
      stream: _signupStream,
      builder: (context, signupSnapshot) {
        Scaffold page(String appBarTitle, Widget body) =>
            Scaffold(appBar: _buildAppBar(context, appBarTitle), body: body);

        if (signupSnapshot.connectionState == ConnectionState.waiting) {
          return page(
            l10n.adminSignupDetailTitle,
            const Center(child: CircularProgressIndicator()),
          );
        }

        final signup = signupSnapshot.data;
        if (signup == null) {
          return page(
            l10n.adminSignupDetailTitle,
            Center(
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
            ? (signup.titleMr.isNotEmpty ? signup.titleMr : signup.titleEn)
            : (signup.titleEn.isNotEmpty ? signup.titleEn : signup.titleMr);
        final desc = isMarathi
            ? (signup.descriptionMr.isNotEmpty
                  ? signup.descriptionMr
                  : signup.descriptionEn)
            : (signup.descriptionEn.isNotEmpty
                  ? signup.descriptionEn
                  : signup.descriptionMr);

        return page(
          title,
          StreamBuilder<List<SignupSlot>>(
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
                          child: SignupExportCard(
                            signup: signup,
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
                          SignupOverviewCard(
                            title: title,
                            groupName: groupName,
                            status: signup.status,
                            joinCode: signup.requiresJoinCode
                                ? signup.joinCode
                                : null,
                            onEdit: () => _editSignup(signup),
                            onDelete: () => _confirmDeleteSignup(signup, l10n),
                          ),
                          const SizedBox(height: 12),
                          SignupHeaderImageCard(
                            headerImageUrl: signup.headerImageUrl,
                            // Covers both the upload and remove flows: the
                            // card hides its buttons whenever this is true,
                            // so a remove-confirm tap can't race a replace
                            // tap (or vice versa) against the same object.
                            isUploading: _isProcessingImage,
                            onPickImage: () =>
                                _pickAndUploadImage(signup, l10n),
                            onRemoveImage: signup.headerImageUrl == null
                                ? null
                                : () => _confirmRemoveImage(signup, l10n),
                          ),
                          if (desc.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              desc,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.appColors.secondaryText,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          SignupStatusSection(
                            currentStatus: signup.status,
                            onStatusChanged: (newStatus) =>
                                _updateStatus(signup, newStatus, l10n),
                          ),
                          const SizedBox(height: 12),
                          SignupActionsRow(
                            onDuplicate: () =>
                                _duplicateSignup(signup, adminUser, l10n),
                            onShare: () =>
                                _shareDeepLink(signup, l10n, isMarathi),
                            onExport: () => _exportSummaryImage(
                              signup,
                              slots,
                              entries,
                              l10n,
                            ),
                            onExportSignups: () => _exportSignupEntries(
                              signup,
                              title,
                              groupName,
                              slots,
                              entries,
                              l10n,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SignupNavCard(
                            icon: Icons.event_seat_outlined,
                            label: l10n.signupSlotsHeading,
                            onTap: () => _openSlots(signup),
                          ),
                          const SizedBox(height: 12),
                          SignupNavCard(
                            icon: Icons.table_rows_outlined,
                            label: l10n.signupEntriesHeading,
                            onTap: () => _openEntries(signup),
                          ),
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
          ),
        );
      },
    );
  }

  AppBar _buildAppBar(BuildContext context, String title) => AppBar(
    title: FittedAppBarTitle(title),
    actions: [
      IconButton(
        icon: const ThemedIcon(LogicalIcon.home),
        onPressed: () =>
            Navigator.of(context).popUntil((route) => route.isFirst),
      ),
      IconButton(
        icon: const ThemedIcon(LogicalIcon.settings),
        onPressed: () => Navigator.pushNamed(context, Routes.settings),
      ),
    ],
  );
}

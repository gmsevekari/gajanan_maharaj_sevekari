import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/vaari_event.dart';
import 'package:gajanan_maharaj_sevekari/models/vaari_participant.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:gajanan_maharaj_sevekari/widgets/themed_icon.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/app_config_provider.dart';
import 'package:gajanan_maharaj_sevekari/models/app_config.dart';
import 'package:gajanan_maharaj_sevekari/utils/marathi_utils.dart';
import 'package:gajanan_maharaj_sevekari/utils/date_time_utils.dart';
import 'package:gajanan_maharaj_sevekari/admin/widgets/admin_stats_widgets.dart';
import 'package:gajanan_maharaj_sevekari/admin/admin_audit_service.dart';
import 'package:gajanan_maharaj_sevekari/admin/vaari/widgets/vaari_export_card.dart';
import 'package:gajanan_maharaj_sevekari/models/admin_user.dart';

class AdminVaariDetailScreen extends StatefulWidget {
  final String eventId;
  final AdminUser adminUser;
  final FirebaseFirestore? firestore;

  const AdminVaariDetailScreen({
    super.key,
    required this.eventId,
    required this.adminUser,
    this.firestore,
  });

  @override
  State<AdminVaariDetailScreen> createState() => _AdminVaariDetailScreenState();
}

class _AdminVaariDetailScreenState extends State<AdminVaariDetailScreen> {
  late final FirebaseFirestore _firestore;
  late Stream<DocumentSnapshot> _eventStream;
  late Stream<QuerySnapshot> _participantsStream;
  final ScreenshotController _screenshotController = ScreenshotController();
  final ScreenshotController _exportController = ScreenshotController();
  int _latestParticipantCount = 0;
  bool _isStatusLocked = true;

  @override
  void initState() {
    super.initState();
    _firestore = widget.firestore ?? FirebaseFirestore.instance;
    _eventStream = _firestore
        .collection('vaari_events')
        .doc(widget.eventId)
        .snapshots();
    _participantsStream = _firestore
        .collection('vaari_events')
        .doc(widget.eventId)
        .collection('participants')
        .orderBy('joinedAt', descending: false)
        .snapshots();
  }

  Future<void> _shareDeepLink(
    VaariEvent event,
    AppLocalizations l10n,
    bool isEnglish,
  ) async {
    final title = isEnglish ? event.nameEn : event.nameMr;
    final shareText =
        '${l10n.adminVaariSharePrefix}: $title\n${l10n.adminVaariJoinCode}: ${event.joinCode}\n\n${l10n.adminVaariShareLinkPrefix}: https://gajananmaharajsevekari.org/vaari/${event.id}?joinCode=${event.joinCode}';
    await SharePlus.instance.share(ShareParams(text: shareText));
  }

  Future<void> _updateStatus(VaariEvent event, String? newStatus) async {
    if (newStatus == null || newStatus == event.status) return;

    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(l10n.updatingStatus),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      await _firestore.collection('vaari_events').doc(event.id).update({
        'status': newStatus,
      });

      await AdminAuditService.logAction(
        action: 'UPDATE_VAARI_STATUS',
        details: {
          'event_id': event.id,
          'old_status': event.status,
          'new_status': newStatus,
        },
      );

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.statusUpdateSuccess)));
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _captureAndShare(AppLocalizations l10n) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imageBytes = await _exportController.capture(pixelRatio: 2.5);
      if (imageBytes == null) {
        throw Exception('Capture returned null');
      }
      final filePath =
          '${directory.path}/vaari_export_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(filePath);
      await file.writeAsBytes(imageBytes);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: l10n.vaariExportProgress),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Capture failed: $e')));
      }
    }
  }

  Future<void> _deleteParticipant(VaariParticipant participant) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteSignupLabel),
        content: Text(l10n.deleteParticipantConfirmMessageVaari),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: Text(l10n.deleteSignupLabel),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final participantId = '${participant.deviceId}_${participant.memberName}';
      await _firestore
          .collection('vaari_events')
          .doc(widget.eventId)
          .collection('participants')
          .doc(participantId)
          .delete();

      await AdminAuditService.logAction(
        action: 'DELETE_VAARI_PARTICIPANT',
        details: {
          'event_id': widget.eventId,
          'participant_id': participantId,
          'member_name': participant.memberName,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.deleteParticipantSuccess)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;
    final langCode = Localizations.localeOf(context).languageCode;
    final isEnglish = langCode == 'en';
    final configProvider = Provider.of<AppConfigProvider>(context);

    final group = configProvider.appConfig?.gajananMaharajGroups.firstWhere(
      (g) => g.id == widget.adminUser.groupId,
      orElse: () => GajananMaharajGroup(id: '', nameEn: '', nameMr: ''),
    );
    final groupName = group != null
        ? (langCode == 'mr' ? group.nameMr : group.nameEn)
        : '';

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.vaariTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _captureAndShare(localizations),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _eventStream,
        builder: (context, eventSnapshot) {
          if (eventSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (eventSnapshot.hasError ||
              !eventSnapshot.hasData ||
              !eventSnapshot.data!.exists) {
            return Center(
              child: Text(
                eventSnapshot.error?.toString() ??
                    localizations.vaariEventNotFound,
              ),
            );
          }

          final event = VaariEvent.fromMap(
            eventSnapshot.data!.id,
            eventSnapshot.data!.data() as Map<String, dynamic>,
          );

          final eventName = isEnglish ? event.nameEn : event.nameMr;
          final eventDesc = isEnglish
              ? event.descriptionEn
              : event.descriptionMr;
          final dateRange =
              "${formatDateShort(event.startDate, langCode)} - ${formatDateShort(event.endDate, langCode)}";

          return Stack(
            children: [
              // Offscreen screenshot target
              Positioned(
                left: -9999,
                top: -9999,
                child: Screenshot(
                  controller: _exportController,
                  child: VaariExportCard(
                    event: event,
                    eventName: eventName,
                    dateRange: dateRange,
                    participantCount: _latestParticipantCount,
                    groupName: groupName,
                    l10n: localizations,
                    theme: theme,
                    langCode: langCode,
                  ),
                ),
              ),

              // Scrollable UI Content
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Join Code Card
                  if (event.joinCode.isNotEmpty)
                    Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.vpn_key,
                              size: 18,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    localizations.adminVaariJoinCode,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    event.joinCode,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Copy',
                              icon: const Icon(Icons.copy, size: 18),
                              color: theme.colorScheme.primary,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: event.joinCode),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Join code copied'),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              tooltip: 'Share link',
                              icon: const Icon(Icons.share, size: 18),
                              color: theme.colorScheme.primary,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _shareDeepLink(
                                event,
                                localizations,
                                isEnglish,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Event Info Card
                  Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            eventName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (eventDesc.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              eventDesc,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.appColors.secondaryText,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: theme.appColors.secondaryText,
                              ),
                              const SizedBox(width: 6),
                              Text(dateRange, style: theme.textTheme.bodySmall),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: theme.appColors.secondaryText,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                event.timezone,
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Stats Row
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: StatCard(
                            label: localizations.adminVaariTotalSteps,
                            value: formatNumberLocalized(
                              event.totalSteps,
                              langCode,
                              pad: false,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            label: localizations.adminVaariTotalDistance,
                            value:
                                "${_formatDistance(event.totalDistance, langCode)} ${event.distanceUnitLabel}",
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Status Control Card
                  Card(
                    margin: const EdgeInsets.only(bottom: 24),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              localizations.updateStatusLabel ?? 'Status',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              _isStatusLocked ? Icons.lock : Icons.lock_open,
                              size: 20,
                              color: theme.colorScheme.primary,
                            ),
                            onPressed: () {
                              setState(() {
                                _isStatusLocked = !_isStatusLocked;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          IgnorePointer(
                            ignoring: _isStatusLocked,
                            child: Opacity(
                              opacity: _isStatusLocked ? 0.6 : 1.0,
                              child: DropdownButton<String>(
                                value: event.status,
                                underline: const SizedBox(),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'upcoming',
                                    child: Text('Upcoming'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'enrolling',
                                    child: Text('Enrolling'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'ongoing',
                                    child: Text('Ongoing'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'completed',
                                    child: Text('Completed'),
                                  ),
                                ],
                                onChanged: (val) => _updateStatus(event, val),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Participants Header
                  Text(
                    localizations.adminVaariParticipantsList,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.appColors.primarySwatch[600],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Participants Table
                  _buildParticipantsTable(theme, localizations, event),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildParticipantsTable(
    ThemeData theme,
    AppLocalizations localizations,
    VaariEvent event,
  ) {
    return StreamBuilder<QuerySnapshot>(
      stream: _participantsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        _latestParticipantCount = docs.length;

        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                localizations
                    .groupNamjapNoParticipants, // reuse general no participants translation
              ),
            ),
          );
        }

        final participants = docs
            .map(
              (doc) =>
                  VaariParticipant.fromMap(doc.data() as Map<String, dynamic>),
            )
            .toList();

        return Card(
          margin: EdgeInsets.zero,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    columnSpacing: 16,
                    columns: [
                      DataColumn(
                        label: Text(
                          localizations.groupNamjapTableColName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          localizations.stepsLabel,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          localizations.distanceLabel,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const DataColumn(label: Text('')),
                    ],
                    rows: participants.map((p) {
                      final langCode = Localizations.localeOf(
                        context,
                      ).languageCode;
                      return DataRow(
                        cells: [
                          DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  p.memberName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (p.phone.isNotEmpty)
                                  Text(
                                    p.phone,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: theme.appColors.secondaryText,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          DataCell(
                            Text(
                              formatNumberLocalized(
                                p.totalSteps,
                                langCode,
                                pad: false,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              "${_formatDistance(p.totalDistance, langCode)} ${event.distanceUnitLabel}",
                            ),
                          ),
                          DataCell(
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                color: theme.colorScheme.error,
                              ),
                              onPressed: () => _deleteParticipant(p),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _formatDistance(double distance, String langCode) {
    final formatted = distance.toStringAsFixed(1);
    final useMarathi = langCode == 'mr';
    return useMarathi ? toMarathiNumerals(formatted) : formatted;
  }
}

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

import 'dart:async';

class AdminVaariDetailScreen extends StatefulWidget {
  final String eventId;
  final AdminUser adminUser;

  /// Injected for testing; defaults to [FirebaseFirestore.instance].
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
  /// Positions the export card far enough off-screen that it never flashes
  /// into view while still being capturable by [ScreenshotController].
  static const double _offscreenExportOffset = 9999;

  late final FirebaseFirestore _firestore;
  late Stream<DocumentSnapshot> _eventStream;
  late Stream<QuerySnapshot> _participantsStream;
  final ScreenshotController _exportController = ScreenshotController();
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

    // Capture everything derived from `context` before any `await` — the
    // widget may be disposed mid-flight, and reusing `context` afterward
    // risks acting on a stale element or the wrong route.
    final l10n = AppLocalizations.of(context)!;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

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
        navigator.pop(); // Close loading dialog
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.statusUpdateSuccess)),
        );
      }
    } catch (e) {
      debugPrint('AdminVaariDetailScreen._updateStatus error: $e');
      if (mounted) {
        navigator.pop(); // Close loading dialog
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.adminVaariStatusUpdateError)),
        );
      }
    }
  }

  Future<void> _captureAndShare(AppLocalizations l10n) async {
    final messenger = ScaffoldMessenger.of(context);
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
      debugPrint('AdminVaariDetailScreen._captureAndShare error: $e');
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.adminVaariShareError)),
        );
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
            if (eventSnapshot.hasError) {
              debugPrint(
                'AdminVaariDetailScreen event stream error: ${eventSnapshot.error}',
              );
            }
            return Center(
              child: Text(
                eventSnapshot.hasError
                    ? localizations.adminVaariLoadError
                    : localizations.vaariEventNotFound,
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
              _buildOffscreenExportTarget(
                event,
                eventName,
                dateRange,
                groupName,
                localizations,
                theme,
                langCode,
              ),

              // Scrollable UI Content
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (event.joinCode.isNotEmpty)
                    _buildJoinCodeCard(event, localizations, theme, isEnglish),
                  _buildEventInfoCard(
                    event,
                    eventName,
                    eventDesc,
                    dateRange,
                    localizations,
                    theme,
                    langCode,
                  ),
                  _buildStatsRow(event, localizations, langCode),
                  const SizedBox(height: 20),

                  _buildStatusUpdateSection(localizations, theme, event),

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

  /// Offscreen target the [Screenshot] controller captures for export.
  /// Reads the participant count directly from [_participantsStream] rather
  /// than caching it in state — avoids triggering a `setState` (and thus a
  /// rebuild of this whole subtree) on every participants snapshot.
  Widget _buildOffscreenExportTarget(
    VaariEvent event,
    String eventName,
    String dateRange,
    String groupName,
    AppLocalizations localizations,
    ThemeData theme,
    String langCode,
  ) {
    return Positioned(
      left: -_offscreenExportOffset,
      top: -_offscreenExportOffset,
      child: Screenshot(
        controller: _exportController,
        child: StreamBuilder<QuerySnapshot>(
          stream: _participantsStream,
          builder: (context, participantsSnapshot) {
            final participantCount =
                participantsSnapshot.data?.docs.length ?? 0;
            return VaariExportCard(
              event: event,
              eventName: eventName,
              dateRange: dateRange,
              participantCount: participantCount,
              groupName: groupName,
              l10n: localizations,
              theme: theme,
              langCode: langCode,
            );
          },
        ),
      ),
    );
  }

  Widget _buildJoinCodeCard(
    VaariEvent event,
    AppLocalizations localizations,
    ThemeData theme,
    bool isEnglish,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            Icon(Icons.vpn_key, size: 18, color: theme.colorScheme.primary),
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
              tooltip: localizations.copyTooltip,
              icon: const Icon(Icons.copy, size: 18),
              color: theme.colorScheme.primary,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: event.joinCode));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(localizations.joinCodeCopied)),
                );
              },
            ),
            const SizedBox(width: 12),
            IconButton(
              tooltip: localizations.shareLinkTooltip,
              icon: const Icon(Icons.share, size: 18),
              color: theme.colorScheme.primary,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => _shareDeepLink(event, localizations, isEnglish),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventInfoCard(
    VaariEvent event,
    String eventName,
    String eventDesc,
    String dateRange,
    AppLocalizations localizations,
    ThemeData theme,
    String langCode,
  ) {
    return Card(
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
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.flag_outlined,
                  size: 14,
                  color: theme.appColors.secondaryText,
                ),
                const SizedBox(width: 6),
                Text(
                  "${localizations.adminVaariTargetDistance}: ${formatDistanceLocalized(event.targetDistance, langCode)} ${localizedDistanceUnitLabel(event.distanceUnit, langCode)}",
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(
    VaariEvent event,
    AppLocalizations localizations,
    String langCode,
  ) {
    return IntrinsicHeight(
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
                  "${formatDistanceLocalized(event.totalDistance, langCode)} ${localizedDistanceUnitLabel(event.distanceUnit, langCode)}",
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsTable(
    ThemeData theme,
    AppLocalizations localizations,
    VaariEvent event,
  ) {
    final langCode = Localizations.localeOf(context).languageCode;
    return StreamBuilder<QuerySnapshot>(
      stream: _participantsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(localizations.groupNamjapNoParticipants),
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
                        label: Expanded(
                          child: Text(
                            localizations.stepsLabel,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Expanded(
                          child: Text(
                            "${localizations.distanceLabel} (${localizedDistanceUnitLabel(event.distanceUnit, langCode)})",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                    rows: participants.map((p) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              p.memberName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataCell(
                            Center(
                              child: Text(
                                formatNumberLocalized(
                                  p.totalSteps,
                                  langCode,
                                  pad: false,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Center(
                              child: Text(
                                formatDistanceLocalized(
                                  p.totalDistance,
                                  langCode,
                                ),
                              ),
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

  Widget _buildStatusUpdateSection(
    AppLocalizations l10n,
    ThemeData theme,
    VaariEvent event,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.groupNamjapStatusLabel.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.2,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isStatusLocked ? Icons.lock_outline : Icons.lock_open,
                    size: 16,
                    color: _isStatusLocked
                        ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                        : theme.colorScheme.primary,
                  ),
                  onPressed: () {
                    setState(() {
                      _isStatusLocked = !_isStatusLocked;
                    });
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),
            IgnorePointer(
              ignoring: _isStatusLocked,
              child: Opacity(
                opacity: _isStatusLocked ? 0.6 : 1.0,
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<String>(
                        style: SegmentedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          textStyle: const TextStyle(fontSize: 10),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        emptySelectionAllowed: true,
                        segments: [
                          ButtonSegment(
                            value: 'upcoming',
                            label: Text(l10n.statusUpcoming),
                            icon: const Icon(
                              Icons.calendar_today_outlined,
                              size: 14,
                            ),
                          ),
                          ButtonSegment(
                            value: 'enrolling',
                            label: Text(l10n.statusEnrolling),
                            icon: const Icon(
                              Icons.person_add_outlined,
                              size: 14,
                            ),
                          ),
                        ],
                        selected:
                            ['upcoming', 'enrolling'].contains(event.status)
                            ? {event.status}
                            : {},
                        onSelectionChanged: (Set<String> newSelection) {
                          final value = newSelection.firstOrNull;
                          if (value != null && value != event.status) {
                            _updateStatus(event, value);
                          }
                        },
                        showSelectedIcon: false,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<String>(
                        style: SegmentedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          textStyle: const TextStyle(fontSize: 10),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        emptySelectionAllowed: true,
                        segments: [
                          ButtonSegment(
                            value: 'ongoing',
                            label: Text(l10n.statusOngoing),
                            icon: const Icon(
                              Icons.play_circle_outline,
                              size: 14,
                            ),
                          ),
                          ButtonSegment(
                            value: 'completed',
                            label: Text(l10n.statusCompleted),
                            icon: const Icon(
                              Icons.check_circle_outline,
                              size: 14,
                            ),
                          ),
                        ],
                        selected:
                            ['ongoing', 'completed'].contains(event.status)
                            ? {event.status}
                            : {},
                        onSelectionChanged: (Set<String> newSelection) {
                          final value = newSelection.firstOrNull;
                          if (value != null && value != event.status) {
                            _updateStatus(event, value);
                          }
                        },
                        showSelectedIcon: false,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

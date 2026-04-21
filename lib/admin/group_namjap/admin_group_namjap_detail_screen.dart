import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/group_namjap_event.dart';
import 'package:gajanan_maharaj_sevekari/models/group_namjap_participant.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:gajanan_maharaj_sevekari/widgets/themed_icon.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:gajanan_maharaj_sevekari/utils/marathi_utils.dart';
import 'package:gajanan_maharaj_sevekari/utils/date_time_utils.dart';
import 'package:gajanan_maharaj_sevekari/admin/widgets/admin_stats_widgets.dart';
import 'package:gajanan_maharaj_sevekari/admin/group_namjap/widgets/group_namjap_export_card.dart';

class AdminGroupNamjapDetailScreen extends StatefulWidget {
  final String eventId;

  const AdminGroupNamjapDetailScreen({super.key, required this.eventId});

  @override
  State<AdminGroupNamjapDetailScreen> createState() =>
      _AdminGroupNamjapDetailScreenState();
}

class _AdminGroupNamjapDetailScreenState
    extends State<AdminGroupNamjapDetailScreen> {
  late Stream<DocumentSnapshot> _eventStream;
  late Stream<QuerySnapshot> _participantsStream;
  final ScreenshotController _screenshotController = ScreenshotController();
  final ScreenshotController _exportController = ScreenshotController();
  int _latestParticipantCount = 0;

  @override
  void initState() {
    super.initState();
    _eventStream = FirebaseFirestore.instance
        .collection('group_namjap_events')
        .doc(widget.eventId)
        .snapshots();
    _participantsStream = FirebaseFirestore.instance
        .collection('group_namjap_events')
        .doc(widget.eventId)
        .collection('participants')
        .orderBy('totalCount', descending: true)
        .snapshots();
  }

  Future<void> _shareDeepLink(
    GroupNamjapEvent event,
    AppLocalizations l10n,
    bool isEnglish,
  ) async {
    final title = isEnglish ? event.nameEn : event.nameMr;
    final shareText =
        '${l10n.groupNamjapSharePrefix}: $title\n${l10n.groupNamjapJoinCode}: ${event.joinCode}\n\n${l10n.groupNamjapShareLinkPrefix}: https://gajananmaharajsevekari.org/namjap/${event.id}?joinCode=${event.joinCode}';
    Share.share(shareText);
  }

  Future<void> _captureAndShare(AppLocalizations l10n) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imageBytes = await _exportController.capture(pixelRatio: 2.5);
      if (imageBytes == null) {
        throw Exception(
          'Capture returned null — export card may not have painted yet',
        );
      }
      final filePath =
          '${directory.path}/namjap_export_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(filePath);
      await file.writeAsBytes(imageBytes);
      await Share.shareXFiles([
        XFile(file.path),
      ], text: l10n.groupNamjapStatusExport);
    } catch (e, stack) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.groupNamjapFailedToCapture}: $e')),
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

    return StreamBuilder<DocumentSnapshot>(
      stream: _eventStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            body: Center(child: Text(localizations.groupNamjapEventNotFound)),
          );
        }

        final event = GroupNamjapEvent.fromMap(
          snapshot.data!.id,
          snapshot.data!.data() as Map<String, dynamic>,
        );
        final eventName = isEnglish ? event.nameEn : event.nameMr;
        final sankalpText = isEnglish ? event.sankalpEn : event.sankalpMr;

        return Scaffold(
          appBar: AppBar(
            title: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(eventName),
            ),
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
          ),
          body: Stack(
            children: [
              // Export card rendered off-screen (must be painted for capture() to work)
              Positioned(
                left: -5000,
                top: 0,
                child: Screenshot(
                  controller: _exportController,
                  child: Builder(
                    builder: (ctx) {
                      final t = Theme.of(ctx);
                      final l10n = AppLocalizations.of(ctx)!;
                      final lc = Localizations.localeOf(ctx).languageCode;
                      final en = lc == 'en';
                      final progress = event.targetCount > 0
                          ? (event.totalCount / event.targetCount).clamp(
                              0.0,
                              1.0,
                            )
                          : 0.0;
                      return GroupNamjapExportCard(
                        event: event,
                        eventName: en ? event.nameEn : event.nameMr,
                        sankalp: en ? event.sankalpEn : event.sankalpMr,
                        dateRange:
                            '${formatDateShort(event.startDate, lc)} - ${formatDateShort(event.endDate, lc)}',
                        percentStr:
                            '${formatNumberLocalized((progress * 100).toInt(), lc, pad: false)}%',
                        progress: progress,
                        participantCount: _latestParticipantCount,
                        l10n: l10n,
                        theme: t,
                        langCode: lc,
                      );
                    },
                  ),
                ),
              ),
              // Main scrollable content
              Screenshot(
                controller: _screenshotController,
                child: Container(
                  color: theme.scaffoldBackgroundColor,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Row 1: Join Code Card
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        localizations.groupNamjapJoinCode,
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: theme.colorScheme.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      Text(
                                        event.joinCode,
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
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
                              ],
                            ),
                          ),
                        ),

                      // Row 2: Namjap Mantra Card
                      if (event.mantra.isNotEmpty)
                        Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.record_voice_over,
                                  size: 18,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        localizations.groupNamjapMantra,
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: theme.colorScheme.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      Text(
                                        event.mantra,
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
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
                                      ClipboardData(text: event.mantra),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Mantra copied'),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${localizations.groupNamjapSankalpLabel}: $sankalpText",
                                style: theme.textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "${formatDateShort(event.startDate, langCode)} - ${formatDateShort(event.endDate, langCode)}",
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      event.status.toUpperCase(),
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Row 3: Statistics Row
                      _buildStatsRow(theme, localizations, event),

                      const SizedBox(height: 24),

                      // Row 4: Quick Actions
                      Text(
                        localizations.groupNamjapQuickActions.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          letterSpacing: 1.2,
                          color: theme.appColors.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _shareDeepLink(
                                event,
                                localizations,
                                isEnglish,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.share, size: 20),
                              label: Text(localizations.groupNamjapShare),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _captureAndShare(localizations),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.ios_share, size: 20),
                              label: Text(
                                localizations.groupNamjapExportStatus,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Row 5: Participants Table
                      Text(
                        localizations.groupNamjapParticipants,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildParticipantsTable(theme, localizations),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsRow(
    ThemeData theme,
    AppLocalizations localizations,
    GroupNamjapEvent event,
  ) {
    return StreamBuilder<QuerySnapshot>(
      stream: _participantsStream,
      builder: (context, snapshot) {
        int participantCount = 0;
        if (snapshot.hasData) {
          participantCount = snapshot.data!.docs.length;
          // Cache so the export card (Offstage) has the latest count
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _latestParticipantCount != participantCount) {
              setState(() => _latestParticipantCount = participantCount);
            }
          });
        }

        final langCode = Localizations.localeOf(context).languageCode;
        double progress = event.targetCount > 0
            ? (event.totalCount / event.targetCount).clamp(0.0, 1.0)
            : 0.0;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: StatCard(
                  label: localizations.groupNamjapTotalParticipants
                      .toUpperCase(),
                  value: formatNumberLocalized(
                    participantCount,
                    langCode,
                    pad: false,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StatCard(
                  label: localizations.groupNamjapAchievedLabel.toUpperCase(),
                  value:
                      "${formatNumberLocalized(event.totalCount, langCode, pad: false)} / ${formatNumberLocalized(event.targetCount, langCode, pad: false)}",
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ProgressStatCard(
                  label: localizations.groupNamjapProgress.toUpperCase(),
                  value:
                      "${formatNumberLocalized((progress * 100).toInt(), langCode, pad: false)}%",
                  subtext: "",
                  progress: progress,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildParticipantsTable(
    ThemeData theme,
    AppLocalizations localizations,
  ) {
    return StreamBuilder<QuerySnapshot>(
      stream: _participantsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Center(child: Text(localizations.groupNamjapNoParticipants));
        }

        final participants = docs
            .map(
              (doc) => GroupNamjapParticipant.fromMap(
                doc.data() as Map<String, dynamic>,
              ),
            )
            .toList();

        return Card(
          child: SizedBox(
            width: double.infinity,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  DataColumn(
                    label: Text(
                      localizations.groupNamjapTableColName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      localizations.groupNamjapTableColPhone,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      localizations.groupNamjapTableColTotalChants,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    numeric: true,
                  ),
                ],
                rows: participants.map((p) {
                  final langCode = Localizations.localeOf(context).languageCode;
                  return DataRow(
                    cells: [
                      DataCell(Text(p.memberName)),
                      DataCell(Text(p.phone)),
                      DataCell(
                        Text(
                          formatNumberLocalized(
                            p.totalCount,
                            langCode,
                            pad: false,
                          ),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}

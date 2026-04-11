import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:gajanan_maharaj_sevekari/admin/admin_audit_service.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/parayan_event.dart';
import 'package:gajanan_maharaj_sevekari/models/parayan_participant.dart';
import 'package:gajanan_maharaj_sevekari/parayan/parayan_type.dart';
import 'package:gajanan_maharaj_sevekari/providers/parayan_service.dart';
import 'package:gajanan_maharaj_sevekari/utils/marathi_utils.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:gajanan_maharaj_sevekari/admin/parayan_admin_add_participants_screen.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gajanan_maharaj_sevekari/widgets/themed_icon.dart';

enum _ParticipantFilter { all, completed, pending }

class ParayanAdminDetailScreen extends StatefulWidget {
  final ParayanEvent event;

  const ParayanAdminDetailScreen({super.key, required this.event});

  @override
  State<ParayanAdminDetailScreen> createState() =>
      _ParayanAdminDetailScreenState();
}

class _ParayanAdminDetailScreenState extends State<ParayanAdminDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ParayanService _parayanService = ParayanService();
  final _screenshotController = ScreenshotController();
  late Stream<List<ParayanMember>> _overviewParticipantsStream;
  late Stream<List<ParayanMember>> _participantsTabStream;
  late Stream<ParayanEvent> _eventStream;
  _ParticipantFilter _currentFilter = _ParticipantFilter.all;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _overviewParticipantsStream = _parayanService.getAllParticipants(
      widget.event.id,
    );
    _participantsTabStream = _parayanService.getAllParticipants(
      widget.event.id,
    );
    _eventStream = _parayanService.getEventById(widget.event.id);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatNumberInternal(dynamic number, bool isMarathi) {
    if (number == null) return '';
    String numStr = number.toString();
    return isMarathi ? toMarathiNumerals(numStr) : numStr;
  }

  String _formatNumber(BuildContext context, dynamic number) {
    final isMarathi = Localizations.localeOf(context).languageCode == 'mr';
    return _formatNumberInternal(number, isMarathi);
  }

  // Future<void> _sendManualPing() async {
  //   // TODO: Implement Firestore update to trigger manual ping Cloud Function
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(content: Text(AppLocalizations.of(context)!.manualPingLabel)),
  //   );
  // }

  Future<void> _updateStatus(ParayanEvent event, String? newStatus) async {
    if (newStatus == null || newStatus == widget.event.status) return;

    final l10n = AppLocalizations.of(context)!;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Updating Status...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      if (newStatus == 'allocated') {
        // Trigger cloud-based allocation
        await _parayanService.allocateAdhyays(event.id);
      } else {
        await _parayanService.updateEventStatus(event, newStatus);
      }

      await AdminAuditService.logAction(
        action: 'UPDATE_PARAYAN_STATUS',
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


  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return StreamBuilder<ParayanEvent>(
      stream: _eventStream,
      initialData: widget.event,
      builder: (context, eventSnapshot) {
        final event = eventSnapshot.data ?? widget.event;
        return Scaffold(
          appBar: AppBar(
            title: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                Localizations.localeOf(context).languageCode == 'mr'
                    ? event.titleMr
                    : event.titleEn,
              ),
            ),
            actions: [
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
            ],
            bottom: TabBar(
              controller: _tabController,
              labelColor: theme.appBarTheme.foregroundColor,
              unselectedLabelColor: theme.appBarTheme.foregroundColor
                  ?.withValues(alpha: 0.6),
              indicatorColor: theme.appBarTheme.foregroundColor,
              indicatorWeight: 3.0,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.normal,
              ),
              tabs: [
                Tab(text: localizations.overviewTab),
                Tab(text: localizations.participantsTab),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              KeepAlivePage(
                child: _buildOverviewTab(localizations, theme, event),
              ),
              KeepAlivePage(
                child: _buildParticipantsTab(localizations, theme, event),
              ),
            ],
          ),
          floatingActionButton:
              (_tabController.index == 1 && event.status != 'completed')
              ? FloatingActionButton.extended(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ParayanAdminAddParticipantsScreen(event: event),
                    ),
                  ),
                  icon: const Icon(Icons.group_add),
                  label: Text(localizations.addParticipantLabel),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                )
              : null,
        );
      },
    );
  }
  // ── Overview Tab ────────────────────────────────────────────────────────────

  Widget _buildOverviewTab(
    AppLocalizations l10n,
    ThemeData theme,
    ParayanEvent event,
  ) {
    return StreamBuilder<List<ParayanMember>>(
      stream: _overviewParticipantsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final participants = (snapshot.data ?? [])
          ..sort((a, b) => (a.globalIndex ?? 0).compareTo(b.globalIndex ?? 0));
        final adhyaysPerPerson = event.type == ParayanType.oneDay ? 1 : 3;
        final totalAdhyays = participants.length * adhyaysPerPerson;

        int completedAdhyays = 0;
        for (final p in participants) {
          completedAdhyays += p.completions.values.where((c) => c).length;
        }

        final progress = totalAdhyays > 0
            ? completedAdhyays / totalAdhyays
            : 0.0;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Join Code Card
            if (event.joinCode != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.vpn_key, color: theme.colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.joinCodeLabel,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                event.joinCode!,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: l10n.copyJoinCode,
                          icon: const Icon(Icons.copy),
                          color: theme.colorScheme.primary,
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: event.joinCode!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.joinCodeCopied)),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _tabController.animateTo(1),
                      borderRadius: BorderRadius.circular(12),
                      child: _StatCard(
                        label: l10n.totalParticipantsLabel.toUpperCase(),
                        value: _formatNumber(context, participants.length),
                        subtext: '',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ProgressStatCard(
                      label: l10n.progressLabel.toUpperCase(),
                      value:
                          '${_formatNumber(context, (progress * 100).toStringAsFixed(0))}%',
                      subtext:
                          '${_formatNumber(context, completedAdhyays)} / ${_formatNumber(context, totalAdhyays)} ${l10n.adhyay}',
                      progress: progress,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildStatusUpdateSection(l10n, theme, event),
            const SizedBox(height: 32),
            Text(
              l10n.quickActionsLabel.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 1.2,
                color: theme.appColors.secondaryText,
              ),
            ),
            const SizedBox(height: 12),
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: participants.isNotEmpty
                        ? () => _exportAllGroups(context, event, l10n)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      disabledBackgroundColor:
                          theme.appColors.disabledBackground,
                      disabledForegroundColor: theme.appColors.disabledText,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.ios_share, size: 20),
                    label: Text(l10n.exportAllocations),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final isMarathi =
                              Localizations.localeOf(context).languageCode ==
                              'mr';
                          final title = isMarathi
                              ? event.titleMr
                              : event.titleEn;

                          final shareText =
                              '${l10n.shareParayanAction}: $title\n\n${l10n.shareLink}: https://gajananmaharajsevekari.org/parayan/${event.id}';
                          SharePlus.instance.share(ShareParams(text: shareText));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.share, size: 20),
                        label: Text(l10n.shareParayan),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final isMarathi =
                              Localizations.localeOf(context).languageCode ==
                              'mr';
                          final title = isMarathi
                              ? event.titleMr
                              : event.titleEn;

                          final joinCodeText = event.joinCode != null ? '\n\n${l10n.joinCodeLabel}: ${event.joinCode}' : '';
                          final shareText =
                              '${l10n.shareParayanAction}: $title$joinCodeText\n\n${l10n.shareLink}: https://gajananmaharajsevekari.org/parayan/${event.id}?joinCode=${event.joinCode}';
                          Share.share(shareText);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          disabledBackgroundColor:
                              theme.appColors.disabledBackground,
                          disabledForegroundColor: theme.appColors.disabledText,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.share, size: 20),
                        label: Text(l10n.shareWithCode),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildRemindersSection(l10n, theme, event),
          ],
        );
      },
    );
  }

  Widget _buildStatusUpdateSection(
    AppLocalizations l10n,
    ThemeData theme,
    ParayanEvent event,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.updateStatusLabel.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 1.2,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 16),
        Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                style: SegmentedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  textStyle: const TextStyle(fontSize: 11),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                emptySelectionAllowed: true,
                segments: [
                  ButtonSegment(
                    value: 'upcoming',
                    label: Text(l10n.statusUpcoming),
                    icon: const Icon(Icons.calendar_today_outlined, size: 14),
                  ),
                  ButtonSegment(
                    value: 'enrolling',
                    label: Text(l10n.statusEnrolling),
                    icon: const Icon(Icons.person_add_outlined, size: 14),
                  ),
                  ButtonSegment(
                    value: 'allocated',
                    label: Text(l10n.statusAllocated),
                    icon: const Icon(
                      Icons.assignment_turned_in_outlined,
                      size: 14,
                    ),
                  ),
                ],
                selected:
                    [
                      'upcoming',
                      'enrolling',
                      'allocated',
                    ].contains(event.status)
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
                  textStyle: const TextStyle(fontSize: 11),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                emptySelectionAllowed: true,
                segments: [
                  ButtonSegment(
                    value: 'ongoing',
                    label: Text(l10n.statusOngoing),
                    icon: const Icon(Icons.play_circle_outline, size: 14),
                  ),
                  ButtonSegment(
                    value: 'completed',
                    label: Text(l10n.statusCompleted),
                    icon: const Icon(Icons.check_circle_outline, size: 14),
                  ),
                ],
                selected: ['ongoing', 'completed'].contains(event.status)
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
      ],
    );
  }

  Widget _buildRemindersSection(
    AppLocalizations l10n,
    ThemeData theme,
    ParayanEvent event,
  ) {
    final totalDays = event.endDate.difference(event.startDate).inDays + 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.remindersStatusLabel.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 1.2,
            color: theme.appColors.secondaryText,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(totalDays, (dayIdx) {
          final dayDate = event.startDate.add(Duration(days: dayIdx));
          final dateStr = DateFormat('MMM dd').format(dayDate);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${l10n.day} ${_formatNumber(context, dayIdx + 1)}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Text(
                        Localizations.localeOf(context).languageCode == 'mr'
                            ? toMarathiNumerals(dateStr)
                            : dateStr,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.appColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  ...event.reminderTimes.map((timeStr) {
                    final reminderTimeParts = timeStr.split(':');
                    if (reminderTimeParts.length != 2) {
                      return const SizedBox.shrink();
                    }

                    final trackingKey = 'day${dayIdx + 1}_$timeStr';
                    final isSent = event.sentReminders.containsKey(trackingKey);
                    final statusText = isSent
                        ? l10n.reminderSentStatus
                        : l10n.reminderPendingStatus;
                    final theme = Theme.of(context);
                    final statusColor = isSent
                        ? theme.appColors.success
                        : theme.appColors.secondaryText;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            Localizations.localeOf(context).languageCode == 'mr'
                                ? toMarathiNumerals(timeStr)
                                : timeStr,
                            style: theme.textTheme.bodyMedium,
                          ),
                          Row(
                            children: [
                              if (isSent)
                                Icon(
                                  Icons.check_circle,
                                  size: 14,
                                  color: theme.appColors.success,
                                ),
                              const SizedBox(width: 4),
                              Text(
                                statusText,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: statusColor,
                                  fontWeight: isSent
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ── Participants Tab ─────────────────────────────────────────────────────────

  Widget _buildParticipantsTab(
    AppLocalizations l10n,
    ThemeData theme,
    ParayanEvent event,
  ) {
    return StreamBuilder<List<ParayanMember>>(
      stream: _participantsTabStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Error: ${snapshot.error}',
                style: TextStyle(color: theme.colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final participants = (snapshot.data ?? [])
          ..sort((a, b) => (a.globalIndex ?? 0).compareTo(b.globalIndex ?? 0));

        // Calculate current parayan day (1-indexed)
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final start = DateTime(
          event.startDate.year,
          event.startDate.month,
          event.startDate.day,
        );
        int currentDay = today.difference(start).inDays + 1;
        final maxDays = (event.type == ParayanType.threeDay) ? 3 : 1;
        if (currentDay < 1) currentDay = 1;
        if (currentDay > maxDays) currentDay = maxDays;

        int allCount = participants.length;
        int completedCount = 0;
        int pendingCount = 0;
        for (final entry in participants) {
          bool upToDate = true;
          for (int d = 1; d <= currentDay; d++) {
            if (!(entry.completions[d.toString()] ?? false)) {
              upToDate = false;
              break;
            }
          }
          if (upToDate) {
            completedCount++;
          } else {
            pendingCount++;
          }
        }

        // Sort participants by globalIndex with joinedAt fallback
        final sortedList = participants.toList()
          ..sort((a, b) {
            // Treat -1 or null as unallocated (legacy compatibility)
            final int? idxA = (a.globalIndex ?? -1) < 0 ? null : a.globalIndex;
            final int? idxB = (b.globalIndex ?? -1) < 0 ? null : b.globalIndex;

            if (idxA != null && idxB != null) {
              return idxA.compareTo(idxB);
            }
            if (idxA != null) return -1;
            if (idxB != null) return 1;

            final res = a.joinedAt.compareTo(b.joinedAt);
            if (res != 0) return res;
            return a.name.compareTo(b.name);
          });

        // Map participants to their original index for correct group number calculation
        final indexedParticipants = sortedList.asMap().entries.toList();

        // Filter based on completion status for current and previous days
        final filteredParticipants = indexedParticipants.where((entry) {
          final p = entry.value;
          bool isUpToDate = true;
          for (int d = 1; d <= currentDay; d++) {
            if (!(p.completions[d.toString()] ?? false)) {
              isUpToDate = false;
              break;
            }
          }

          if (_currentFilter == _ParticipantFilter.completed) return isUpToDate;
          if (_currentFilter == _ParticipantFilter.pending) return !isUpToDate;
          return true;
        }).toList();

        return Column(
          children: [
            _buildParticipantsFilterBar(
              l10n,
              theme,
              all: allCount,
              completed: completedCount,
              pending: pendingCount,
            ),
            Expanded(
              child: filteredParticipants.isEmpty
                  ? Center(child: Text(l10n.noResultsFound))
                  : Builder(
                      builder: (context) {
                        final Map<int, List<MapEntry<int, ParayanMember>>>
                        grouped = {};
                        final bool isThreeDay =
                            event.type == ParayanType.threeDay;
                        final int gSize = isThreeDay ? 7 : 21;

                        for (final entry in filteredParticipants) {
                          final p = entry.value;
                          final int gNum =
                              p.groupNumber ??
                              ((p.globalIndex ?? entry.key) ~/ gSize) + 1;
                          grouped.putIfAbsent(gNum, () => []).add(entry);
                        }
                        final bool showHeaders =
                            event.status != 'upcoming' &&
                            event.status != 'enrolling';
                        final sortedGroupKeys = grouped.keys.toList()..sort();

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: sortedGroupKeys.length,
                          itemBuilder: (context, gi) {
                            final gNum = sortedGroupKeys[gi];
                            final members = grouped[gNum]!;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Group Header
                                if (showHeaders)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      20,
                                      16,
                                      8,
                                    ),
                                    child: Text(
                                      l10n
                                          .groupLabel(
                                            _formatNumber(context, gNum),
                                          )
                                          .toUpperCase(),
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.2,
                                          ),
                                    ),
                                  ),
                                // Member Cards
                                ...members.map((entry) {
                                  final p = entry.value;

                                  bool isUpToDate = true;
                                  for (int d = 1; d <= currentDay; d++) {
                                    if (!(p.completions[d.toString()] ??
                                        false)) {
                                      isUpToDate = false;
                                      break;
                                    }
                                  }

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                      leading: CircleAvatar(
                                        backgroundColor: isUpToDate
                                            ? theme.appColors.success
                                                  .withValues(alpha: 0.15)
                                            : theme
                                                  .colorScheme
                                                  .primaryContainer,
                                        child: Icon(
                                          isUpToDate
                                              ? Icons.check_circle
                                              : Icons.person_outline,
                                          color: isUpToDate
                                              ? theme.appColors.success
                                              : theme.colorScheme.primary,
                                        ),
                                      ),
                                      title: Text(
                                        p.name,
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      subtitle: RichText(
                                        text: TextSpan(
                                          style: theme.textTheme.bodySmall,
                                          children: [
                                            TextSpan(
                                              text:
                                                  "${l10n.groupLabel(_formatNumber(context, gNum))} • ",
                                            ),
                                            ...p.assignedAdhyays
                                                .asMap()
                                                .entries
                                                .map((entry) {
                                                  final dayIdx = entry.key + 1;
                                                  final adhyay = entry.value;
                                                  final isDone =
                                                      p.completions[dayIdx
                                                          .toString()] ??
                                                      false;
                                                  final isLast =
                                                      entry.key ==
                                                      p.assignedAdhyays.length -
                                                          1;

                                                  return TextSpan(
                                                    text:
                                                        "${_formatNumber(context, adhyay)}${isLast ? '' : ', '}",
                                                    style: TextStyle(
                                                      color: isDone
                                                          ? theme
                                                                .appColors
                                                                .success
                                                          : null,
                                                      fontWeight: isDone
                                                          ? FontWeight.bold
                                                          : null,
                                                      fontSize: 12,
                                                    ),
                                                  );
                                                }),
                                          ],
                                        ),
                                      ),
                                      trailing: IconButton(
                                        icon: Icon(
                                          Icons.edit_note,
                                          color: theme.colorScheme.primary,
                                        ),
                                        onPressed: () =>
                                            _showParticipantEditDialog(
                                              context,
                                              l10n,
                                              p,
                                              event,
                                              gNum,
                                            ),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildParticipantsFilterBar(
    AppLocalizations l10n,
    ThemeData theme, {
    required int all,
    required int completed,
    required int pending,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildFilterChip(
            "${l10n.filterAll} - ${_formatNumber(context, all)}",
            _ParticipantFilter.all,
            theme,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            "${l10n.filterCompleted} - ${_formatNumber(context, completed)}",
            _ParticipantFilter.completed,
            theme,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            "${l10n.filterPending} - ${_formatNumber(context, pending)}",
            _ParticipantFilter.pending,
            theme,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    _ParticipantFilter filter,
    ThemeData theme,
  ) {
    final isSelected = _currentFilter == filter;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _currentFilter = filter;
          });
        }
      },
      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? theme.colorScheme.primary : theme.hintColor,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  void _showParticipantEditDialog(
    BuildContext context,
    AppLocalizations l10n,
    ParayanMember member,
    ParayanEvent event,
    int groupNumber,
  ) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                "${member.name} (${l10n.groupLabel(_formatNumber(context, groupNumber))})",
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (member.phone != null && member.phone!.isNotEmpty)
                      ListTile(
                        leading: const Icon(Icons.phone),
                        title: Text(member.phone!),
                        trailing: IconButton(
                          icon: Icon(
                            Icons.message,
                            color: theme.appColors.success,
                          ),
                          onPressed: () async {
                            final number = member.phone!.replaceAll(
                              RegExp(r"[^\d+]"),
                              "",
                            );
                            final url = 'https://wa.me/$number';
                            if (await canLaunchUrl(Uri.parse(url))) {
                              await launchUrl(
                                Uri.parse(url),
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          },
                        ),
                        visualDensity: VisualDensity.compact,
                        contentPadding: EdgeInsets.zero,
                      ),
                    const Divider(),
                    Text(
                      l10n.adhyayCompletionTitle.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...member.assignedAdhyays
                        .asMap()
                        .entries
                        .where((entry) {
                          // Filter based on current day of the event
                          final now = DateTime.now();
                          final today = DateTime(now.year, now.month, now.day);
                          final start = DateTime(
                            event.startDate.year,
                            event.startDate.month,
                            event.startDate.day,
                          );
                          final currentDayOfEvent =
                              today.difference(start).inDays + 1;

                          // Show day 1 adhyay if currentDayOfEvent >= 1, day 2 if >= 2, etc.
                          // idx (entry.key) starts from 0, so entry.key + 1 is the day index.
                          final dayIndex = entry.key + 1;

                          // Always show at least the first day if the event is ongoing or later,
                          // or if we are exactly on the start date.
                          // Otherwise, show only up to the current day.
                          return dayIndex <= currentDayOfEvent;
                        })
                        .map((entry) {
                          final idx = entry.key + 1;
                          final adhyay = entry.value;
                          final isDone =
                              member.completions[idx.toString()] ?? false;
                          return CheckboxListTile(
                            title: Text(
                              "${l10n.day} ${_formatNumber(context, idx)}: ${l10n.adhyay} ${_formatNumber(context, adhyay)}",
                            ),
                            value: isDone,
                            onChanged: (val) async {
                              if (val == null) return;

                              // Optimistic update for instant UI feedback
                              setDialogState(() {
                                member.completions[idx.toString()] = val;
                              });

                              try {
                                await _parayanService.updateMemberCompletion(
                                  eventId: event.id,
                                  memberId: member.id!,
                                  dayIndex: idx,
                                  completed: val,
                                );

                                await AdminAuditService.logAction(
                                  action: 'UPDATE_MEMBER_COMPLETION',
                                  details: {
                                    'event_id': event.id,
                                    'device_id': member.deviceId,
                                    'member_name': member.name,
                                    'day_index': idx,
                                    'completed': val,
                                  },
                                );
                              } catch (e) {
                                // Revert optimistic update on failure
                                setDialogState(() {
                                  member.completions[idx.toString()] = !val;
                                });
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              }
                            },
                          );
                        }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.closeLabel),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _exportAllGroups(
    BuildContext context,
    ParayanEvent event,
    AppLocalizations l10n,
  ) async {
    final isMarathi = Localizations.localeOf(context).languageCode == 'mr';
    final title = isMarathi ? event.titleMr : event.titleEn;
    final dateString = isMarathi
        ? DateFormat('d MMMM, yyyy', 'mr').format(event.startDate)
        : DateFormat('MMMM d, yyyy').format(event.startDate);

    String suffix = "";
    if (event.status == 'allocated') {
      suffix = l10n.exportSuffixAllocated;
    } else if (event.status == 'ongoing') {
      suffix = l10n.exportSuffixOngoing;
    } else if (event.status == 'completed') {
      suffix = l10n.exportSuffixCompleted;
    }
    final String shareText = "$title$suffix";

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(l10n.exportingGroups),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final participants =
          (await _parayanService.getAllParticipants(event.id).first)..sort((
            a,
            b,
          ) {
            // Treat -1 or null as unallocated (legacy compatibility)
            final int? idxA = (a.globalIndex ?? -1) < 0 ? null : a.globalIndex;
            final int? idxB = (b.globalIndex ?? -1) < 0 ? null : b.globalIndex;

            if (idxA != null && idxB != null) {
              return idxA.compareTo(idxB);
            }
            if (idxA != null) return -1;
            if (idxB != null) return 1;

            final res = a.joinedAt.compareTo(b.joinedAt);
            if (res != 0) return res;
            return a.name.compareTo(b.name);
          });
      final int groupSize = (event.type == ParayanType.threeDay) ? 7 : 21;
      final int totalGroups = (participants.length / groupSize).ceil();

      final List<XFile> files = [];
      final tempDir = await getTemporaryDirectory();

      // Batch groups: 1 group per file for 1-day (easy sharing), 3 groups per file for 3-day.
      final int batchSize = (event.type == ParayanType.threeDay) ? 3 : 1;
      final int totalBatches = (totalGroups / batchSize).ceil();
      final exportTheme = Theme.of(context);
      if (!context.mounted) return;

      for (int batch = 0; batch < totalBatches; batch++) {
        final int startGroup = batch * batchSize + 1;
        final int endGroup = (startGroup + batchSize - 1).clamp(1, totalGroups);

        Widget batchWidget;

        if (event.type == ParayanType.threeDay) {
          final batchGroups = <MapEntry<int, List<ParayanMember>>>[];
          for (int i = startGroup; i <= endGroup; i++) {
            final int startIdx = (i - 1) * groupSize;
            if (startIdx >= participants.length) break;
            final int endIdx = (startIdx + groupSize).clamp(
              0,
              participants.length,
            );
            final List<ParayanMember> groupParticipants = participants.sublist(
              startIdx,
              endIdx,
            );
            batchGroups.add(MapEntry(i, groupParticipants));
          }
          if (batchGroups.isEmpty) continue;
          batchWidget = _buildExportableBatchCard(
            event: event,
            batchGroups: batchGroups,
            l10n: l10n,
            isMarathi: isMarathi,
            title: title,
            dateString: dateString,
            theme: exportTheme,
          );
        } else {
          final List<Widget> batchCards = [];
          for (int i = startGroup; i <= endGroup; i++) {
            final int startIdx = (i - 1) * groupSize;
            if (startIdx >= participants.length) break;
            final int endIdx = (startIdx + groupSize).clamp(
              0,
              participants.length,
            );
            final List<ParayanMember> groupParticipants = participants.sublist(
              startIdx,
              endIdx,
            );
            if (batchCards.isNotEmpty) {
              batchCards.add(const SizedBox(height: 16));
            }
            batchCards.add(
              _buildExportableGroupCard(
                event: event,
                groupNumber: i,
                participants: groupParticipants,
                l10n: l10n,
                isMarathi: isMarathi,
                title: title,
                dateString: dateString,
                theme: exportTheme,
              ),
            );
          }
          if (batchCards.isEmpty) continue;
          batchWidget = Column(
            mainAxisSize: MainAxisSize.min,
            children: batchCards,
          );
        }

        final wrappedWidget = MediaQuery(
          data: MediaQueryData(
            size: const Size(420, 2500),
            devicePixelRatio: 2.0,
          ),
          child: Directionality(
            textDirection: ui.TextDirection.ltr,
            child: Theme(
              data: exportTheme,
              child: UnconstrainedBox(
                alignment: Alignment.topCenter,
                child: Container(
                  width: 420,
                  color: exportTheme.appColors.surface,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      batchWidget,
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        final imageBytes = await _screenshotController.captureFromWidget(
          wrappedWidget,
          pixelRatio: 2.0,
          delay: const Duration(milliseconds: 250),
        );

        final String startFormatted = _formatNumberInternal(
          startGroup,
          isMarathi,
        );
        final String endFormatted = _formatNumberInternal(endGroup, isMarathi);
        final String fileName =
            'Parayan_Groups_$startFormatted-$endFormatted.png';
        final File file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(imageBytes);
        files.add(XFile(file.path));
      }

      if (context.mounted) Navigator.of(context).pop(); // Close loading dialog

      if (files.isNotEmpty) {
        await SharePlus.instance.share(ShareParams(files: files, text: shareText));
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  Widget _buildExportableGroupCard({
    required ParayanEvent event,
    required int groupNumber,
    required List<ParayanMember> participants,
    required AppLocalizations l10n,
    required bool isMarathi,
    required String title,
    required String dateString,
    required ThemeData theme,
  }) {
    final date = dateString;
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 420, // Slightly wider to accommodate serial number column
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        decoration: BoxDecoration(
          color: theme.appColors.surface,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Image.asset(
                  'resources/images/logo/App_Logo.png',
                  width: 50,
                  height: 50,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.seattleGajananMaharajParivar,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.appColors.primarySwatch,
                        ),
                      ),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Divider(
              height: 24,
              thickness: 1.5,
              color: theme.appColors.primarySwatch,
            ),

            // Group Number + Date in same row
            if (event.status != 'upcoming' && event.status != 'enrolling')
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: theme.appColors.primarySwatch.withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        l10n.groupLabel(
                          _formatNumberInternal(groupNumber, isMarathi),
                        ),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.appColors.primarySwatch,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      "${l10n.dateLabel}: $date",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  "${l10n.dateLabel}: $date",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            // Participants Table with serial number column
            if (event.type == ParayanType.threeDay)
              // 3-day: 4-column layout — Day 1, Day 2, Day 3 each show adhyay# + ✓/pending
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(2.0),
                  1: FlexColumnWidth(1.2),
                  2: FlexColumnWidth(1.2),
                  3: FlexColumnWidth(1.2),
                },
                border: TableBorder.all(color: theme.colorScheme.outline),
                children: [
                  TableRow(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4.0,
                          vertical: 4.0,
                        ),
                        child: Text(
                          l10n.parayanParticipant,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4.0,
                          vertical: 4.0,
                        ),
                        child: Text(
                          l10n.day1Label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4.0,
                          vertical: 4.0,
                        ),
                        child: Text(
                          l10n.day2Label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4.0,
                          vertical: 4.0,
                        ),
                        child: Text(
                          l10n.day3Label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  ...participants.map((p) {
                    Widget dayCell(int dayIndex) {
                      final adhyay = dayIndex <= p.assignedAdhyays.length
                          ? p.assignedAdhyays[dayIndex - 1]
                          : null;
                      final isDone =
                          p.completions[dayIndex.toString()] ?? false;
                      final label = adhyay != null
                          ? _formatNumberInternal(adhyay, isMarathi)
                          : '–';
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                label,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isDone
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isDone
                                      ? theme.appColors.success
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            if (isDone) ...[
                              const SizedBox(width: 2),
                              Icon(
                                Icons.check,
                                size: 12,
                                color: theme.appColors.success,
                              ),
                            ],
                          ],
                        ),
                      );
                    }

                    return TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4.0,
                            vertical: 4.0,
                          ),
                          child: Text(
                            p.name,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        dayCell(1),
                        dayCell(2),
                        dayCell(3),
                      ],
                    );
                  }),
                ],
              )
            else
              // 1-day: 4-column layout — # | Participant | Adhyay | Status
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(0.5),
                  1: FlexColumnWidth(2.5),
                  2: FlexColumnWidth(1.0),
                  3: FlexColumnWidth(1.0),
                },
                border: TableBorder.all(color: theme.colorScheme.outline),
                children: [
                  TableRow(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4.0,
                          vertical: 4.0,
                        ),
                        child: Text(
                          '#',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4.0,
                          vertical: 4.0,
                        ),
                        child: Text(
                          l10n.parayanParticipant,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4.0,
                          vertical: 4.0,
                        ),
                        child: Text(
                          l10n.adhyaysLabel,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4.0,
                          vertical: 4.0,
                        ),
                        child: Text(
                          l10n.statusLabel,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  ...participants.asMap().entries.map(
                    (entry) => TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4.0,
                            vertical: 4.0,
                          ),
                          child: Text(
                            _formatNumberInternal(entry.key + 1, isMarathi),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4.0,
                            vertical: 4.0,
                          ),
                          child: Text(
                            entry.value.name,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4.0,
                            vertical: 4.0,
                          ),
                          child: Text(
                            entry.value.assignedAdhyays
                                .map((a) => _formatNumberInternal(a, isMarathi))
                                .join(', '),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4.0,
                            vertical: 4.0,
                          ),
                          child: Text(
                            entry.value.isFullyCompleted ? "Done" : "Pending",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: entry.value.isFullyCompleted
                                  ? theme.appColors.success
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 16),

            // Footer
            Center(
              child: Text(
                l10n.jaiGajanan,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.appColors.brandAccent, // Maroon color from theme
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Renders a single export image for up to 3 groups of a 3-day parayan.
  /// One shared header, one unified grid with full-width group separator rows,
  /// actual event dates as column headers, and one footer.
  Widget _buildExportableBatchCard({
    required ParayanEvent event,
    required List<MapEntry<int, List<ParayanMember>>> batchGroups,
    required AppLocalizations l10n,
    required bool isMarathi,
    required String title,
    required String dateString,
    required ThemeData theme,
  }) {
    // Dynamic column widths — total 380px matches inner container (420 - 16*2)
    const double nameColW = 152.0;
    final int daysCount = event.type.daysCount;
    final double dayColW = (380.0 - nameColW) / daysCount;

    String dayHeader(int dayOffset) {
      final date = event.startDate.add(Duration(days: dayOffset));
      return isMarathi
          ? DateFormat('d MMM', 'mr').format(date)
          : DateFormat('MMM d').format(date);
    }

    // A single bordered cell
    Widget cell({
      required Widget child,
      required double width,
      bool rightBorder = true,
      bool bottomBorder = true,
      Color? background,
      AlignmentGeometry alignment = Alignment.center,
    }) {
      return Container(
        width: width,
        alignment: alignment,
        decoration: BoxDecoration(
          color: background,
          border: Border(
            right: rightBorder
                ? BorderSide(color: theme.appColors.divider)
                : BorderSide.none,
            bottom: bottomBorder
                ? BorderSide(color: theme.appColors.divider)
                : BorderSide.none,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: child,
      );
    }

    // A day-data cell with adhyay number + optional ✓
    Widget dayCell(
      ParayanMember p,
      int dayIndex, {
      bool bottomBorder = true,
      bool rightBorder = true,
    }) {
      final adhyay = dayIndex <= p.assignedAdhyays.length
          ? p.assignedAdhyays[dayIndex - 1]
          : null;
      final isDone = p.completions[dayIndex.toString()] ?? false;
      return cell(
        width: dayColW,
        rightBorder: rightBorder,
        bottomBorder: bottomBorder,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              adhyay != null ? '$adhyay' : '–',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
                color: theme.colorScheme.onSurface,
              ),
            ),
            if (isDone) ...[
              const SizedBox(width: 2),
              Icon(Icons.check, size: 11, color: theme.appColors.success),
            ],
          ],
        ),
      );
    }

    // Build grid rows
    final rows = <Widget>[];

    // ── Header row ──
    rows.add(
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            cell(
              child: Text(
                l10n.parayanParticipant,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              width: nameColW,
              background: theme.appColors.primarySwatch,
              alignment: Alignment.center,
            ),
            ...List.generate(daysCount, (i) => cell(
              child: Text(
                dayHeader(i),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              width: dayColW,
              background: theme.appColors.primarySwatch,
              rightBorder: i < daysCount - 1,
            )),
          ],
        ),
      ),
    );

    for (int gi = 0; gi < batchGroups.length; gi++) {
      final groupNumber = batchGroups[gi].key;
      final members = batchGroups[gi].value;
      final isLastGroup = gi == batchGroups.length - 1;

      // ── Full-width group separator row ──
      if (event.status != 'upcoming' && event.status != 'enrolling') {
        rows.add(
          Container(
            width: nameColW + dayColW * daysCount,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 3),
            decoration: BoxDecoration(
              color: theme.appColors.primarySwatch.withValues(alpha: 0.12),
              border: Border(
                bottom: BorderSide(color: theme.appColors.divider),
              ),
            ),
            child: Text(
              l10n.groupLabel(_formatNumberInternal(groupNumber, isMarathi)),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: theme.appColors.primarySwatch,
              ),
            ),
          ),
        );
      }

      // ── Participant rows ──
      for (int pi = 0; pi < members.length; pi++) {
        final p = members[pi];
        final isLastRow = isLastGroup && pi == members.length - 1;
        rows.add(
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                cell(
                  child: Text(
                    p.name,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  width: nameColW,
                  alignment: Alignment.centerLeft,
                  bottomBorder: !isLastRow,
                ),
                ...List.generate(daysCount, (i) => dayCell(
                  p,
                  i + 1,
                  rightBorder: i < daysCount - 1,
                  bottomBorder: !isLastRow,
                )),
              ],
            ),
          ),
        );
      }
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 420,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: theme.appColors.surface,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              // Shared header
              Row(
                children: [
                  Image.asset(
                    'resources/images/logo/App_Logo.png',
                    width: 44,
                    height: 44,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.seattleGajananMaharajParivar,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: theme.appColors.primarySwatch,
                          ),
                        ),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Divider(
                height: 16,
                thickness: 1.5,
                color: theme.appColors.primarySwatch,
              ),

              // Unified grid with outer border
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: theme.appColors.divider),
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: rows),
              ),

              const SizedBox(height: 20),

              // Footer
              Center(
                child: Text(
                  l10n.jaiGajanan,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.appColors.brandAccent,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }
}

// ── Private stat-card widgets ────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtext;

  const _StatCard({
    required this.label,
    required this.value,
    required this.subtext,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 1.2,
                color: theme.appColors.secondaryText,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              textAlign: TextAlign.center,
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            if (subtext.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                subtext,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.appColors.secondaryText,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProgressStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtext;
  final double progress;

  const _ProgressStatCard({
    required this.label,
    required this.value,
    required this.subtext,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 1.2,
                color: theme.appColors.secondaryText,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 72,
                    width: 72,
                    child: CircularProgressIndicator(
                      value: progress,
                      backgroundColor: theme.colorScheme.onSurface.withValues(
                        alpha: 0.1,
                      ),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                      strokeWidth: 6,
                    ),
                  ),
                  Text(
                    value,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              subtext,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.appColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class KeepAlivePage extends StatefulWidget {
  final Widget child;
  const KeepAlivePage({super.key, required this.child});

  @override
  State<KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

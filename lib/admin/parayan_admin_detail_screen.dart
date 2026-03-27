import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/admin/admin_audit_service.dart';
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

  Future<void> _sendManualPing() async {
    // TODO: Implement Firestore update to trigger manual ping Cloud Function
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.manualPingLabel)),
    );
  }

  Future<void> _updateStatus(String? newStatus) async {
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
        await _parayanService.allocateAdhyays(widget.event.id);
      } else {
        await _parayanService.updateEventStatus(widget.event.id, newStatus);
      }

      await AdminAuditService.logAction(
        action: 'UPDATE_PARAYAN_STATUS',
        details: {
          'event_id': widget.event.id,
          'old_status': widget.event.status,
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
            title: Text(
              Localizations.localeOf(context).languageCode == 'mr'
                  ? event.titleMr
                  : event.titleEn,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.home),
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
              ),
              IconButton(
                icon: const Icon(Icons.settings),
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
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
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
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 12),
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: null, // Disabled for now (Coming Soon)
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.12),
                      disabledForegroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.38),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.notification_important, size: 20),
                    label: Text(l10n.manualPingLabel),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final shareText =
                              'Join this Parayan: ${event.titleEn}\n\nLink: https://gajananmaharajsevekari.org/parayan/${event.id}';
                          Share.share(shareText);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
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
                        onPressed: participants.isNotEmpty
                            ? () => _exportAllGroups(context, event, l10n)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade200,
                          disabledForegroundColor: Colors.grey.shade400,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.ios_share, size: 20),
                        label: Text(l10n.exportAllocations),
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
        const SizedBox(height: 12),
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
                    _updateStatus(value);
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
                    _updateStatus(value);
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
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
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
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
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
                    final statusColor = isSent
                        ? Colors.green
                        : theme.colorScheme.onSurface.withValues(alpha: 0.5);

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
                                const Icon(
                                  Icons.check_circle,
                                  size: 14,
                                  color: Colors.green,
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
                style: const TextStyle(color: Colors.red),
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
                                            ? Colors.green.withValues(
                                                alpha: 0.15,
                                              )
                                            : theme
                                                  .colorScheme
                                                  .primaryContainer,
                                        child: Icon(
                                          isUpToDate
                                              ? Icons.check_circle
                                              : Icons.person_outline,
                                          color: isUpToDate
                                              ? Colors.green
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
                                                          ? Colors.green
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
                          icon: const Icon(Icons.message, color: Colors.green),
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
                                  deviceId: member.deviceId!,
                                  memberName: member.name,
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
          batchWidget = _buildExportableThreeDayBatchCard(
            event: event,
            batchGroups: batchGroups,
            l10n: l10n,
            isMarathi: isMarathi,
            title: title,
            dateString: dateString,
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
              ),
            );
          }
          if (batchCards.isEmpty) continue;
          batchWidget = Material(
            color: Colors.transparent,
            child: OverflowBox(
              minHeight: 0,
              maxHeight: double.infinity,
              alignment: Alignment.topCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: batchCards,
              ),
            ),
          );
        }

        final imageBytes = await _screenshotController.captureFromWidget(
          batchWidget,
          delay: const Duration(milliseconds: 100),
          pixelRatio: 2.0,
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
        await Share.shareXFiles(files, text: shareText);
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
  }) {
    final date = dateString;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 400, // Fixed width for consistent export look
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.orange, width: 2),
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
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32, thickness: 1.5, color: Colors.orange),

            // Group Number
            if (event.status != 'upcoming' && event.status != 'enrolling')
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    l10n.groupLabel(
                      _formatNumberInternal(groupNumber, isMarathi),
                    ),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ),
            if (event.status != 'upcoming' && event.status != 'enrolling')
              const SizedBox(height: 24),

            // Date
            Text(
              "${l10n.dateLabel}: $date",
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),

            // Participants Table
            if (event.type == ParayanType.threeDay)
              // 3-day: 4-column layout — Day 1, Day 2, Day 3 each show adhyay# + ✓/pending
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(2.0),
                  1: FlexColumnWidth(1.2),
                  2: FlexColumnWidth(1.2),
                  3: FlexColumnWidth(1.2),
                },
                border: TableBorder.all(color: Colors.grey.shade300),
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: Colors.grey.shade100),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
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
                        padding: const EdgeInsets.all(8.0),
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
                        padding: const EdgeInsets.all(8.0),
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
                        padding: const EdgeInsets.all(8.0),
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
                                      ? Colors.green.shade700
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ),
                            if (isDone) ...[
                              const SizedBox(width: 2),
                              Icon(
                                Icons.check,
                                size: 12,
                                color: Colors.green.shade700,
                              ),
                            ],
                          ],
                        ),
                      );
                    }

                    return TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            p.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13),
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
              // 1-day: original 3-column layout — Participant | Adhyay | Status
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(2.5),
                  1: FlexColumnWidth(1.2),
                  2: FlexColumnWidth(1),
                },
                border: TableBorder.all(color: Colors.grey.shade300),
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: Colors.grey.shade100),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
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
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          l10n.adhyaysLabel,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          l10n.statusLabel,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  ...participants.map(
                    (p) => TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            p.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            p.assignedAdhyays
                                .map((a) => _formatNumberInternal(a, isMarathi))
                                .join(', '),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            p.isFullyCompleted ? "Done" : "Pending",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: p.isFullyCompleted
                                  ? Colors.green.shade700
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 32),

            // Footer
            Center(
              child: Text(
                l10n.jaiGajanan,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF9B3746), // Maroon color from theme
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Renders a single export image for up to 3 groups of a 3-day parayan.
  /// One shared header, one unified grid with full-width group separator rows,
  /// actual event dates as column headers, and one footer.
  Widget _buildExportableThreeDayBatchCard({
    required ParayanEvent event,
    required List<MapEntry<int, List<ParayanMember>>> batchGroups,
    required AppLocalizations l10n,
    required bool isMarathi,
    required String title,
    required String dateString,
  }) {
    // Fixed column widths — total 380px matches inner container (420 - 20*2)
    const double nameColW = 152.0;
    const double dayColW = 76.0;

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
                ? BorderSide(color: Colors.grey.shade300)
                : BorderSide.none,
            bottom: bottomBorder
                ? BorderSide(color: Colors.grey.shade300)
                : BorderSide.none,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
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
                color: isDone ? Colors.green.shade700 : Colors.grey.shade600,
              ),
            ),
            if (isDone) ...[
              const SizedBox(width: 2),
              Icon(Icons.check, size: 11, color: Colors.green.shade700),
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
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              width: nameColW,
              background: Colors.grey.shade200,
              alignment: Alignment.center,
            ),
            cell(
              child: Text(
                dayHeader(0),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              width: dayColW,
              background: Colors.grey.shade200,
            ),
            cell(
              child: Text(
                dayHeader(1),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              width: dayColW,
              background: Colors.grey.shade200,
            ),
            cell(
              child: Text(
                dayHeader(2),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              width: dayColW,
              background: Colors.grey.shade200,
              rightBorder: false,
            ),
          ],
        ),
      ),
    );

    for (int gi = 0; gi < batchGroups.length; gi++) {
      final groupNumber = batchGroups[gi].key;
      final members = batchGroups[gi].value;
      final isLastGroup = gi == batchGroups.length - 1;

      // ── Full-width group separator row ──
      if (event.status != 'upcoming' && event.status != 'enrolling')
        rows.add(
          Container(
            width: nameColW + dayColW * 3,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.12),
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Text(
              l10n.groupLabel(_formatNumberInternal(groupNumber, isMarathi)),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.orange,
              ),
            ),
          ),
        );

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
                  child: Text(p.name, style: const TextStyle(fontSize: 12)),
                  width: nameColW,
                  alignment: Alignment.centerLeft,
                  bottomBorder: !isLastRow,
                ),
                dayCell(p, 1, bottomBorder: !isLastRow),
                dayCell(p, 2, bottomBorder: !isLastRow),
                dayCell(p, 3, rightBorder: false, bottomBorder: !isLastRow),
              ],
            ),
          ),
        );
      }
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.orange, width: 2),
        ),
        child: OverflowBox(
          minHeight: 0,
          maxHeight: double.infinity,
          alignment: Alignment.topCenter,
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
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 20, thickness: 1.5, color: Colors.orange),

              // Unified grid with outer border
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: rows),
              ),

              const SizedBox(height: 20),

              // Footer
              Center(
                child: Text(
                  l10n.jaiGajanan,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF9B3746),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
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
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
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
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
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
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
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
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
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

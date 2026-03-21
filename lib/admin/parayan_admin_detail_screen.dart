import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/parayan_event.dart';
import 'package:gajanan_maharaj_sevekari/models/parayan_participant.dart';
import 'package:gajanan_maharaj_sevekari/parayan/parayan_type.dart';
import 'package:gajanan_maharaj_sevekari/providers/parayan_service.dart';
import 'package:gajanan_maharaj_sevekari/utils/marathi_utils.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:intl/intl.dart';

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
  late Stream<List<ParayanMember>> _overviewParticipantsStream;
  late Stream<List<ParayanMember>> _participantsTabStream;
  late Stream<ParayanEvent> _eventStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _overviewParticipantsStream = _parayanService.getAllParticipants(widget.event.id);
    _participantsTabStream = _parayanService.getAllParticipants(widget.event.id);
    _eventStream = _parayanService.getEventById(widget.event.id);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatNumber(BuildContext context, dynamic number) {
    if (number == null) return '';
    String numStr = number.toString();
    final isMarathi = Localizations.localeOf(context).languageCode == 'mr';
    return isMarathi ? toMarathiNumerals(numStr) : numStr;
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
    try {
      await _parayanService.updateEventStatus(widget.event.id, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.statusUpdateSuccess)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
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
          unselectedLabelColor:
              theme.appBarTheme.foregroundColor?.withValues(alpha: 0.6),
          indicatorColor: theme.appBarTheme.foregroundColor,
          indicatorWeight: 3.0,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
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
          KeepAlivePage(child: _buildOverviewTab(localizations, theme, event)),
          KeepAlivePage(child: _buildParticipantsTab(localizations, theme, event)),
        ],
      ),
    );
  },
);
}
  // ── Overview Tab ────────────────────────────────────────────────────────────

  Widget _buildOverviewTab(
      AppLocalizations l10n, ThemeData theme, ParayanEvent event) {
    return StreamBuilder<List<ParayanMember>>(
      stream: _overviewParticipantsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final participants = snapshot.data ?? [];
        final adhyaysPerPerson = event.type == ParayanType.oneDay ? 1 : 3;
        final totalAdhyays = participants.length * adhyaysPerPerson;

        int completedAdhyays = 0;
        for (final p in participants) {
          completedAdhyays += p.completions.values.where((c) => c).length;
        }

        final progress =
            totalAdhyays > 0 ? completedAdhyays / totalAdhyays : 0.0;

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
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _sendManualPing,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.notification_important, size: 20),
                  label: Text(l10n.manualPingLabel),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    final shareText =
                        'Join this Parayan: ${event.titleEn}\n\nLink: http://gajananmaharajsevekari.org/parayan/${event.id}';
                    Share.share(shareText);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    foregroundColor: theme.colorScheme.onSecondaryContainer,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.share, size: 20),
                  label: const Text("Share Parayan"),
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
      AppLocalizations l10n, ThemeData theme, ParayanEvent event) {
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
        Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'enrolling',
                  label: Text(l10n.statusEnrolling,
                      style: const TextStyle(fontSize: 12)),
                  icon: const Icon(Icons.person_add_outlined, size: 16),
                ),
                ButtonSegment(
                  value: 'allocated',
                  label: Text(l10n.statusAllocated,
                      style: const TextStyle(fontSize: 12)),
                  icon:
                      const Icon(Icons.assignment_turned_in_outlined, size: 16),
                ),
                ButtonSegment(
                  value: 'ongoing',
                  label: Text(l10n.statusOngoing,
                      style: const TextStyle(fontSize: 12)),
                  icon: const Icon(Icons.play_circle_outline, size: 16),
                ),
                ButtonSegment(
                  value: 'completed',
                  label: Text(l10n.statusCompleted,
                      style: const TextStyle(fontSize: 12)),
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                ),
              ],
              selected: {event.status},
              onSelectionChanged: (Set<String> newSelection) {
                _updateStatus(newSelection.first);
              },
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: theme.colorScheme.primary,
                selectedForegroundColor: theme.colorScheme.onPrimary,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRemindersSection(
      AppLocalizations l10n, ThemeData theme, ParayanEvent event) {
    final now = DateTime.now();
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
                          color:
                              theme.colorScheme.onSurface.withValues(alpha: 0.5),
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

                    final reminderHour =
                        int.tryParse(reminderTimeParts[0]) ?? 20;
                    final reminderMin =
                        int.tryParse(reminderTimeParts[1]) ?? 0;

                    final reminderDateTime = DateTime(
                      dayDate.year,
                      dayDate.month,
                      dayDate.day,
                      reminderHour,
                      reminderMin,
                    );

                    final isSent = now.isAfter(reminderDateTime);
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
                                const Icon(Icons.check_circle,
                                    size: 14, color: Colors.green),
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
      AppLocalizations l10n, ThemeData theme, ParayanEvent event) {
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

        final participants = snapshot.data ?? [];

        if (participants.isEmpty) {
          return Center(child: Text(l10n.noResultsFound));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: participants.length,
          itemBuilder: (context, index) {
            final p = participants[index];
            final allDone = p.completions.values.every((v) => v);

            final int groupSize = (event.type == ParayanType.threeDay) ? 7 : 21;
            final int groupNumber = (index ~/ groupSize) + 1;

            return Card(
              // Uses AppTheme.cardTheme: color, elevation, shape, border
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: allDone
                      ? Colors.green.withValues(alpha: 0.15)
                      : theme.colorScheme.primaryContainer,
                  child: Icon(
                    allDone ? Icons.check_circle : Icons.person_outline,
                    color: allDone
                        ? Colors.green
                        : theme.colorScheme.primary,
                  ),
                ),
                title: Text(
                  p.name,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "${l10n.groupLabel(groupNumber.toString())} • ${l10n.adminAdhyaysLabel(p.assignedAdhyays.join(', '))}",
                  style: theme.textTheme.bodySmall,
                ),
                trailing: IconButton(
                  icon: Icon(Icons.edit_note,
                      color: theme.colorScheme.primary),
                  onPressed: () => _showParticipantEditDialog(context, l10n, p, event, groupNumber),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showParticipantEditDialog(
      BuildContext context, AppLocalizations l10n, ParayanMember member, ParayanEvent event, int groupNumber) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text("${member.name} (${l10n.groupLabel(groupNumber.toString())})"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (member.email != null && member.email!.isNotEmpty)
                      ListTile(
                        leading: const Icon(Icons.email),
                        title: Text(member.email!),
                        visualDensity: VisualDensity.compact,
                        contentPadding: EdgeInsets.zero,
                      ),
                    if (member.phone != null && member.phone!.isNotEmpty)
                      ListTile(
                        leading: const Icon(Icons.phone),
                        title: Text(member.phone!),
                        visualDensity: VisualDensity.compact,
                        contentPadding: EdgeInsets.zero,
                      ),
                    const Divider(),
                    Text(
                      l10n.adhyayCompletionTitle.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.1),
                    ),
                    const SizedBox(height: 8),
                    ...member.assignedAdhyays.asMap().entries.map((entry) {
                      final idx = entry.key + 1;
                      final adhyay = entry.value;
                      final isDone = member.completions[idx.toString()] ?? false;
                      return CheckboxListTile(
                        title: Text("${l10n.day} ${_formatNumber(context, idx)}: ${l10n.adhyay} ${_formatNumber(context, adhyay)}"),
                        value: isDone,
                        onChanged: (val) async {
                          if (val == null) return;
                          try {
                            await _parayanService.updateMemberCompletion(
                              eventId: event.id,
                              deviceId: member.deviceId!,
                              memberName: member.name,
                              dayIndex: idx,
                              completed: val,
                            );
                            setDialogState(() {
                               member.completions[idx.toString()] = val;
                            });
                          } catch (e) {
                             if (mounted) {
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
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.closeLabel),
                ),
              ],
            );
          },
        );
      },
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
                      backgroundColor:
                          theme.colorScheme.onSurface.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary),
                      strokeWidth: 6,
                    ),
                  ),
                  Text(
                    value,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
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

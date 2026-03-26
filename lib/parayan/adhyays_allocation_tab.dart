import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/parayan/parayan_type.dart';
import 'package:gajanan_maharaj_sevekari/models/parayan_event.dart';
import 'package:gajanan_maharaj_sevekari/models/parayan_participant.dart';
import 'package:gajanan_maharaj_sevekari/providers/parayan_service.dart';

class AdhyaysAllocationTab extends StatefulWidget {
  final ParayanEvent event;

  const AdhyaysAllocationTab({super.key, required this.event});

  @override
  State<AdhyaysAllocationTab> createState() => _AdhyaysAllocationTabState();
}

class _AdhyaysAllocationTabState extends State<AdhyaysAllocationTab>
    with AutomaticKeepAliveClientMixin {
  final ParayanService _parayanService = ParayanService();
  late Stream<List<ParayanMember>> _participantsStream;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _participantsStream = _parayanService.getAllParticipants(widget.event.id);
  }

  String _formatNumber(BuildContext context, int number, {bool pad = false}) {
    String numStr = pad ? number.toString().padLeft(2, '0') : number.toString();
    final isMarathi = Localizations.localeOf(context).languageCode == 'mr';
    if (!isMarathi) return numStr;

    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const marathi = ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'];
    for (int i = 0; i < english.length; i++) {
      numStr = numStr.replaceAll(english[i], marathi[i]);
    }
    return numStr;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    return StreamBuilder<List<ParayanMember>>(
      stream: _participantsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final participants = (snapshot.data ?? [])
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
        final bool isThreeDay = widget.event.type == ParayanType.threeDay;
        final bool showHeaders =
            widget.event.status != 'upcoming' &&
            widget.event.status != 'enrolling';

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // Header Row
                Container(
                  decoration: BoxDecoration(
                    color:
                        theme.cardTheme.color?.withValues(alpha: 0.8) ??
                        const Color(0xFF1E1E1E).withValues(alpha: 0.8),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child: Table(
                    columnWidths: {
                      0: const FlexColumnWidth(2),
                      if (isThreeDay) ...{
                        1: const FlexColumnWidth(1),
                        2: const FlexColumnWidth(1),
                        3: const FlexColumnWidth(1),
                      } else
                        1: const FlexColumnWidth(1),
                    },
                    children: [
                      TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            child: Text(
                              localizations.name,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.secondary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          if (isThreeDay) ...[
                            _buildHeaderCell(localizations.day1Label, theme),
                            _buildHeaderCell(localizations.day2Label, theme),
                            _buildHeaderCell(localizations.day3Label, theme),
                          ] else
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              child: Text(
                                localizations.adhyay,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.secondary,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Data Rows
                // Data Rows
                Container(
                  decoration: BoxDecoration(
                    color:
                        theme.cardTheme.color?.withValues(alpha: 0.3) ??
                        const Color(0xFF1E1E1E).withValues(alpha: 0.3),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(12),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: participants.isEmpty
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            widget.event.status == 'upcoming'
                                ? localizations.upcomingParayanMessage
                                : localizations.noSignupsFound,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.hintColor,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : Builder(
                          builder: (context) {
                            final Map<int, List<ParayanMember>> grouped = {};
                            final int gSize = isThreeDay ? 7 : 21;
                            for (int i = 0; i < participants.length; i++) {
                              final p = participants[i];
                              final int gNum =
                                  p.groupNumber ?? (i ~/ gSize) + 1;
                              grouped.putIfAbsent(gNum, () => []).add(p);
                            }
                            final sortedGroupKeys = grouped.keys.toList()
                              ..sort();

                            return Column(
                              children: sortedGroupKeys.map((gNum) {
                                final members = grouped[gNum]!;

                                return Column(
                                  children: [
                                    // Group Header Row
                                    if (showHeaders)
                                      Container(
                                        width: double.infinity,
                                        alignment: Alignment.center,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                          horizontal: 16,
                                        ),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary
                                              .withValues(alpha: 0.1),
                                          border: Border(
                                            bottom: BorderSide(
                                              color: theme.colorScheme.primary
                                                  .withValues(alpha: 0.2),
                                            ),
                                            top: gNum > 1
                                                ? BorderSide(
                                                    color: theme
                                                        .colorScheme
                                                        .primary
                                                        .withValues(alpha: 0.2),
                                                  )
                                                : BorderSide.none,
                                          ),
                                        ),
                                        child: Text(
                                          localizations.groupLabel(
                                            _formatNumber(context, gNum),
                                          ),
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    theme.colorScheme.primary,
                                                letterSpacing: 1,
                                              ),
                                        ),
                                      ),
                                    Table(
                                      columnWidths: {
                                        0: const FlexColumnWidth(2),
                                        if (isThreeDay) ...{
                                          1: const FlexColumnWidth(1),
                                          2: const FlexColumnWidth(1),
                                          3: const FlexColumnWidth(1),
                                        } else
                                          1: const FlexColumnWidth(1),
                                      },
                                      defaultVerticalAlignment:
                                          TableCellVerticalAlignment.middle,
                                      children: members.asMap().entries.map((
                                        entry,
                                      ) {
                                        final pi = entry.key;
                                        final p = entry.value;
                                        final isEnrolling =
                                            widget.event.status == 'enrolling';
                                        final isEven = pi % 2 == 0;

                                        final rowDecoration = BoxDecoration(
                                          color: isEven
                                              ? Colors.transparent
                                              : theme.hintColor.withValues(
                                                  alpha: 0.03,
                                                ),
                                        );

                                        final nameWidget = Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 14,
                                          ),
                                          child: Text(
                                            p.name,
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  fontSize: isThreeDay
                                                      ? 13
                                                      : 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: theme
                                                      .colorScheme
                                                      .onSurface
                                                      .withValues(alpha: 0.9),
                                                ),
                                          ),
                                        );

                                        final hasAnyUnallocated =
                                            p.assignedAdhyays.isEmpty;

                                        if (isEnrolling || hasAnyUnallocated) {
                                          return TableRow(
                                            decoration: rowDecoration,
                                            children: [
                                              nameWidget,
                                              if (isThreeDay) ...[
                                                _buildStatusCell(locale, theme),
                                                _buildStatusCell(locale, theme),
                                                _buildStatusCell(locale, theme),
                                              ] else
                                                _buildStatusCell(locale, theme),
                                            ],
                                          );
                                        }

                                        // For allocated states
                                        if (isThreeDay) {
                                          return TableRow(
                                            decoration: rowDecoration,
                                            children: [
                                              nameWidget,
                                              _buildAdhyayCell(
                                                context,
                                                p.assignedAdhyays.isNotEmpty
                                                    ? p.assignedAdhyays[0]
                                                    : null,
                                                p.completions['1'] ?? false,
                                                theme,
                                              ),
                                              _buildAdhyayCell(
                                                context,
                                                p.assignedAdhyays.length > 1
                                                    ? p.assignedAdhyays[1]
                                                    : null,
                                                p.completions['2'] ?? false,
                                                theme,
                                              ),
                                              _buildAdhyayCell(
                                                context,
                                                p.assignedAdhyays.length > 2
                                                    ? p.assignedAdhyays[2]
                                                    : null,
                                                p.completions['3'] ?? false,
                                                theme,
                                              ),
                                            ],
                                          );
                                        } else {
                                          final isRead =
                                              p.completions['1'] ?? false;
                                          return TableRow(
                                            decoration: rowDecoration,
                                            children: [
                                              nameWidget,
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 12,
                                                    ),
                                                child: Wrap(
                                                  spacing: 6,
                                                  runSpacing: 4,
                                                  alignment:
                                                      WrapAlignment.center,
                                                  children: p.assignedAdhyays
                                                      .map(
                                                        (a) =>
                                                            _buildAdhyayCircle(
                                                              context,
                                                              a,
                                                              theme,
                                                              isRead: isRead,
                                                            ),
                                                      )
                                                      .toList(),
                                                ),
                                              ),
                                            ],
                                          );
                                        }
                                      }).toList(),
                                    ),
                                  ],
                                );
                              }).toList(),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAdhyayCell(
    BuildContext context,
    int? adhyay,
    bool isRead,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: _buildAdhyayCircle(context, adhyay, theme, isRead: isRead),
      ),
    );
  }

  Widget _buildHeaderCell(String label, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Center(
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.secondary,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCell(String locale, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Center(child: _buildNotAllocated(locale, theme)),
    );
  }

  Widget _buildNotAllocated(String locale, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.hintColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: theme.hintColor.withValues(alpha: 0.1)),
      ),
      child: Text(
        locale == 'mr' ? "वाटप अद्याप झाले नाही" : "Not allocated",
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.hintColor,
          fontSize: 10,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildAdhyayCircle(
    BuildContext context,
    int? adhyay,
    ThemeData theme, {
    bool isRead = false,
  }) {
    if (adhyay == null) return const SizedBox.shrink();
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: isRead ? Colors.green : theme.colorScheme.primary,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        _formatNumber(context, adhyay),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

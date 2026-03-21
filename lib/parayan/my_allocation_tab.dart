import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/parayan_event.dart';
import 'package:gajanan_maharaj_sevekari/models/parayan_participant.dart';
import 'package:gajanan_maharaj_sevekari/parayan/parayan_type.dart';
import 'package:gajanan_maharaj_sevekari/providers/parayan_service.dart';

class MyAllocationTab extends StatefulWidget {
  final ParayanEvent event;
  final String deviceId;

  const MyAllocationTab({super.key, required this.event, required this.deviceId});

  @override
  State<MyAllocationTab> createState() => _MyAllocationTabState();
}

class _MyAllocationTabState extends State<MyAllocationTab>
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
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return StreamBuilder<List<ParayanMember>>(
      stream: _participantsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allParticipants = snapshot.data ?? [];
        final participants = <MapEntry<int, ParayanMember>>[];
        for (int i = 0; i < allParticipants.length; i++) {
          if (allParticipants[i].deviceId == widget.deviceId) {
            participants.add(MapEntry(i, allParticipants[i]));
          }
        }

        final isEnrolling = widget.event.status == 'enrolling';
        final isAllocated = widget.event.status == 'allocated';
        final isOngoing = widget.event.status == 'ongoing';

        if (participants.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_off_outlined,
                    size: 64,
                    color: theme.hintColor.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.event.status == 'upcoming'
                        ? localizations.upcomingParayanMessage
                        : localizations.noSignupsFound,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.hintColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        if (isEnrolling) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 64,
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    Localizations.localeOf(context).languageCode == 'mr'
                        ? "अध्याय वाटप अद्याप झाले नाही, कृपया नंतर तपासा"
                        : "Adhyay not allocated yet, please check back later",
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.hintColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: participants.length,
          itemBuilder: (context, pIndex) {
            final entry = participants[pIndex];
            final globalIndex = entry.key;
            final participant = entry.value;

            final int groupSize = (widget.event.type == ParayanType.threeDay) ? 7 : 21;
            final int groupNumber = (globalIndex ~/ groupSize) + 1;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (pIndex > 0) const SizedBox(height: 24),
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${participant.name} (${localizations.groupLabel(groupNumber.toString())})',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...participant.assignedAdhyays.asMap().entries.map((entry) {
                  final index = entry.key;
                  final adhyay = entry.value;
                  final dayNum = index + 1;
                  final isRead =
                      participant.completions[dayNum.toString()] ?? false;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildAllocationItem(
                      context,
                      dayNum: dayNum,
                      adhyay: adhyay,
                      isRead: isRead,
                      isOngoing: isOngoing,
                      theme: theme,
                      onComplete: () => _parayanService.updateMemberCompletion(
                        eventId: widget.event.id,
                        deviceId: widget.deviceId,
                        memberName: participant.name,
                        dayIndex: dayNum,
                        completed: true,
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildAllocationItem(
    BuildContext context, {
    required int dayNum,
    required int adhyay,
    required bool isRead,
    required bool isOngoing,
    required ThemeData theme,
    required VoidCallback onComplete,
  }) {
    final localizations = AppLocalizations.of(context)!;

    return Card(
      margin: EdgeInsets.zero,
      color: theme.cardTheme.color ?? const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isRead ? Colors.green.withValues(alpha: 0.5) : Colors.white10,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Day Indicator
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isRead ? Colors.green : theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isRead ? Colors.green : theme.colorScheme.primary,
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                _formatNumber(context, dayNum),
                style: TextStyle(
                  color: isRead
                      ? Colors.white
                      : theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${localizations.day} ${_formatNumber(context, dayNum)}",
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${localizations.adhyay} ${_formatNumber(context, adhyay)}",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (isRead)
              const Icon(Icons.check_circle, color: Colors.green)
            else if (isOngoing)
              ElevatedButton(
                onPressed: () => _showCompletionDialog(context, onComplete),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(localizations.submitLabel),
              )
            else
              Icon(Icons.radio_button_unchecked, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  void _showCompletionDialog(BuildContext context, VoidCallback onComplete) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Completion"),
        content: const Text("Have you finished reading the assigned Adhyay?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("No"),
          ),
          ElevatedButton(
            onPressed: () {
              onComplete();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text("Reading progress updated successfully!")),
              );
            },
            child: const Text("Yes"),
          ),
        ],
      ),
    );
  }
}

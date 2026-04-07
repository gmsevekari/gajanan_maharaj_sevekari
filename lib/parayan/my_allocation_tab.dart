import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/parayan_event.dart';
import 'package:gajanan_maharaj_sevekari/models/parayan_participant.dart';
import 'package:gajanan_maharaj_sevekari/parayan/parayan_type.dart';
import 'package:gajanan_maharaj_sevekari/providers/parayan_service.dart';
import 'package:gajanan_maharaj_sevekari/providers/app_config_provider.dart';
import 'package:gajanan_maharaj_sevekari/shared/content_detail_screen.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:provider/provider.dart';

class MyAllocationTab extends StatefulWidget {
  final ParayanEvent event;
  final String deviceId;

  const MyAllocationTab({
    super.key,
    required this.event,
    required this.deviceId,
  });

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
    _participantsStream = _parayanService.getParticipantsByDevice(
      widget.event.id,
      widget.deviceId,
    );
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

        final participants = snapshot.data ?? [];

        final isEnrolling = widget.event.status == 'enrolling';
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

        final isAllocated = widget.event.status == 'allocated';
        final hasAnyUnallocated = participants.any(
          (p) => p.assignedAdhyays.isEmpty,
        );

        if (isEnrolling || (isAllocated && hasAnyUnallocated)) {
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
                    localizations.upcomingParayanMessage,
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

        return Builder(
          builder: (context) {
            final sortedParticipants = participants.toList()
              ..sort(
                (a, b) => (a.globalIndex ?? 0).compareTo(b.globalIndex ?? 0),
              );

            Widget buildParticipantCard(int pIndex) {
              final theme = Theme.of(context);
              final participant = sortedParticipants[pIndex];

              final int groupSize = (widget.event.type == ParayanType.threeDay)
                  ? 7
                  : 21;
              final int groupNumber =
                  participant.groupNumber ??
                  ((participant.globalIndex ?? 0) ~/ groupSize) + 1;

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
                        onComplete: () =>
                            _parayanService.updateMemberCompletion(
                              eventId: widget.event.id,
                              memberId: participant.id!,
                              dayIndex: dayNum,
                              completed: true,
                              deviceId: widget.deviceId,
                            ),
                      ),
                    );
                  }),
                ],
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ...List.generate(
                  sortedParticipants.length,
                  (pIndex) => buildParticipantCard(pIndex),
                ),
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

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = widget.event.startDate;
    final startDate = DateTime(start.year, start.month, start.day);
    final currentDayOfEvent = today.difference(startDate).inDays + 1;

    // Buttons are enabled if already read, or if it's ongoing and the day has arrived.
    final canInteract = isRead || (isOngoing && dayNum <= currentDayOfEvent);

            void handleReadTap({int initialTabIndex = 0, bool autoPlay = false}) {
              final configProvider = Provider.of<AppConfigProvider>(
                context,
                listen: false,
              );
              final appConfig = configProvider.appConfig;
              if (appConfig == null || appConfig.deities.isEmpty) return;
              final deity = appConfig.deities.firstWhere(
                (d) => d.id == 'gajanan_maharaj',
                orElse: () => appConfig.deities.first,
              );

              final List<Map<String, String>> contentList = List.generate(
                21,
                (index) {
                  final adhyayNum = index + 1;
                  return {
                    'title_en': 'Adhyay $adhyayNum',
                    'title_mr': 'अध्याय ${_formatNumber(context, adhyayNum)}',
                    'assetPath':
                        'resources/texts/gajanan_maharaj/granth/adhyay_$adhyayNum.json',
                    'imagePath':
                        'resources/images/gajanan_maharaj/granth/adhyay_$adhyayNum.png',
                    'youtube_video_id':
                        '', // Optional, the view will load it from JSON
                  };
                },
              );

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ContentDetailScreen(
                    deity: deity,
                    contentType: ContentType.granth,
                    contentList: contentList,
                    currentIndex: adhyay - 1,
                    assetPath:
                        'resources/texts/gajanan_maharaj/granth/adhyay_$adhyay.json',
                    imagePath:
                        'resources/images/gajanan_maharaj/granth/adhyay_$adhyay.png',
                    initialTabIndex: initialTabIndex,
                    autoPlay: autoPlay,
                  ),
                ),
              );
            }

            return Card(
              margin: EdgeInsets.zero,
              color: theme.cardTheme.color,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color:
                      isRead
                          ? theme.appColors.success.withValues(alpha: 0.5)
                          : theme.appColors.divider,
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 8.0,
                ),
                child: Row(
                  children: [
                    // Day Indicator
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color:
                            isRead
                                ? theme.appColors.success
                                : theme.colorScheme.primary.withValues(
                                  alpha: 0.1,
                                ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              isRead
                                  ? theme.appColors.success
                                  : theme.colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.menu_book,
                        size: 20,
                        color:
                            isRead
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        "${localizations.day} ${_formatNumber(context, dayNum)} - ${localizations.adhyay} ${_formatNumber(context, adhyay)}",
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Action Icons
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildActionButton(
                          icon: Icons.chrome_reader_mode_outlined,
                          onPressed: () => handleReadTap(initialTabIndex: 0),
                          isEnabled: canInteract,
                          theme: theme,
                          tooltip: localizations.read,
                        ),
                        _buildActionButton(
                          icon: Icons.play_circle_outline_rounded,
                          onPressed:
                              () => handleReadTap(
                                initialTabIndex: 1,
                                autoPlay: true,
                              ),
                          isEnabled: canInteract,
                          theme: theme,
                          tooltip: localizations.listen,
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    if (isRead)
                      Icon(Icons.check_circle, color: theme.appColors.success)
                    else
                      ElevatedButton(
                        onPressed:
                            canInteract
                                ? () =>
                                    _showCompletionDialog(context, onComplete)
                                : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              canInteract
                                  ? theme.colorScheme.primary
                                  : theme.appColors.disabledBackground,
                          foregroundColor:
                              canInteract
                                  ? theme.colorScheme.onPrimary
                                  : theme.appColors.disabledText,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(localizations.submitLabel),
                      ),
                  ],
                ),
              ),
            );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isEnabled,
    required ThemeData theme,
    required String tooltip,
  }) {
    return IconButton(
      icon: Icon(icon),
      onPressed: isEnabled ? onPressed : null,
      color: isEnabled ? theme.colorScheme.primary : theme.appColors.disabledText,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(),
    );
  }

  void _showCompletionDialog(BuildContext context, VoidCallback onComplete) {
    final localizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.confirmCompletionTitle),
        content: Text(localizations.confirmCompletionMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.no),
          ),
          ElevatedButton(
            onPressed: () {
              onComplete();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(localizations.readingProgressUpdated),
                ),
              );
            },
            child: Text(localizations.yes),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/group_namjap_event.dart';
import 'package:gajanan_maharaj_sevekari/models/group_namjap_participant.dart';
import 'package:gajanan_maharaj_sevekari/providers/group_namjap_service.dart';
import 'package:gajanan_maharaj_sevekari/providers/group_namjap_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/jap_mala_provider.dart';
import 'package:gajanan_maharaj_sevekari/utils/date_time_utils.dart';
import 'package:gajanan_maharaj_sevekari/utils/marathi_utils.dart';
import 'package:gajanan_maharaj_sevekari/utils/unique_id_service.dart';
import 'package:gajanan_maharaj_sevekari/widgets/themed_icon.dart';
import 'package:gajanan_maharaj_sevekari/jap_mala/widgets/manual_jap_tab.dart';
import 'package:gajanan_maharaj_sevekari/jap_mala/widgets/namjap_signup_dialog.dart';
import 'package:provider/provider.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';

class GroupNamjapDetailScreen extends StatefulWidget {
  final String eventId;
  final String? prefilledJoinCode;

  const GroupNamjapDetailScreen({
    super.key,
    required this.eventId,
    this.prefilledJoinCode,
  });

  @override
  State<GroupNamjapDetailScreen> createState() =>
      _GroupNamjapDetailScreenState();
}

class _GroupNamjapDetailScreenState extends State<GroupNamjapDetailScreen> {
  Stream<GroupNamjapEvent?>? _eventStream;
  Stream<GroupNamjapParticipant?>? _participantStream;
  Stream<int>? _participantsCountStream;

  @override
  void initState() {
    super.initState();
    final service = context.read<GroupNamjapService>();
    _eventStream = service.getEventStream(widget.eventId);
    _participantsCountStream = Stream.value(0);
    _initSync();
  }

  Future<void> _initSync() async {
    final provider = context.read<GroupNamjapProvider>();
    await provider.loadLocalData();

    final deviceId = await UniqueIdService.getUniqueId();
    if (mounted) {
      await provider.syncParticipation(widget.eventId, deviceId);
      _updateParticipantStream();
    }
  }

  void _updateParticipantStream() {
    final provider = context.read<GroupNamjapProvider>();
    final service = context.read<GroupNamjapService>();

    if (provider.isJoined(widget.eventId)) {
      UniqueIdService.getUniqueId().then((deviceId) {
        if (mounted) {
          setState(() {
            _participantStream = service.getParticipantStream(
              widget.eventId,
              deviceId,
              provider.memberName!,
            );
          });
        }
      });
    }
  }

  Future<void> _submitCount(int countToSubmit) async {
    final provider = context.read<GroupNamjapProvider>();
    final currentMemberName = provider.memberName;
    if (currentMemberName == null) return;

    try {
      final service = context.read<GroupNamjapService>();
      final deviceId = await UniqueIdService.getUniqueId();

      await service.submitNamjapCount(
        eventId: widget.eventId,
        deviceId: deviceId,
        memberName: currentMemberName,
        countToSubmit: countToSubmit,
      );
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
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return StreamBuilder<GroupNamjapEvent?>(
      stream: _eventStream,
      builder: (context, snapshot) {
        final event = snapshot.data;
        final title = event == null
            ? localizations.groupNamjapEventDetails
            : (locale == 'mr' ? event.nameMr : event.nameEn);

        return Scaffold(
          appBar: AppBar(
            title: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            backgroundColor: theme.appColors.primarySwatch,
            iconTheme: IconThemeData(color: theme.colorScheme.onPrimary),
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
          ),
          body: snapshot.connectionState == ConnectionState.waiting
              ? const Center(child: CircularProgressIndicator())
              : event == null
              ? Center(child: Text(localizations.groupNamjapEventNotFound))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopEventCard(
                        event,
                        localizations,
                        theme,
                        locale,
                        isLandscape,
                      ),
                      const SizedBox(height: 12),
                      _buildActionRow(
                        event,
                        localizations,
                        theme,
                        locale,
                        isLandscape,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildProgressCardsRow(
                              event,
                              localizations,
                              theme,
                              locale,
                            ),
                            const SizedBox(height: 16),
                            ChangeNotifierProvider(
                              create: (_) => JapMalaProvider(),
                              child: Consumer2<JapMalaProvider, GroupNamjapProvider>(
                                builder:
                                    (context, japProvider, groupProvider, _) {
                                      final isJoined = groupProvider.isJoined(
                                        widget.eventId,
                                      );
                                      final isOngoing =
                                          event.status == 'ongoing';
                                      final canSubmit =
                                          japProvider.totalCount > 0 &&
                                          isJoined &&
                                          isOngoing;

                                      return Column(
                                        children: [
                                          ManualJapTab(
                                            compact: true,
                                            enabled: isJoined && isOngoing,
                                          ),
                                          const SizedBox(height: 12),
                                          SizedBox(
                                            width: double.infinity,
                                            height: 50,
                                            child: ElevatedButton(
                                              onPressed: canSubmit
                                                  ? () async {
                                                      await _submitCount(
                                                        japProvider.totalCount,
                                                      );
                                                      japProvider.reset();
                                                    }
                                                  : null,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: canSubmit
                                                    ? theme.colorScheme.primary
                                                    : theme
                                                          .appColors
                                                          .disabledBackground,
                                                foregroundColor: canSubmit
                                                    ? theme
                                                          .colorScheme
                                                          .onPrimary
                                                    : theme
                                                          .appColors
                                                          .disabledText,
                                                elevation: canSubmit ? 2 : 0,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                              ),
                                              child: FittedBox(
                                                child: Text(
                                                  localizations
                                                      .groupNamjapSubmitCount(
                                                        formatNumberLocalized(
                                                          japProvider
                                                              .totalCount,
                                                          locale,
                                                          pad: false,
                                                        ),
                                                      ),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildTopEventCard(
    GroupNamjapEvent event,
    AppLocalizations localizations,
    ThemeData theme,
    String locale,
    bool isLandscape,
  ) {
    final sankalp = locale == 'mr' ? event.sankalpMr : event.sankalpEn;
    final dateRange =
        '${formatDateShort(event.startDate, locale)} - ${formatDateShort(event.endDate, locale)}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 4.0),
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Vertical Saffron Accent Line
              Container(width: 4, color: theme.colorScheme.primary),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(isLandscape ? 8.0 : 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailItem(
                        theme,
                        Icons.auto_awesome,
                        localizations.groupNamjapSankalpLabel,
                        sankalp,
                        isLandscape,
                      ),
                      const SizedBox(height: 8),
                      _buildDetailItem(
                        theme,
                        Icons.music_note,
                        localizations.mantraLabel,
                        event.mantra,
                        isLandscape,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: _buildDetailItem(
                              theme,
                              Icons.calendar_today,
                              localizations.dateRangeLabel,
                              dateRange,
                              isLandscape,
                            ),
                          ),
                          _buildStatusChip(
                            event.status,
                            localizations,
                            theme,
                            isLandscape,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(
    ThemeData theme,
    IconData icon,
    String label,
    String value,
    bool isLandscape,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: isLandscape ? 16 : 18,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 1.2,
                  fontSize: isLandscape ? 9 : null,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.4,
                  fontSize: isLandscape ? 12 : 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(
    String status,
    AppLocalizations localizations,
    ThemeData theme,
    bool isLandscape,
  ) {
    return Container(
      padding: EdgeInsets.all(isLandscape ? 4 : 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: isLandscape ? 12 : 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            _getStatusDescription(status, localizations),
            style:
                (isLandscape
                        ? theme.textTheme.labelSmall?.copyWith(fontSize: 9)
                        : theme.textTheme.labelSmall)
                    ?.copyWith(
                      color: theme.appColors.secondaryText,
                      fontStyle: FontStyle.italic,
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(
    GroupNamjapEvent event,
    AppLocalizations localizations,
    ThemeData theme,
    String locale,
    bool isLandscape,
  ) {
    final isActionEnabled =
        (event.status == 'ongoing' || event.status == 'enrolling') && !kIsWeb;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          StreamBuilder<int>(
            stream: _participantsCountStream,
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    localizations.groupNamjapTotalParticipants,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                      fontWeight: FontWeight.bold,
                      fontSize: isLandscape ? 10 : null,
                    ),
                  ),
                  Text(
                    formatNumberLocalized(count, locale, pad: false),
                    style:
                        (isLandscape
                                ? theme.textTheme.titleMedium
                                : theme.textTheme.titleLarge)
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                  ),
                ],
              );
            },
          ),
          Consumer<GroupNamjapProvider>(
            builder: (context, groupProvider, _) {
              final isJoined = groupProvider.isJoined(event.id);
              final canJoin =
                  event.status == 'enrolling' || event.status == 'ongoing';
              final isEditable = isJoined && event.status == 'enrolling';
              final isJoinable = !isJoined && canJoin;
              final isActionEnabled = (isEditable || isJoinable) && !kIsWeb;

              return SizedBox(
                height: isLandscape ? 32 : 50,
                child: ElevatedButton(
                  onPressed: isActionEnabled
                      ? () async {
                          final result = await showDialog(
                            context: context,
                            builder: (context) => NamjapSignupDialog(
                              event: event,
                              isEdit: isJoined,
                              prefilledJoinCode: widget.prefilledJoinCode,
                            ),
                          );
                          if (result == true) {
                            _updateParticipantStream();
                          } else if (result is Map &&
                              result['deleted'] == true) {
                            _updateParticipantStream();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  localizations.deleteSignupSuccess,
                                ),
                              ),
                            );
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isActionEnabled
                        ? theme.colorScheme.primary
                        : theme.appColors.disabledBackground,
                    foregroundColor: isActionEnabled
                        ? theme.colorScheme.onPrimary
                        : theme.appColors.disabledText,
                    elevation: isActionEnabled ? 2 : 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: isLandscape ? 12 : 20,
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isJoined
                              ? (isEditable
                                    ? Icons.edit
                                    : Icons.check_circle_outline)
                              : Icons.person_add_outlined,
                          size: isLandscape ? 14 : 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isJoined
                              ? (isEditable
                                    ? localizations.editLabel
                                    : localizations.signedUpLabel)
                              : localizations.signUp,
                          style: TextStyle(
                            fontSize: isLandscape ? 12 : 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCardsRow(
    GroupNamjapEvent event,
    AppLocalizations localizations,
    ThemeData theme,
    String locale,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            theme,
            localizations.totalCountLabel,
            '${formatNumberLocalized(event.totalCount, locale, pad: false)} / ${formatNumberLocalized(event.targetCount, locale, pad: false)}',
            Icons.groups,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StreamBuilder<GroupNamjapParticipant?>(
            stream: _participantStream,
            builder: (context, snapshot) {
              final participant = snapshot.data;
              final myCount = participant?.totalCount ?? 0;
              return _buildStatCard(
                theme,
                localizations.myTotalLabel,
                formatNumberLocalized(myCount, locale, pad: false),
                Icons.person,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
  ) {
    return Card(
      elevation: theme.cardTheme.elevation,
      color: theme.cardTheme.color,
      shape: theme.cardTheme.shape,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 4),
                Text(
                  label.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 0.5,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusDescription(String status, AppLocalizations localizations) {
    switch (status) {
      case 'ongoing':
        return localizations.statusOngoing;
      case 'completed':
        return localizations.statusCompleted;
      case 'upcoming':
        return localizations.statusUpcoming;
      default:
        return status;
    }
  }
}

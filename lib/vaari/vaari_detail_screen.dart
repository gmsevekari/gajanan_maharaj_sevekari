import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/vaari_event.dart';
import 'package:gajanan_maharaj_sevekari/providers/vaari_service.dart';
import 'package:gajanan_maharaj_sevekari/providers/vaari_provider.dart';
import 'package:gajanan_maharaj_sevekari/utils/date_time_utils.dart';
import 'package:gajanan_maharaj_sevekari/utils/marathi_utils.dart';
import 'package:gajanan_maharaj_sevekari/utils/locale_extensions.dart';
import 'package:gajanan_maharaj_sevekari/utils/unique_id_service.dart';
import 'package:gajanan_maharaj_sevekari/widgets/themed_icon.dart';
import 'package:gajanan_maharaj_sevekari/vaari/widgets/add_steps_dialog.dart';
import 'package:gajanan_maharaj_sevekari/vaari/widgets/vaari_signup_dialog.dart';
import 'package:gajanan_maharaj_sevekari/vaari/widgets/vaari_participants_table.dart';
import 'package:provider/provider.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';

class VaariDetailScreen extends StatefulWidget {
  final String eventId;
  final String? prefilledJoinCode;

  const VaariDetailScreen({
    super.key,
    required this.eventId,
    this.prefilledJoinCode,
  });

  @override
  State<VaariDetailScreen> createState() => _VaariDetailScreenState();
}

class _VaariDetailScreenState extends State<VaariDetailScreen> {
  Stream<VaariEvent?>? _eventStream;
  Stream<int>? _participantsCountStream;

  @override
  void initState() {
    super.initState();
    final service = context.read<VaariService>();
    _eventStream = service.getEventStream(widget.eventId);
    _participantsCountStream = service.getParticipantsCountStream(
      widget.eventId,
    );
    _initSync();
  }

  Future<void> _initSync() async {
    final provider = context.read<VaariProvider>();
    await provider.loadLocalData();

    final deviceId = await UniqueIdService.getUniqueId();
    if (mounted) {
      await provider.syncParticipation(widget.eventId, deviceId);
    }
  }

  Future<void> _showAddStepsDialog(VaariEvent event) async {
    final provider = context.read<VaariProvider>();
    final memberName = provider.memberName;
    if (memberName == null) return;

    final deviceId = await UniqueIdService.getUniqueId();
    if (!mounted) return;

    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => AddStepsDialog(
        eventId: widget.eventId,
        deviceId: deviceId,
        memberName: memberName,
        distanceUnit: event.distanceUnitLabel,
      ),
    );

    if (submitted == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.stepsSubmittedSuccess),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;

    return StreamBuilder<VaariEvent?>(
      stream: _eventStream,
      builder: (context, snapshot) {
        final event = snapshot.data;
        final title = event == null
            ? localizations.vaariEventDetails
            : Localizations.localeOf(
                context,
              ).localizedContent(event.nameEn, event.nameMr);

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
              ? Center(child: Text(localizations.vaariEventNotFound))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopEventCard(event, localizations, theme, context),
                      const SizedBox(height: 12),
                      _buildActionRow(event, localizations, theme, locale),
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
                            Consumer<VaariProvider>(
                              builder: (context, vaariProvider, _) {
                                final isJoined = vaariProvider.isJoined(
                                  widget.eventId,
                                );
                                final isOngoing = event.status == 'ongoing';
                                if (!(isJoined && isOngoing)) {
                                  return const SizedBox.shrink();
                                }

                                return SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _showAddStepsDialog(event),
                                    icon: const Icon(Icons.directions_walk),
                                    label: Text(localizations.addStepsLabel),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          theme.colorScheme.primary,
                                      foregroundColor:
                                          theme.colorScheme.onPrimary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            VaariParticipantsTable(
                              eventId: widget.eventId,
                              distanceUnitLabel: event.distanceUnitLabel,
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
    VaariEvent event,
    AppLocalizations localizations,
    ThemeData theme,
    BuildContext context,
  ) {
    final description = Localizations.localeOf(
      context,
    ).localizedContent(event.descriptionEn, event.descriptionMr);
    final locale = Localizations.localeOf(context).languageCode;
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
              Container(width: 4, color: theme.colorScheme.primary),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailItem(
                        theme,
                        Icons.directions_walk,
                        localizations.descriptionLabel,
                        description,
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
                            ),
                          ),
                          _buildStatusChip(event.status, localizations, theme),
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
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
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
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
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
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            _getStatusDescription(status, localizations),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.appColors.secondaryText,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(
    VaariEvent event,
    AppLocalizations localizations,
    ThemeData theme,
    String locale,
  ) {
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
                    localizations.vaariTotalParticipants,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    formatNumberLocalized(count, locale, pad: false),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              );
            },
          ),
          Consumer<VaariProvider>(
            builder: (context, vaariProvider, _) {
              final isJoined = vaariProvider.isJoined(event.id);
              final canJoin =
                  event.status == 'enrolling' || event.status == 'ongoing';
              final isEditable = isJoined && event.status == 'enrolling';
              final isJoinable = !isJoined && canJoin;
              final isActionEnabled = (isEditable || isJoinable) && !kIsWeb;

              return SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: isActionEnabled
                      ? () async {
                          final result = await showDialog(
                            context: context,
                            builder: (context) => VaariSignupDialog(
                              event: event,
                              isEdit: isJoined,
                              prefilledJoinCode: widget.prefilledJoinCode,
                            ),
                          );
                          if (result is Map &&
                              result['deleted'] == true &&
                              context.mounted) {
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
                    padding: const EdgeInsets.symmetric(horizontal: 20),
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
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isJoined
                              ? (isEditable
                                    ? localizations.editLabel
                                    : localizations.signedUpLabel)
                              : localizations.signUp,
                          style: const TextStyle(
                            fontSize: 16,
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
    VaariEvent event,
    AppLocalizations localizations,
    ThemeData theme,
    String locale,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            theme,
            localizations.totalStepsLabel,
            formatNumberLocalized(event.totalSteps, locale, pad: false),
            Icons.groups,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            theme,
            '${localizations.totalDistanceLabel} (${event.distanceUnitLabel})',
            _formatDistance(event.totalDistance, context),
            Icons.social_distance,
          ),
        ),
      ],
    );
  }

  String _formatDistance(double distance, BuildContext context) {
    final formatted = distance.toStringAsFixed(1);
    final useMarathi = Localizations.localeOf(context).useMarathiContent;
    return useMarathi ? toMarathiNumerals(formatted) : formatted;
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

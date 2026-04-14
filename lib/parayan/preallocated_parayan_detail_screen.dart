import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/parayan_event.dart';
import 'package:gajanan_maharaj_sevekari/models/parayan_participant.dart';
import 'package:gajanan_maharaj_sevekari/providers/parayan_service.dart';
import 'package:gajanan_maharaj_sevekari/utils/unique_id_service.dart';
import 'package:gajanan_maharaj_sevekari/parayan/my_allocation_tab.dart';
import 'package:gajanan_maharaj_sevekari/parayan/widgets/claim_allocation_dialog.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/widgets/themed_icon.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:gajanan_maharaj_sevekari/parayan/parayan_type.dart';
import 'package:gajanan_maharaj_sevekari/utils/date_time_utils.dart';
import 'package:gajanan_maharaj_sevekari/parayan/utils/parayan_extensions.dart';
import 'package:gajanan_maharaj_sevekari/utils/marathi_utils.dart';

class PreallocatedParayanDetailScreen extends StatefulWidget {
  final ParayanEvent? event;
  final String? eventId;
  final String? deviceId; // For TDD injection
  final ParayanService? parayanService; // For TDD injection

  const PreallocatedParayanDetailScreen({
    super.key,
    this.event,
    this.eventId,
    this.deviceId,
    this.parayanService,
  }) : assert(event != null || eventId != null);

  @override
  State<PreallocatedParayanDetailScreen> createState() =>
      _PreallocatedParayanDetailScreenState();
}

class _PreallocatedParayanDetailScreenState
    extends State<PreallocatedParayanDetailScreen> {
  late final ParayanService _service;
  ParayanEvent? _event;
  String? _deviceId;
  bool _isLinked = false;

  @override
  void initState() {
    super.initState();
    _service = widget.parayanService ?? ParayanService();
    _event = widget.event;
    _deviceId = widget.deviceId;
    if (_deviceId == null) {
      _getDeviceId();
    }
    if (_event == null) {
      _service.getEventById(widget.eventId!).first.then((e) {
        if (mounted) setState(() => _event = e);
      });
    }
  }

  Future<void> _getDeviceId() async {
    final id = await UniqueIdService.getUniqueId();
    if (mounted) setState(() => _deviceId = id);
  }

  void _showClaimDialog() async {
    if (_deviceId == null || _event == null) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ClaimAllocationDialog(
        eventId: _event!.id,
        deviceId: _deviceId!,
        daysCount: _event!.type.daysCount,
        parayanService: _service,
      ),
    );

    if (result == true) {
      // Refresh state if needed, though StreamBuilder should handle it
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    if (_event == null || _deviceId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return StreamBuilder<List<ParayanMember>>(
      stream: _service.getParticipantsByDevice(_event!.id, _deviceId!),
      builder: (context, snapshot) {
        final participants = snapshot.data ?? [];
        _isLinked = participants.isNotEmpty;

        return Scaffold(
          appBar: AppBar(
            title: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                locale == 'mr' ? _event!.titleMr : _event!.titleEn,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimary,
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
                  (_) => false,
                ),
              ),
              IconButton(
                icon: const ThemedIcon(LogicalIcon.settings),
                onPressed: () => Navigator.pushNamed(context, Routes.settings),
              ),
            ],
          ),
          body: Column(
            children: [
              // Header Card
              Padding(
                padding: EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 4.0),
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
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Row 1: Date & Time
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_rounded,
                                      size: isLandscape ? 16 : 18,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _event!.getSmartDate(locale),
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          color: theme.colorScheme.onSurface,
                                          fontWeight: FontWeight.bold,
                                          fontSize: isLandscape ? 14 : 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Row 2: Parayan Type
                                Row(
                                  children: [
                                    Icon(
                                      Icons.auto_stories_rounded,
                                      size: isLandscape ? 16 : 18,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        (_event!.type == ParayanType.oneDay
                                                ? localizations.oneDayParayan
                                                : _event!.type == ParayanType.threeDay
                                                    ? localizations.threeDayParayan
                                                    : localizations.guruPushyaParayan)
                                            .replaceAll(' ', '\u00A0'),
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w600,
                                          fontSize: isLandscape ? 12 : 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                // Row 3: Description (if exists)
                                if (_event!.descriptionEn.isNotEmpty ||
                                    _event!.descriptionMr.isNotEmpty) ...[
                                  Divider(
                                    height: 12,
                                    color: theme.dividerColor.withOpacity(0.1),
                                  ),
                                  Text(
                                    locale == 'mr'
                                        ? _event!.descriptionMr
                                        : _event!.descriptionEn,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      height: 1.5,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                // Row 4: Status Chip
                                _buildInfoChip(
                                  context,
                                  Icons.info_outline_rounded,
                                  _event!.getDescriptiveStatus(
                                    localizations,
                                    locale,
                                    usePreallocatedWording: true,
                                  ),
                                  isLandscape: isLandscape,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Action Row
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: isLandscape ? 4 : 6,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: isLandscape ? 40 : 50,
                  child: ElevatedButton(
                    onPressed: _isLinked ? null : _showClaimDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isLinked
                          ? theme.appColors.disabledBackground
                          : theme.colorScheme.primary,
                      foregroundColor: _isLinked
                          ? theme.appColors.disabledText
                          : theme.colorScheme.onPrimary,
                      elevation: _isLinked ? 0 : 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isLinked
                                ? Icons.check_circle_outline
                                : Icons.person_search,
                            size: isLandscape ? 16 : 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isLinked
                                ? localizations.signedUpLabel
                                : localizations.findMyAllocationLabel,
                            style: TextStyle(
                              fontSize: isLandscape ? 14 : 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const Divider(height: 1),
              // Main Allocation View
              Expanded(
                child: _isLinked
                    ? MyAllocationTab(
                        event: _event!,
                        deviceId: _deviceId!,
                        parayanService: _service,
                      )
                    : _buildPlaceholder(context, localizations, theme),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoChip(
    BuildContext context,
    IconData icon,
    String label, {
    bool isLandscape = false,
  }) {
    final theme = Theme.of(context);
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
            icon,
            size: isLandscape ? 12 : 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style:
                  (isLandscape
                          ? theme.textTheme.labelSmall?.copyWith(fontSize: 9)
                          : theme.textTheme.labelSmall)
                      ?.copyWith(
                        color: theme.appColors.secondaryText,
                        fontStyle: FontStyle.italic,
                      ),
              maxLines: isLandscape ? 1 : null,
              overflow: isLandscape ? TextOverflow.ellipsis : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(
    BuildContext context,
    AppLocalizations localizations,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_ind_outlined,
              size: 64,
              color: theme.hintColor.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              localizations.findMyAllocationPlaceholder,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.hintColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

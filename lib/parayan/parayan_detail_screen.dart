import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/parayan_event.dart';
import 'package:gajanan_maharaj_sevekari/models/parayan_participant.dart';
import 'package:gajanan_maharaj_sevekari/providers/parayan_service.dart';
import 'package:gajanan_maharaj_sevekari/parayan/my_allocation_tab.dart';
import 'package:gajanan_maharaj_sevekari/utils/unique_id_service.dart';
import 'package:gajanan_maharaj_sevekari/parayan/adhyays_allocation_tab.dart';
import 'package:gajanan_maharaj_sevekari/parayan/parayan_signup_screen.dart';
import 'package:gajanan_maharaj_sevekari/parayan/parayan_type.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:gajanan_maharaj_sevekari/utils/notification_service_helper.dart';
import 'package:gajanan_maharaj_sevekari/utils/date_time_utils.dart';
import 'package:gajanan_maharaj_sevekari/parayan/utils/parayan_extensions.dart';
import 'package:gajanan_maharaj_sevekari/utils/marathi_utils.dart';
import 'dart:async';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/widgets/themed_icon.dart';

class ParayanDetailScreen extends StatefulWidget {
  final ParayanEvent? event;
  final String? eventId;
  final String? prefilledJoinCode;
  final ParayanService? parayanService;

  const ParayanDetailScreen({
    super.key,
    this.event,
    this.eventId,
    this.prefilledJoinCode,
    this.parayanService,
  }) : assert(event != null || eventId != null);

  @override
  State<ParayanDetailScreen> createState() => _ParayanDetailScreenState();
}

class _ParayanDetailScreenState extends State<ParayanDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late final ParayanService _parayanService;
  String? _deviceId;
  bool _isRegistered = false;
  late Stream<List<ParayanMember>> _participantsStream;
  ParayanEvent? _event;
  StreamSubscription<ParayanEvent>? _eventSubscription;
  StreamSubscription<List<ParayanMember>>? _registrationSubscription;

  @override
  void initState() {
    super.initState();
    _parayanService = widget.parayanService ?? ParayanService();
    _tabController = TabController(length: 1, vsync: this);
    _event = widget.event;
    final effectiveEventId = _event?.id ?? widget.eventId!;
    _participantsStream = _parayanService.getAllParticipants(effectiveEventId);
    _getDeviceId();

    if (_event == null) {
      _fetchEvent(effectiveEventId);
    } else {
      // Setup live listener even if we already have the widget.event
      _fetchEvent(effectiveEventId);
    }
  }

  void _fetchEvent(String id) {
    _eventSubscription?.cancel();
    _eventSubscription = _parayanService.getEventById(id).listen((
      updatedEvent,
    ) {
      if (mounted) {
        setState(() {
          _event = updatedEvent;
        });

        // Auto-unsubscribe if parayan is completed
        if (updatedEvent.status == 'completed') {
          NotificationServiceHelper.unsubscribeFromEventTopics(
            updatedEvent.id,
            updatedEvent.type.daysCount,
          );
        }
      }
    });
  }

  Future<void> _getDeviceId() async {
    final id = await UniqueIdService.getUniqueId();
    setState(() {
      _deviceId = id;
    });
    _checkRegistration(id);
  }

  void _checkRegistration(String deviceId) {
    final effectiveEventId = _event?.id ?? widget.eventId!;
    _registrationSubscription?.cancel();
    _registrationSubscription = _parayanService
        .getParticipantsByDevice(effectiveEventId, deviceId)
        .listen((list) {
          if (mounted) {
            final newIsRegistered = list.isNotEmpty;
            if (newIsRegistered != _isRegistered) {
              setState(() {
                _isRegistered = newIsRegistered;
                final oldController = _tabController;
                _tabController = TabController(
                  length: _isRegistered ? 2 : 1,
                  vsync: this,
                );
                // Dispose the old controller after the new one is assigned
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  oldController.dispose();
                });
              });
            }
          }
        });
  }

  Future<void> _attemptJoin(
    BuildContext context,
    AppLocalizations localizations,
  ) async {
    // If prefilled code matches or event surprisingly has no code (legacy safety)
    if (_event!.joinCode == null ||
        widget.prefilledJoinCode == _event!.joinCode) {
      _navigateAndHandleResult();
      return;
    }

    final codeController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(localizations.joinCodeTitle),
          content: TextField(
            controller: codeController,
            decoration: InputDecoration(hintText: localizations.joinCodeHint),
            textCapitalization: TextCapitalization.characters,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(localizations.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                if (codeController.text.trim().toUpperCase() ==
                    _event!.joinCode) {
                  Navigator.pop(context, true);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(localizations.invalidJoinCode)),
                  );
                }
              },
              child: Text(localizations.submitLabel),
            ),
          ],
        );
      },
    );

    if (result == true) {
      _navigateAndHandleResult();
    }
  }

  Future<void> _navigateAndHandleResult([ParayanHousehold? household]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ParayanSignupScreen(
          event: _event!,
          existingEnrollment: household,
          parayanService: _parayanService,
        ),
      ),
    );
    if (result != null && _deviceId != null && mounted) {
      if (result == true) {
        _checkRegistration(_deviceId!);
      } else if (result is Map && result['deleted'] == true) {
        _checkRegistration(_deviceId!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.signupDeletedSuccess),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _registrationSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            _event == null
                ? localizations.parayanTitle
                : (locale == 'mr' ? _event!.titleMr : _event!.titleEn),
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
              (route) => false,
            ),
          ),
          IconButton(
            icon: const ThemedIcon(LogicalIcon.settings),
            onPressed: () => Navigator.pushNamed(context, Routes.settings),
          ),
        ],
      ),
      body: _event == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header Section
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
                              padding: EdgeInsets.all(isLandscape ? 8.0 : 10.0),
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
                // Registration and Stats Row
                StreamBuilder<List<ParayanMember>>(
                  stream: _participantsStream,
                  builder: (context, snapshot) {
                    final count = snapshot.data?.length ?? 0;
                    final canJoin = _event!.status == 'enrolling';

                    final isEditable = _isRegistered && canJoin;
                    final isJoinable = !_isRegistered && canJoin;
                    final isActionEnabled =
                        (isEditable || isJoinable) && !kIsWeb;

                    return Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: isLandscape ? 4 : 6,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Participant Count
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                localizations.allAllocationsLabel,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.hintColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: isLandscape ? 10 : null,
                                ),
                              ),
                              Text(
                                formatNumberLocalized(
                                  count,
                                  locale,
                                  pad: false,
                                ),
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
                          ),
                          // Join / Edit Button
                          SizedBox(
                            height: isLandscape ? 32 : 50,
                            child: ElevatedButton(
                              onPressed: isActionEnabled
                                  ? () async {
                                      if (isEditable && _deviceId != null) {
                                        final household = await _parayanService
                                            .getHousehold(
                                              _event!.id,
                                              _deviceId!,
                                            );
                                        if (household != null && mounted) {
                                          _navigateAndHandleResult(household);
                                        }
                                      } else {
                                        _attemptJoin(context, localizations);
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
                                alignment: Alignment.center,
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isEditable
                                          ? Icons.edit
                                          : (_isRegistered
                                                ? Icons.check_circle_outline
                                                : Icons.person_add_outlined),
                                      size: isLandscape ? 14 : 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _isRegistered
                                          ? (canJoin
                                                ? localizations.editEnrollmentLabel
                                                : localizations.signedUpLabel)
                                          : localizations.joinParayanLabel,
                                      style: TextStyle(
                                        fontSize: isLandscape ? 12 : 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                // Tab Section
                Container(
                  color: theme.scaffoldBackgroundColor,
                  child: TabBar(
                    key: ValueKey('tab_bar_$_isRegistered'),
                    controller: _tabController,
                    labelColor: theme.colorScheme.primary,
                    unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                    indicatorColor: theme.colorScheme.primary,
                    indicatorWeight: 3,
                    tabs: [
                      Tab(text: localizations.adhyayAllocationTab),
                      if (_isRegistered)
                        Tab(text: localizations.myAllocationTab),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    key: ValueKey('tab_view_$_isRegistered'),
                    controller: _tabController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      AdhyaysAllocationTab(event: _event!),
                      if (_isRegistered)
                        _deviceId == null
                            ? const Center(child: CircularProgressIndicator())
                            : MyAllocationTab(
                                event: _event!,
                                deviceId: _deviceId!,
                                parayanService: _parayanService,
                              ),
                    ],
                  ),
                ),
              ],
            ),
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
}

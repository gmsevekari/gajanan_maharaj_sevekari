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
import 'package:intl/intl.dart';
import 'package:gajanan_maharaj_sevekari/utils/marathi_utils.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'dart:async';

class ParayanDetailScreen extends StatefulWidget {
  final ParayanEvent? event;
  final String? eventId;

  const ParayanDetailScreen({super.key, this.event, this.eventId})
    : assert(event != null || eventId != null);

  @override
  State<ParayanDetailScreen> createState() => _ParayanDetailScreenState();
}

class _ParayanDetailScreenState extends State<ParayanDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ParayanService _parayanService = ParayanService();
  String? _deviceId;
  bool _isRegistered = false;
  late Stream<List<ParayanMember>> _participantsStream;
  ParayanEvent? _event;
  StreamSubscription<ParayanEvent>? _eventSubscription;
  StreamSubscription<List<ParayanMember>>? _registrationSubscription;

  @override
  void initState() {
    super.initState();
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
          NotificationServiceHelper.unsubscribeFromEventTopics(updatedEvent.id);
        }
      }
    });
  }

  Future<void> _getDeviceId() async {
    final id = await UniqueIdService.getUniqueId();
    setState(() {
      _deviceId = id;
    });
    if (id != null) {
      _checkRegistration(id);
    }
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

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _registrationSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  String _formatNumber(BuildContext context, dynamic number) {
    if (number == null) return '';
    String numStr = number.toString();
    final isMarathi = Localizations.localeOf(context).languageCode == 'mr';
    return isMarathi ? toMarathiNumerals(numStr) : numStr;
  }

  String _formatDate(DateTime date, String locale) {
    final dateStr = locale == 'mr'
        ? DateFormat('d MMMM, yyyy', 'mr').format(date)
        : DateFormat('MMMM d, yyyy').format(date);
    return locale == 'mr' ? toMarathiNumerals(dateStr) : dateStr;
  }

  String _getSmartDate(String locale) {
    if (_event == null) return "";
    if (_event!.type == ParayanType.oneDay ||
        _event!.type == ParayanType.guruPushya) {
      return _formatDate(_event!.startDate, locale);
    } else {
      final startStr = locale == 'mr'
          ? DateFormat('d MMMM', 'mr').format(_event!.startDate)
          : DateFormat('MMMM d').format(_event!.startDate);
      final start = locale == 'mr' ? toMarathiNumerals(startStr) : startStr;
      final end = _formatDate(_event!.endDate, locale);
      return "$start - $end";
    }
  }

  String _getDescriptiveStatus(AppLocalizations localizations, String locale) {
    if (_event == null) return "";
    final date = _formatDate(_event!.startDate, locale);

    switch (_event!.status) {
      case 'upcoming':
        return _event!.type == ParayanType.oneDay ||
                _event!.type == ParayanType.guruPushya
            ? localizations.statusUpcomingOneDay(date)
            : localizations.statusUpcomingMultiDay(date);
      case 'enrolling':
        return localizations.statusEnrollingDesc(date);
      case 'allocated':
        return localizations.statusAllocatedDesc(date);
      case 'ongoing':
        return localizations.statusOngoing;
      case 'completed':
        return localizations.statusCompleted;
      default:
        return "";
    }
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
        title: Text(
          _event == null
              ? localizations.parayanTitle
              : (locale == 'mr' ? _event!.titleMr : _event!.titleEn),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.orange,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              Routes.home,
              (route) => false,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
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
                  padding: EdgeInsets.all(isLandscape ? 8.0 : 16.0),
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
                              padding: EdgeInsets.all(isLandscape ? 8.0 : 16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    localizations.parayanDetailsHeader,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          color: theme.colorScheme.secondary,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.2,
                                          fontSize: isLandscape ? 14 : null,
                                        ),
                                  ),
                                  SizedBox(height: isLandscape ? 4 : 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              localizations.dateLabel,
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color:
                                                        theme.brightness ==
                                                            Brightness.dark
                                                        ? Colors.grey[400]
                                                        : Colors.grey[700],
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: isLandscape
                                                        ? 10
                                                        : null,
                                                  ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _getSmartDate(locale),
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                    color: theme
                                                        .colorScheme
                                                        .onSurface,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: isLandscape
                                                        ? 14
                                                        : null,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        width: 1,
                                        height: isLandscape ? 20 : 30,
                                        color: Colors.grey[800],
                                        margin: EdgeInsets.symmetric(
                                          horizontal: isLandscape ? 8 : 16,
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              localizations.typeLabel,
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color:
                                                        theme.brightness ==
                                                            Brightness.dark
                                                        ? Colors.grey[400]
                                                        : Colors.grey[700],
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: isLandscape
                                                        ? 10
                                                        : null,
                                                  ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _event!.type == ParayanType.oneDay
                                                  ? localizations.oneDayParayan
                                                  : _event!.type ==
                                                        ParayanType.threeDay
                                                  ? localizations
                                                        .threeDayParayan
                                                  : localizations
                                                        .guruPushyaParayan,
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                    color: theme
                                                        .colorScheme
                                                        .onSurface,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: isLandscape
                                                        ? 14
                                                        : null,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (!isLandscape &&
                                      (_event!.descriptionEn.isNotEmpty ||
                                          _event!
                                              .descriptionMr
                                              .isNotEmpty)) ...[
                                    Divider(
                                      height: 24,
                                      color: theme.dividerColor,
                                    ),
                                    Text(
                                      locale == 'mr'
                                          ? _event!.descriptionMr
                                          : _event!.descriptionEn,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.8),
                                            height: 1.4,
                                          ),
                                    ),
                                  ],
                                  SizedBox(height: isLandscape ? 4 : 12),
                                  _buildInfoChip(
                                    context,
                                    Icons.info_outline,
                                    _getDescriptiveStatus(
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
                        vertical: isLandscape ? 4 : 12,
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
                                _formatNumber(context, count),
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
                            height: isLandscape ? 32 : 40,
                            child: ElevatedButton.icon(
                              onPressed: isActionEnabled
                                  ? () async {
                                      if (isEditable && _deviceId != null) {
                                        final household = await _parayanService
                                            .getHousehold(
                                              _event!.id,
                                              _deviceId!,
                                            );
                                        if (household != null && mounted) {
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ParayanSignupScreen(
                                                    event: _event!,
                                                    existingEnrollment:
                                                        household,
                                                  ),
                                            ),
                                          );
                                          if (result != null &&
                                              _deviceId != null) {
                                            if (result == true) {
                                              _checkRegistration(_deviceId!);
                                            } else if (result is Map &&
                                                result['deleted'] == true) {
                                              _checkRegistration(_deviceId!);
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    localizations
                                                        .signupDeletedSuccess,
                                                  ),
                                                ),
                                              );
                                            }
                                          }
                                        }
                                      } else {
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ParayanSignupScreen(
                                                  event: _event!,
                                                ),
                                          ),
                                        );
                                        if (result != null &&
                                            _deviceId != null) {
                                          if (result == true) {
                                            _checkRegistration(_deviceId!);
                                          } else if (result is Map &&
                                              result['deleted'] == true) {
                                            _checkRegistration(_deviceId!);
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  localizations
                                                      .signupDeletedSuccess,
                                                ),
                                              ),
                                            );
                                          }
                                        }
                                      }
                                    }
                                  : null,
                              icon: Icon(
                                isEditable
                                    ? Icons.edit
                                    : (_isRegistered
                                          ? Icons.check_circle_outline
                                          : Icons.person_add_outlined),
                                size: isLandscape ? 14 : 18,
                              ),
                              label: Text(
                                _isRegistered
                                    ? (canJoin
                                          ? localizations.editEnrollmentLabel
                                          : localizations.signedUpLabel)
                                    : localizations.joinParayanLabel,
                                style: TextStyle(
                                  fontSize: isLandscape ? 12 : null,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isActionEnabled
                                    ? theme.colorScheme.primary
                                    : Colors.grey.withValues(alpha: 0.1),
                                foregroundColor: isActionEnabled
                                    ? Colors.white
                                    : Colors.grey,
                                elevation: isActionEnabled ? 2 : 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: isLandscape ? 12 : 20,
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
                    unselectedLabelColor: Colors.grey,
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
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.8,
                        ),
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

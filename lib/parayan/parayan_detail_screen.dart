import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/parayan_event.dart';
import 'package:gajanan_maharaj_sevekari/models/parayan_participant.dart';
import 'package:gajanan_maharaj_sevekari/providers/parayan_service.dart';
import 'package:gajanan_maharaj_sevekari/parayan/my_allocation_tab.dart';
import 'package:gajanan_maharaj_sevekari/parayan/adhyays_allocation_tab.dart';
import 'package:gajanan_maharaj_sevekari/parayan/parayan_signup_screen.dart';
import 'package:gajanan_maharaj_sevekari/parayan/parayan_type.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:intl/intl.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _event = widget.event;
    final effectiveEventId = _event?.id ?? widget.eventId!;
    _participantsStream = _parayanService.getAllParticipants(effectiveEventId);
    _getDeviceId();

    if (_event == null) {
      _fetchEvent(widget.eventId!);
    }
  }

  void _fetchEvent(String id) {
    _parayanService.getEventById(id).first.then((event) {
      if (mounted) {
        setState(() {
          _event = event;
        });
      }
    });
  }

  Future<void> _getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    String? id;
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      id = androidInfo.id;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      id = iosInfo.identifierForVendor;
    }
    setState(() {
      _deviceId = id;
    });
    if (id != null) {
      _checkRegistration(id);
    }
  }

  void _checkRegistration(String deviceId) {
    final effectiveEventId = _event?.id ?? widget.eventId!;
    _parayanService
        .getParticipantsByDevice(effectiveEventId, deviceId)
        .first
        .then((list) {
      if (mounted) {
        final newIsRegistered = list.isNotEmpty;
        if (newIsRegistered != _isRegistered) {
          setState(() {
            _isRegistered = newIsRegistered;
            final oldController = _tabController;
            _tabController =
                TabController(length: _isRegistered ? 2 : 1, vsync: this);
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
    _tabController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date, String locale) {
    return locale == 'mr'
        ? DateFormat('d MMMM, yyyy', 'mr').format(date)
        : DateFormat('MMMM d, yyyy').format(date);
  }

  String _getSmartDate(String locale) {
    if (_event == null) return "";
    if (_event!.type == ParayanType.oneDay ||
        _event!.type == ParayanType.guruPushya) {
      return _formatDate(_event!.startDate, locale);
    } else {
      final start = locale == 'mr'
          ? DateFormat('d MMMM', 'mr').format(_event!.startDate)
          : DateFormat('MMMM d').format(_event!.startDate);
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
          locale == 'mr' ? _event!.titleMr : _event!.titleEn,
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
                          Container(
                            width: 4,
                            color: theme.colorScheme.primary,
                          ),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.all(isLandscape ? 8.0 : 16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    localizations.parayanDetailsHeader,
                                    style: theme.textTheme.titleMedium?.copyWith(
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
                                                color: theme.brightness ==
                                                        Brightness.dark
                                                    ? Colors.grey[400]
                                                    : Colors.grey[700],
                                                fontWeight: FontWeight.bold,
                                                fontSize:
                                                    isLandscape ? 10 : null,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _getSmartDate(locale),
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                color: theme
                                                    .colorScheme.onSurface,
                                                fontWeight: FontWeight.bold,
                                                fontSize:
                                                    isLandscape ? 14 : null,
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
                                                color: theme.brightness ==
                                                        Brightness.dark
                                                    ? Colors.grey[400]
                                                    : Colors.grey[700],
                                                fontWeight: FontWeight.bold,
                                                fontSize:
                                                    isLandscape ? 10 : null,
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
                                                    .colorScheme.onSurface,
                                                fontWeight: FontWeight.bold,
                                                fontSize:
                                                    isLandscape ? 14 : null,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (!isLandscape &&
                                      (_event!.descriptionEn.isNotEmpty ||
                                          _event!.descriptionMr.isNotEmpty)) ...[
                                    Divider(
                                        height: 24, color: theme.dividerColor),
                                    Text(
                                      locale == 'mr'
                                          ? _event!.descriptionMr
                                          : _event!.descriptionEn,
                                      style: theme.textTheme.bodySmall?.copyWith(
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
                                        localizations, locale),
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
                    final canJoin = _event!.status == 'enrolling' ||
                        _event!.status == 'allocated';

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
                                count.toString(),
                                style: (isLandscape
                                        ? theme.textTheme.titleMedium
                                        : theme.textTheme.titleLarge)
                                    ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          // Join Button
                          SizedBox(
                            height: isLandscape ? 32 : 40,
                            child: ElevatedButton.icon(
                              onPressed: canJoin && !_isRegistered
                                  ? () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ParayanSignupScreen(
                                                  event: _event!),
                                        ),
                                      );
                                      if (result == true && _deviceId != null) {
                                        _checkRegistration(_deviceId!);
                                      }
                                    }
                                  : null,
                              icon: Icon(
                                _isRegistered
                                    ? Icons.check_circle_outline
                                    : Icons.person_add_outlined,
                                size: isLandscape ? 14 : 18,
                              ),
                              label: Text(
                                _isRegistered
                                    ? "Signed Up"
                                    : localizations.joinParayanLabel,
                                style: TextStyle(
                                    fontSize: isLandscape ? 12 : null),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: canJoin && !_isRegistered
                                    ? theme.colorScheme.primary
                                    : Colors.grey.withValues(alpha: 0.1),
                                foregroundColor: canJoin && !_isRegistered
                                    ? Colors.white
                                    : Colors.grey,
                                elevation: canJoin && !_isRegistered ? 2 : 0,
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

  Widget _buildInfoChip(BuildContext context, IconData icon, String label,
      {bool isLandscape = false}) {
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
          Icon(icon, size: isLandscape ? 12 : 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: (isLandscape
                      ? theme.textTheme.labelSmall?.copyWith(fontSize: 9)
                      : theme.textTheme.labelSmall)
                  ?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
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

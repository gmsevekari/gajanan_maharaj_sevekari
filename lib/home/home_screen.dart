import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/event_calendar/event_calendar_screen.dart';
import 'package:gajanan_maharaj_sevekari/models/app_config.dart';
import 'package:gajanan_maharaj_sevekari/providers/app_config_provider.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gajanan_maharaj_sevekari/shared/global_search_delegate.dart';
import 'package:gajanan_maharaj_sevekari/models/parayan_event.dart';
import 'package:gajanan_maharaj_sevekari/parayan/parayan_type.dart';
import 'package:gajanan_maharaj_sevekari/parayan/parayan_detail_screen.dart';

import '../deity/deity_dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  Future<Map<String, dynamic>>? _upcomingEventsFuture;
  String? _lastReadTimestamp;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _upcomingEventsFuture = _fetchUpcomingEvents();
    _loadUnreadStatus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        //NotificationManager.requestPermissions(context);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadUnreadStatus();
    }
  }

  Future<void> _loadUnreadStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lastReadTimestamp = prefs.getString('last_read_notification_timestamp');
    });
  }

  Future<Map<String, dynamic>> _fetchUpcomingEvents() async {
    final now = DateTime.now();
    final nowTimestamp = Timestamp.fromDate(now);

    // 1. Fetch from 'events' collection
    final eventsSnapshot = await FirebaseFirestore.instance
        .collection('events')
        .where('start_time', isGreaterThanOrEqualTo: nowTimestamp)
        .orderBy('start_time')
        .limit(20)
        .get();

    DocumentSnapshot? weeklyPooja;
    DocumentSnapshot? specialEvent;

    for (var doc in eventsSnapshot.docs) {
      final eventData = doc.data();
      final eventType = eventData['event_type'] as String?;

      if (weeklyPooja == null &&
          (eventType == 'weekly_pooja' ||
              eventType == 'weekly pooja' ||
              eventType == 'weeklyPooja')) {
        weeklyPooja = doc;
      }
      if (specialEvent == null &&
          (eventType == 'special_event' ||
              eventType == 'special event' ||
              eventType == 'specialEvent')) {
        specialEvent = doc;
      }
      if (weeklyPooja != null && specialEvent != null) break;
    }

    // 2. Fetch from 'parayan_events' collection
    // Simplified query: Fetch recent/upcoming ones and filter in-memory
    // to avoid needing a composite index for 'status' + 'startDate'.
    final parayanSnapshot = await FirebaseFirestore.instance
        .collection('parayan_events')
        .orderBy('startDate')
        .limit(10)
        .get();

    ParayanEvent? upcomingParayan;
    for (var doc in parayanSnapshot.docs) {
      final event = ParayanEvent.fromFirestore(doc);
      // We want the first event that hasn't ended yet
      if (event.endDate.isAfter(now)) {
        upcomingParayan = event;
        break;
      }
    }

    return {
      'weeklyPooja': weeklyPooja,
      'specialEvent': specialEvent,
      'parayan': upcomingParayan,
    };
  }

  void _launchAppStore() async {
    const appleId = '6759313202';
    const androidPackageName = 'com.gajanan.maharaj.sevekari';

    final url = Theme.of(context).platform == TargetPlatform.iOS
        ? 'https://apps.apple.com/app/id$appleId'
        : 'https://play.google.com/store/apps/details?id=$androidPackageName';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }


  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final appConfigProvider = Provider.of<AppConfigProvider>(context);

    if (localizations == null) return const SizedBox.shrink();

    final List<Widget> cards = [];

    if (appConfigProvider.appConfig != null) {
      for (var deity in appConfigProvider.appConfig!.deities) {
        cards.add(_buildDeityGridItem(context, deity));
      }
    }

    cards.add(
      _buildIconGridItem(
        context: context,
        title: localizations.otherTitle, // "Other" card
        icon: Icons.temple_hindu,
        onTap: () => Navigator.pushNamed(context, Routes.other),
      ),
    );
    cards.add(
      _buildIconGridItem(
        context: context,
        title: localizations.naamjapTitle,
        imagePath: 'resources/images/icon/Rudraksha_Mala.png',
        imageSize: 64.0,
        onTap: () => Navigator.pushNamed(context, Routes.naamjap),
      ),
    );
    cards.add(
      _buildIconGridItem(
        context: context,
        title: localizations.parayanTitle,
        icon: Icons.menu_book,
        onTap: () => Navigator.pushNamed(context, Routes.parayanList),
      ),
    );
    cards.add(
      _buildIconGridItem(
        context: context,
        title: localizations.calendarTitle,
        icon: Icons.calendar_month_outlined,
        onTap: () => Navigator.pushNamed(context, Routes.calendar),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('resources/images/logo/App_Logo.png'),
        ),
        title: Text(localizations.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: GlobalSearchDelegate(
                  hintText: localizations.searchHint,
                ),
              );
            },
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .orderBy('timestamp', descending: true)
                .limit(1)
                .snapshots(),
            builder: (context, snapshot) {
              bool hasUnread = false;
              if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                final latestDoc =
                    snapshot.data!.docs.first.data() as Map<String, dynamic>;
                final latestTimestampStr = latestDoc['timestamp'] as String?;

                if (latestTimestampStr != null) {
                  if (_lastReadTimestamp == null) {
                    hasUnread = true;
                  } else {
                    try {
                      final latestTime = DateTime.parse(latestTimestampStr);
                      final lastReadTime = DateTime.parse(_lastReadTimestamp!);
                      if (latestTime.isAfter(lastReadTime)) {
                        hasUnread = true;
                      }
                    } catch (e) {
                      // ignore parse errors
                    }
                  }
                }
              }

              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () async {
                      await Navigator.pushNamed(
                        context,
                        Routes.userNotifications,
                      );
                      _loadUnreadStatus(); // Refresh when returning
                    },
                  ),
                  if (hasUnread)
                    Positioned(
                      right: 12,
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, Routes.settings),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildUpcomingEventCard(context, localizations),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      alignment: WrapAlignment.center,
                      children: cards,
                    ),
                  ),
                  if (kIsWeb) _buildDownloadBanner(context, localizations),
                  const SizedBox(
                    height: 100,
                  ), // Extra space to prevent bottom cards from cutting off on zoomed displays
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.spa, color: Colors.orange[300], size: 20),
                  const SizedBox(width: 12),
                  Text(
                    localizations.gajananChant,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[600],
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.spa, color: Colors.orange[300], size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadBanner(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: theme.cardTheme.shadowColor!,
            offset: const Offset(0, 4),
            blurRadius: 0,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: theme.cardTheme.color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
          side: BorderSide(color: Color(0xFFFF9800), width: 1),
        ),
        child: InkWell(
          onTap: _launchAppStore,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.phone_android,
                    color: theme.colorScheme.onPrimary,
                    size: 24.0,
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations.downloadAppTitle,
                        style: TextStyle(
                          color: Colors.orange[600],
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        localizations.downloadAppSubtitle,
                        style: TextStyle(
                          color: Colors.orange[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _launchAppStore,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    localizations.downloadAppButton,
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingEventCard(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    final theme = Theme.of(context);

    return FutureBuilder<Map<String, dynamic>>(
      future: _upcomingEventsFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint("Error fetching upcoming events: ${snapshot.error}");
          return Container(
            margin: const EdgeInsets.all(8.0),
            padding: const EdgeInsets.all(16.0),
            child: const Center(
              child: Icon(Icons.error_outline, color: Colors.red),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(child: Center(child: CircularProgressIndicator()));
        }

        final data = snapshot.data;
        if (!snapshot.hasData ||
            data == null ||
            (data['weeklyPooja'] == null &&
                data['specialEvent'] == null &&
                data['parayan'] == null)) {
          return Container(
            margin: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: [
                BoxShadow(
                  color: theme.cardTheme.shadowColor ?? Colors.black12,
                  offset: const Offset(0, 4),
                  blurRadius: 0,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Card(
              elevation: 0,
              margin: EdgeInsets.zero,
              color: theme.cardTheme.color,
              shape: theme.cardTheme.shape,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      localizations.eventOnDate,
                      style: TextStyle(
                        color: Colors.orange[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final weeklyPoojaDoc = data['weeklyPooja'] as DocumentSnapshot?;
        final specialEventDoc = data['specialEvent'] as DocumentSnapshot?;
        final parayanEvent = data['parayan'] as ParayanEvent?;

        List<Widget> children = [
          Text(
            localizations.upcomingEvent,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.orange[600],
            ),
          ),
          const SizedBox(height: 4.0),
          Divider(color: Colors.orange.withValues(alpha: 0.2), height: 8.0),
        ];

        if (weeklyPoojaDoc != null) {
          children.add(
            _buildEventRow(
              context,
              weeklyPoojaDoc,
              Icons.event_repeat,
              Colors.orange,
              localizations.weeklyPooja,
              theme,
            ),
          );
        }

        if (weeklyPoojaDoc != null && specialEventDoc != null) {
          children.add(
            Divider(color: Colors.orange.withValues(alpha: 0.2), height: 8.0),
          );
        }

        if (specialEventDoc != null) {
          children.add(
            _buildEventRow(
              context,
              specialEventDoc,
              Icons.celebration,
              Colors.orange,
              localizations.specialEvents,
              theme,
            ),
          );
        }

        if (parayanEvent != null) {
          if (weeklyPoojaDoc != null || specialEventDoc != null) {
            children.add(
              Divider(color: Colors.orange.withValues(alpha: 0.2), height: 8.0),
            );
          }
          children.add(
            _buildParayanRow(context, parayanEvent, theme, localizations),
          );
        }

        return Container(
          margin: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: [
              BoxShadow(
                color: theme.cardTheme.shadowColor!,
                offset: const Offset(0, 4),
                blurRadius: 0,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            color: theme.cardTheme.color,
            shape: theme.cardTheme.shape,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 8.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEventRow(
    BuildContext context,
    DocumentSnapshot doc,
    IconData icon,
    Color iconColor,
    String eventTypeLabel,
    ThemeData theme,
  ) {
    final eventData = doc.data() as Map<String, dynamic>;
    final event = Event.fromFirestore(doc);
    final locale = Localizations.localeOf(context).languageCode;
    final eventTitle = locale == 'mr' ? event.title_mr : event.title_en;
    final eventDate = (eventData['start_time'] as Timestamp).toDate();
    final eventDateString = DateFormat.yMMMMEEEEd(locale).format(eventDate);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventCalendarScreen(initialDate: eventDate),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eventTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[600],
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    eventDateString,
                    style: TextStyle(color: Colors.orange[600], fontSize: 13.0),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8.0),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 4.0,
              ),
              decoration: BoxDecoration(
                color: iconColor,
                borderRadius: BorderRadius.circular(6.0),
              ),
              child: Text(
                eventTypeLabel.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParayanRow(
    BuildContext context,
    ParayanEvent event,
    ThemeData theme,
    AppLocalizations localizations,
  ) {
    final locale = Localizations.localeOf(context).languageCode;
    final title = locale == 'mr' ? event.titleMr : event.titleEn;
    final isSingleDay =
        event.type == ParayanType.oneDay ||
        event.type == ParayanType.guruPushya;
    final dateRange = isSingleDay
        ? (locale == 'mr'
              ? DateFormat('d MMMM, yyyy', 'mr').format(event.startDate)
              : DateFormat('MMM d, yyyy').format(event.startDate))
        : (locale == 'mr'
              ? "${DateFormat('d MMMM', 'mr').format(event.startDate)} - ${DateFormat('d MMMM, yyyy', 'mr').format(event.endDate)}"
              : "${DateFormat('MMM d').format(event.startDate)} - ${DateFormat('MMM d, yyyy').format(event.endDate)}");

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ParayanDetailScreen(event: event),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.menu_book, color: Colors.orange),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[600],
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    dateRange,
                    style: TextStyle(color: Colors.orange[600], fontSize: 13.0),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8.0),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 4.0,
              ),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(6.0),
              ),
              child: Text(
                localizations.parayanTitle.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeityGridItem(BuildContext context, DeityConfig deity) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final name = locale == 'mr' ? deity.nameMr : deity.nameEn;

    return SizedBox(
      width: (MediaQuery.of(context).size.width - 32) / 3,
      child: AspectRatio(
        aspectRatio: 1.0, // Make cards square
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: [
              BoxShadow(
                color: theme.cardTheme.shadowColor!,
                offset: const Offset(0, 4),
                blurRadius: 0,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Card(
            clipBehavior: Clip.antiAlias,
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: theme.cardTheme.shape,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DeityDashboardScreen(deity: deity),
                  ),
                );
              },
              child: Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset(
                        deity.imagePath,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.error,
                          color: Colors.red.shade300,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    color: theme.cardTheme.color,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 4,
                    ),
                    child: Center(
                      child: Text(
                        name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.orange[600],
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconGridItem({
    required BuildContext context,
    required String title,
    IconData? icon,
    String? imagePath,
    double? imageSize,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final size = imageSize ?? 48.0;

    return SizedBox(
      width: (MediaQuery.of(context).size.width - 32) / 3,
      child: AspectRatio(
        aspectRatio: 1.0, // Make cards square
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: [
              BoxShadow(
                color: theme.cardTheme.shadowColor!,
                offset: const Offset(0, 4),
                blurRadius: 0,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            color: theme.cardTheme.color,
            shape: theme.cardTheme.shape,
            child: InkWell(
              onTap: onTap,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (imagePath != null)
                    Image.asset(
                      imagePath,
                      height: size,
                      width: size,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.error_outline,
                        size: size,
                        color: theme.iconTheme.color,
                      ),
                    )
                  else if (icon != null)
                    Icon(icon, size: size, color: theme.iconTheme.color),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.orange[600],
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
import 'package:gajanan_maharaj_sevekari/notifications/notification_manager.dart';

import '../deity/deity_dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<Map<String, DocumentSnapshot?>>? _upcomingEventsFuture;

  @override
  void initState() {
    super.initState();
    _upcomingEventsFuture = _fetchUpcomingEvents();
  }

  Future<Map<String, DocumentSnapshot?>> _fetchUpcomingEvents() async {
    final now = Timestamp.now();
    final snapshot = await FirebaseFirestore.instance
        .collection('events')
        .where('start_time', isGreaterThanOrEqualTo: now)
        .orderBy('start_time')
        .limit(20)
        .get();

    DocumentSnapshot? weeklyPooja;
    DocumentSnapshot? specialEvent;

    for (var doc in snapshot.docs) {
      final eventData = doc.data();
      final eventType = eventData['event_type'] as String?;

      if (weeklyPooja == null && (eventType == 'weekly_pooja' || eventType == 'weekly pooja' || eventType == 'weeklyPooja')) {
        weeklyPooja = doc;
      }
      if (specialEvent == null && (eventType == 'special_event' || eventType == 'special event' || eventType == 'specialEvent')) {
        specialEvent = doc;
      }

      if (weeklyPooja != null && specialEvent != null) {
        break;
      }
    }

    return {
      'weeklyPooja': weeklyPooja,
      'specialEvent': specialEvent,
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
    final localizations = AppLocalizations.of(context)!;
    final appConfigProvider = Provider.of<AppConfigProvider>(context);

    final List<Widget> cards = [];

    if (appConfigProvider.appConfig != null) {
      for (var deity in appConfigProvider.appConfig!.deities) {
        cards.add(_buildDeityGridItem(context, deity));
      }
    }

    cards.add(_buildIconGridItem(context, localizations.calendarTitle, Icons.calendar_month_outlined, () => Navigator.pushNamed(context, Routes.calendar)));
    cards.add(_buildIconGridItem(context, localizations.favoritesTitle, Icons.favorite_border, () => Navigator.pushNamed(context, Routes.favorites)));

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('resources/images/logo/App_Logo.png'),
        ),
        title: Text(localizations.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, Routes.settings),
          ),
        ],
      ),
      body: SingleChildScrollView(
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
            const SizedBox(height: 100), // Extra space to prevent bottom cards from cutting off on zoomed displays
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadBanner(BuildContext context, AppLocalizations localizations) {
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
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(Icons.phone_android, color: theme.colorScheme.onPrimary, size: 24.0),
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
                            fontSize: 16
                        )
                      ),
                      Text(
                        localizations.downloadAppSubtitle,
                        style: TextStyle(
                            color: Colors.orange[600],
                            fontSize: 12
                        )
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
                  child: Text(localizations.downloadAppButton, style: TextStyle(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold)),
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

    return FutureBuilder<Map<String, DocumentSnapshot?>>(
      future: _upcomingEventsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(child: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData || (snapshot.data!['weeklyPooja'] == null && snapshot.data!['specialEvent'] == null)) {
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
              ));
        }

        final weeklyPoojaDoc = snapshot.data!['weeklyPooja'];
        final specialEventDoc = snapshot.data!['specialEvent'];

        Widget buildEventRow(DocumentSnapshot doc, IconData icon, Color iconColor, String eventTypeLabel) {
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
              padding: const EdgeInsets.symmetric(vertical: 8.0),
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                          decoration: BoxDecoration(
                            color: iconColor,
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          child: Text(
                            eventTypeLabel,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          eventTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[600],
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          eventDateString,
                          style: TextStyle(color: Colors.orange[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        List<Widget> children = [
          Text(
            localizations.upcomingEvent,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.orange[600],
            ),
          ),
          const SizedBox(height: 12.0),
        ];

        if (weeklyPoojaDoc != null) {
          children.add(buildEventRow(weeklyPoojaDoc, Icons.event_repeat, Colors.orange, localizations.weeklyPooja.toUpperCase()));
        }

        if (weeklyPoojaDoc != null && specialEventDoc != null) {
          children.add(Divider(color: Colors.orange.withValues(alpha: 0.2), height: 16.0));
        }

        if (specialEventDoc != null) {
          children.add(buildEventRow(specialEventDoc, Icons.celebration, Colors.orange, localizations.specialEvents.toUpperCase()));
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
              padding: const EdgeInsets.all(16.0),
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
  
  Widget _buildDeityGridItem(BuildContext context, DeityConfig deity) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final name = locale == 'mr' ? deity.nameMr : deity.nameEn;

    return SizedBox(
      width: (MediaQuery.of(context).size.width - 24) / 2,
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
                  MaterialPageRoute(builder: (context) => DeityDashboardScreen(deity: deity)),
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
                        errorBuilder: (context, error, stackTrace) => Icon(Icons.error, color: Colors.red.shade300, size: 60),
                      ),
                    ),
                  ),
                  Container(
                    color: theme.cardTheme.color,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                    child: Center(
                      child: Text(
                        name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.orange[600],
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
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

  Widget _buildIconGridItem(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    final theme = Theme.of(context);

    return SizedBox(
      width: (MediaQuery.of(context).size.width - 24) / 2,
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
                  Icon(icon, size: 80.0, color: theme.iconTheme.color),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.orange[600],
                      fontWeight: FontWeight.bold,
                      fontSize: 16
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

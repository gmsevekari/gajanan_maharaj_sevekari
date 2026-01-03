import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/event_calendar/event_calendar_screen.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<DocumentSnapshot?>? _upcomingEventFuture;

  @override
  void initState() {
    super.initState();
    _upcomingEventFuture = _fetchUpcomingEvent();
  }

  Future<DocumentSnapshot?> _fetchUpcomingEvent() async {
    final now = Timestamp.now();
    final snapshot = await FirebaseFirestore.instance
        .collection('events')
        .where('start_time', isGreaterThanOrEqualTo: now)
        .orderBy('start_time')
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first;
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    final List<Map<String, dynamic>> modules = [
      {'title': localizations.nityopasanaTitle, 'icon': 'resources/images/icon/Nitya_Smaran.png', 'route': Routes.nityopasana},
      {'title': localizations.calendarTitle, 'icon': Icons.calendar_month_outlined, 'route': Routes.calendar},
      {'title': localizations.donationsTitle, 'icon': Icons.volunteer_activism_outlined, 'route': Routes.donations},
      {'title': localizations.signupsTitle, 'icon': Icons.assignment_ind_outlined, 'route': Routes.signups},
      {'title': localizations.favoritesTitle, 'icon': Icons.favorite_border, 'route': Routes.favorites},
      {'title': localizations.aboutMaharajTitle, 'icon': Icons.info_outline, 'route': Routes.aboutMaharaj},
      {'title': localizations.socialMediaTitle, 'icon': Icons.connect_without_contact, 'route': Routes.socialMedia},
    ];

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('resources/images/logo/App_Logo.png'),
        ),
        title: Text(
          localizations.appName,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
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
            _buildGridView(context, modules),
          ],
        ),
      ),
    );
  }

  Widget _buildGridView(
    BuildContext context,
    List<Map<String, dynamic>> modules,
  ) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Wrap(
        spacing: 8.0, // Horizontal space between cards
        runSpacing: 8.0, // Vertical space between rows
        alignment: WrapAlignment.center,
        children: modules.map((module) {
          return SizedBox(
            width:
                (MediaQuery.of(context).size.width - 24) /
                2, // 24 = padding * 2 + spacing
            child: _buildGridItem(
              context,
              module['title'],
              module['icon'],
              module['route'],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUpcomingEventCard(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    return FutureBuilder<DocumentSnapshot?>(
      future: _upcomingEventFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(child: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                localizations.eventOnDate,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final eventData = snapshot.data!.data() as Map<String, dynamic>;
        final event = Event.fromFirestore(snapshot.data!);
        final locale = Localizations.localeOf(context).languageCode;
        final eventTitle = locale == 'mr' ? event.title_mr : event.title_en;
        final eventDate = (eventData['start_time'] as Timestamp).toDate();
        final eventDateString = DateFormat.yMMMMEEEEd(locale).format(eventDate);

        return Container(
          margin: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: [
              BoxShadow(
                color: Colors.orange, // Color of the shadow
                offset: const Offset(0, 4), // Shift shadow downwards
                blurRadius: 0, // Sharp edge for a "hard" shadow look
                spreadRadius: 0,
              ),
            ],
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      EventCalendarScreen(initialDate: eventDate),
                ),
              );
            },
            child: Card(
              elevation: 0,
              margin: EdgeInsets.zero,
              color: Colors.orange[50],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
                side: BorderSide(color: Colors.orange.withAlpha(128), width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      localizations.upcomingEvent,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[600],
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      eventTitle,
                      style: TextStyle(
                        color: Colors.orange[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      eventDateString,
                      style: TextStyle(color: Colors.orange[600]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGridItem(
    BuildContext context,
    String title,
    dynamic icon,
    String route,
  ) {
    return AspectRatio(
      aspectRatio: 1.4,
      child: Container(
        // This Container provides the distinct bottom shadow
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.orange, // Color of the shadow
              offset: const Offset(0, 4), // Shift shadow downwards
              blurRadius: 0, // Sharp edge for a "hard" shadow look
              spreadRadius: 0,
            ),
          ],
        ),
        child: Card(
          elevation: 0, // Disable default card elevation
          margin: EdgeInsets.zero, // Remove default margin
          color: Colors.orange[50],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
            side: BorderSide(color: Colors.orange.withAlpha(128), width: 1),
          ),
          child: InkWell(
            onTap: () => Navigator.pushNamed(context, route),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon is IconData)
                  Icon(icon, size: 40.0, color: Colors.orange[400])
                else if (icon is String)
                  Image.asset(icon, height: 40.0, width: 40.0),
                const SizedBox(height: 8.0),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.orange[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

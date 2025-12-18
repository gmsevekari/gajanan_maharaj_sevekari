import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/event_calendar/event_calendar_screen.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/utils/routes.dart';
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
      {'title': localizations.granthTitle, 'icon': Icons.book, 'route': Routes.granth},
      {'title': localizations.stotraTitle, 'icon': Icons.queue_music, 'route': Routes.stotra},
      {'title': localizations.bhajanTitle, 'icon': Icons.music_note, 'route': Routes.bhajan},
      {'title': localizations.aartiTitle, 'icon': Icons.audiotrack, 'route': Routes.aarti},
      {'title': localizations.namavaliTitle, 'icon': Icons.format_list_numbered, 'route': Routes.namavali},
      {'title': localizations.calendarTitle, 'icon': Icons.event, 'route': Routes.calendar},
      {'title': localizations.galleryTitle, 'icon': Icons.photo_album, 'route': Routes.gallery},
      {'title': localizations.donationsTitle, 'icon': Icons.volunteer_activism, 'route': Routes.donations},
      {'title': localizations.sankalpTitle, 'icon': Icons.calendar_today, 'route': Routes.sankalp},
      {'title': localizations.aboutMaharajTitle, 'icon': Icons.info, 'route': Routes.aboutMaharaj},
      {'title': localizations.parayanTitle, 'icon': Icons.group_work, 'route': Routes.parayan},
    ];

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('resources/images/logo/App_Logo.png'),
        ),
        title: Text(localizations.appName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, Routes.settings),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildUpcomingEventCard(context, localizations),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
              ),
              itemCount: modules.length,
              itemBuilder: (context, index) {
                return _buildGridItem(
                  context,
                  modules[index]['title'],
                  modules[index]['icon'],
                  modules[index]['route'],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingEventCard(BuildContext context, AppLocalizations localizations) {
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
              child: Text(localizations.eventOnDate, textAlign: TextAlign.center),
            ),
          );
        }

        final eventData = snapshot.data!.data() as Map<String, dynamic>;
        final event = Event.fromFirestore(snapshot.data!);
        final locale = Localizations.localeOf(context).languageCode;
        final eventTitle = locale == 'mr' ? event.title_mr : event.title_en;
        final eventDate = (eventData['start_time'] as Timestamp).toDate();
        final eventDateString = DateFormat.yMMMMd(locale).format(eventDate);

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EventCalendarScreen(initialDate: eventDate),
              ),
            );
          },
          child: Card(
            elevation: 4.0,
            color: Colors.orange[50],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
              side: BorderSide(color: Colors.orange.withAlpha(128), width: 1),
            ),
            margin: const EdgeInsets.all(8.0),
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
                  Text(eventTitle, style: TextStyle(color: Colors.orange[600], fontWeight: FontWeight.bold)),
                  Text(eventDateString, style: TextStyle(color: Colors.orange[600])),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGridItem(BuildContext context, String title, IconData icon, String route) {
    return Card(
      elevation: 8.0,
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
            Icon(icon, size: 40.0, color: Colors.orange[400]),
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
    );
  }
}

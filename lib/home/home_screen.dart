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

    final nityopasanaModule = {'title': localizations.nityopasanaTitle, 'icon': 'resources/images/icon/NityaSmaran.png', 'route': Routes.nityopasana};
    final List<Map<String, dynamic>> modules = [
      {'title': localizations.calendarTitle, 'icon': Icons.calendar_month_outlined, 'route': Routes.calendar},
      {'title': localizations.donationsTitle, 'icon': Icons.volunteer_activism_outlined, 'route': Routes.donations},
      {'title': localizations.aboutMaharajTitle, 'icon': Icons.info_outline, 'route': Routes.aboutMaharaj},
      {'title': localizations.socialMediaTitle, 'icon': Icons.connect_without_contact, 'route': Routes.socialMedia},
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
          _buildFullWidthCard(context, nityopasanaModule['title']!, nityopasanaModule['icon']!, nityopasanaModule['route']!),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.4,
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
  
  Widget _buildFullWidthCard(BuildContext context, String title, dynamic icon, String route) {
    return Card(
      elevation: 8.0,
      color: Colors.orange[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: Colors.orange.withAlpha(128), width: 1),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (icon is IconData)
                    Icon(icon, size: 40.0, color: Colors.orange[400])
                  else if (icon is String)
                    Image.asset(icon, height: 40.0, width: 40.0),
                  const SizedBox(width: 16.0),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18.0,
                      color: Colors.orange[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.orange[400]),
            ],
          ),
        ),
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

  Widget _buildGridItem(BuildContext context, String title, dynamic icon, String route) {
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
    );
  }
}

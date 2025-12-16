import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/event_calendar/event_calendar_screen.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/utils/routes.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    final List<Map<String, dynamic>> modules = [
      {'title': localizations.granthTitle, 'icon': Icons.book, 'route': Routes.granth},
      {'title': localizations.stotraTitle, 'icon': Icons.queue_music, 'route': Routes.stotra},
      {'title': localizations.namavaliTitle, 'icon': Icons.format_list_numbered, 'route': Routes.namavali},
      {'title': localizations.aartiTitle, 'icon': Icons.audiotrack, 'route': Routes.aarti},
      {'title': localizations.bhajanTitle, 'icon': Icons.music_note, 'route': Routes.bhajan},
      {'title': localizations.sankalpTitle, 'icon': Icons.calendar_today, 'route': Routes.sankalp},
      {'title': localizations.parayanTitle, 'icon': Icons.group_work, 'route': Routes.parayan},
      {'title': localizations.aboutMaharajTitle, 'icon': Icons.info, 'route': Routes.aboutMaharaj},
      {'title': localizations.calendarTitle, 'icon': Icons.event, 'route': Routes.calendar},
      {'title': localizations.donationsTitle, 'icon': Icons.volunteer_activism, 'route': Routes.donations},
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
    final eventDate = DateTime(2025, 2, 21);

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
          side: BorderSide(color: Colors.orange.withOpacity(0.5), width: 1),
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
              Text(localizations.prakatDinUtsav, style: TextStyle(color: Colors.orange[600])),
              Text('February 21, 2025', style: TextStyle(color: Colors.orange[600])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridItem(BuildContext context, String title, IconData icon, String route) {
    return Card(
      elevation: 8.0,
      color: Colors.orange[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: Colors.orange.withOpacity(0.5), width: 1),
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

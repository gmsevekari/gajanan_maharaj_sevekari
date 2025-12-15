import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/utils/constants.dart';
import 'package:gajanan_maharaj_sevekari_app_demo/utils/routes.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> modules = [
      {'title': Constants.granthTitle, 'icon': Icons.book, 'route': Routes.granth},
      {'title': Constants.stotraTitle, 'icon': Icons.queue_music, 'route': Routes.stotra},
      {'title': Constants.namavaliTitle, 'icon': Icons.format_list_numbered, 'route': Routes.namavali},
      {'title': Constants.aartiTitle, 'icon': Icons.audiotrack, 'route': Routes.aarti},
      {'title': Constants.bhajanTitle, 'icon': Icons.music_note, 'route': Routes.bhajan},
      {'title': Constants.sankalpTitle, 'icon': Icons.calendar_today, 'route': Routes.sankalp},
      {'title': Constants.parayanTitle, 'icon': Icons.group_work, 'route': Routes.parayan},
      {'title': Constants.aboutMaharajTitle, 'icon': Icons.info, 'route': Routes.aboutMaharaj},
      {'title': Constants.calendarTitle, 'icon': Icons.event, 'route': Routes.calendar},
      {'title': Constants.donationsTitle, 'icon': Icons.volunteer_activism, 'route': Routes.donations},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(Constants.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, Routes.settings),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildUpcomingEventCard(context),
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

  Widget _buildUpcomingEventCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 4.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Upcoming Event',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 8.0),
            const Text('Prakat Din Utsav'),
            const Text('February 21, 2025'),
          ],
        ),
      ),
    );
  }

  Widget _buildGridItem(BuildContext context, String title, IconData icon, String route) {
    return Card(
      elevation: 2.0,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40.0, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8.0),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
      ),
    );
  }
}

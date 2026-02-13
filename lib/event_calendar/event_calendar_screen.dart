import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/utils/marathi_utils.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';

// Event Model
class Event {
  final String title_mr;
  final String title_en;
  final Timestamp start_time;
  final Timestamp? end_time;
  final String? location_mr;
  final String? location_en;
  final String? details_mr;
  final String? details_en;
  final String? address;

  Event({
    required this.title_mr,
    required this.title_en,
    required this.start_time,
    this.end_time,
    this.location_mr,
    this.location_en,
    this.details_mr,
    this.details_en,
    this.address,
  });

  factory Event.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Event(
      title_mr: data['title_mr'] ?? '',
      title_en: data['title_en'] ?? '',
      start_time: data['start_time'] ?? Timestamp.now(),
      end_time: data['end_time'] as Timestamp?,
      location_mr: data['location_mr'] as String?,
      location_en: data['location_en'] as String?,
      details_mr: data['details_mr'] as String?,
      details_en: data['details_en'] as String?,
      address: data['address'] as String?,
    );
  }
}

class EventCalendarScreen extends StatefulWidget {
  final DateTime? initialDate;

  const EventCalendarScreen({super.key, this.initialDate});

  @override
  _EventCalendarScreenState createState() => _EventCalendarScreenState();
}

class _EventCalendarScreenState extends State<EventCalendarScreen> with TickerProviderStateMixin {
  TabController? _tabController;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  Map<DateTime, List<Event>> _events = {};
  List<Event> _allEvents = [];
  List<Event> _filteredEvents = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _focusedDay = widget.initialDate ?? DateTime.now();
    _selectedDay = widget.initialDate ?? DateTime.now();
    _fetchEvents();
    _searchController.addListener(_filterEvents);
    _tabController!.addListener(() {
      setState(() {}); // Rebuild to update FAB visibility and AppBar title
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _fetchEvents() {
    FirebaseFirestore.instance
        .collection('events')
        .orderBy('start_time', descending: false)
        .snapshots()
        .listen((snapshot) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final Map<DateTime, List<Event>> events = {};
      final List<Event> allEvents = [];
      for (var doc in snapshot.docs) {
        final event = Event.fromFirestore(doc);
        if (event.start_time.toDate().isBefore(today)) continue;
        allEvents.add(event);
        final date = event.start_time.toDate();
        final day = DateTime.utc(date.year, date.month, date.day);
        if (events[day] == null) {
          events[day] = [];
        }
        events[day]!.add(event);
      }
      setState(() {
        _events = events;
        _allEvents = allEvents;
        _filteredEvents = allEvents;
      });
    });
  }

  void _filterEvents() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredEvents = _allEvents.where((event) {
        final title = event.title_mr.toLowerCase() + event.title_en.toLowerCase();
        return title.contains(query);
      }).toList();
    });
  }

  List<Event> _getEventsForDay(DateTime day) {
    return _events[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }

  Future<void> _launchMaps(String address) async {
    final query = Uri.encodeComponent(address);
    final url = 'https://www.google.com/maps/search/?api=1&query=$query';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  String _formatMarathiTime(DateTime time) {
    final hour = time.hour;
    String period;
    if (hour >= 5 && hour < 12) {
      period = "सकाळी"; // Morning
    } else if (hour >= 12 && hour < 17) {
      period = "दुपारी"; // Afternoon
    } else if (hour >= 17 && hour < 20) {
      period = "सायंकाळी"; // Evening
    } else {
      period = "रात्री"; // Night
    }
    final formattedTime = DateFormat('hh:mm').format(time);
    final marathiTime = toMarathiNumerals(formattedTime);
    return '$period $marathiTime';
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
            _tabController?.index == 0
                ? localizations.calendarTitle
                : localizations.allEventsList,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)
        ),
        backgroundColor: Colors.orange,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, Routes.home, (route) => false),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, Routes.settings),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: localizations.calendarTitle),
            Tab(text: localizations.list),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(), // Disable swipe gesture
        children: [
          _buildCalendarView(),
          _buildListView(),
        ],
      ),
      floatingActionButton: _tabController?.index == 0
          ? FloatingActionButton(
        onPressed: () => _tabController?.animateTo(1),
        child: const Icon(Icons.list),
      )
          : null,
    );
  }

  Widget _buildCalendarView() {
    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          eventLoader: _getEventsForDay,
          calendarStyle: CalendarStyle(
            weekendTextStyle: TextStyle(color: Colors.orange.shade700),
          ),
          headerStyle: HeaderStyle(
            formatButtonTextStyle: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
            formatButtonDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
          onFormatChanged: (format) {
            if (_calendarFormat != format) {
              setState(() {
                _calendarFormat = format;
              });
            }
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
        ),
        const SizedBox(height: 8.0),
        Expanded(
          child: _buildEventListForCalendar(),
        ),
      ],
    );
  }

  Widget _buildListView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context).searchEvent,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _filteredEvents.length,
            itemBuilder: (context, index) {
              return _buildEventCard(_filteredEvents[index], isSelected: false);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEventListForCalendar() {
    final endDate = _selectedDay!.add(const Duration(days: 30));
    final eventsToShow = _allEvents.where((event) {
      final eventDate = event.start_time.toDate();
      return (eventDate.isAfter(_selectedDay!) || isSameDay(eventDate, _selectedDay)) && eventDate.isBefore(endDate);
    }).toList();

    if (eventsToShow.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context).eventOnDate),
      );
    }

    return ListView.builder(
      itemCount: eventsToShow.length,
      itemBuilder: (context, index) {
        final event = eventsToShow[index];
        final isSelected = isSameDay(event.start_time.toDate(), _selectedDay);
        return _buildEventCard(event, isSelected: isSelected);
      },
    );
  }

  Widget _buildEventCard(Event event, {required bool isSelected}) {
    final locale = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);

    final title = locale == 'mr' ? event.title_mr : event.title_en;
    final location = (locale == 'mr' ? event.location_mr : event.location_en) ?? '';
    final details = (locale == 'mr' ? event.details_mr : event.details_en) ?? '';

    final String startTime;
    final String? endTime;

    if (locale == 'mr') {
      startTime = _formatMarathiTime(event.start_time.toDate());
      endTime = event.end_time != null ? _formatMarathiTime(event.end_time!.toDate()) : null;
    } else {
      final timeFormatter = DateFormat.jm(locale);
      startTime = timeFormatter.format(event.start_time.toDate());
      endTime = event.end_time != null ? timeFormatter.format(event.end_time!.toDate()) : null;
    }

    final eventDateString = DateFormat.yMMMMEEEEd(locale).format(event.start_time.toDate());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: theme.cardTheme.elevation,
      color: isSelected ? Colors.orange[200] : theme.cardTheme.color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isSelected
              ? BorderSide(color: Colors.orange.shade700, width: 2)
              : BorderSide(color: Color(0xFFFF9800), width: 1),
        ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(eventDateString, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.orange[800])),
            const SizedBox(height: 8),
            Text(title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.orange[800])),
            const SizedBox(height: 8),
            if (endTime != null) Row(children: [const Icon(Icons.access_time, size: 16, color: Colors.orange), const SizedBox(width: 8), Text('$startTime - $endTime', style: TextStyle(color: Colors.orange[700]))]) else Row(children: [const Icon(Icons.access_time, size: 16, color: Colors.orange), const SizedBox(width: 8), Text(startTime, style: TextStyle(color: Colors.orange[700]))]),
            const SizedBox(height: 8),
            if (location.isNotEmpty) InkWell(
              onTap: event.address != null ? () => _launchMaps(event.address!) : null,
              child: Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      location,
                      style: TextStyle(
                        decoration: event.address != null ? TextDecoration.underline : TextDecoration.none,
                        color: event.address != null ? Colors.blue : Colors.orange[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (details.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(details, style: TextStyle(color: Colors.orange[700])),
            ],
          ],
        ),
      ),
    );
  }
}

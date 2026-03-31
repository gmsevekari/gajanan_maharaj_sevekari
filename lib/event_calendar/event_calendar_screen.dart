import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/utils/marathi_utils.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:gajanan_maharaj_sevekari/utils/calendar_export_service.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';

enum EventType { weeklyPooja, specialEvent, other }

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
  final EventType event_type;

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
    this.event_type = EventType.other,
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
      event_type: _parseEventType(data['event_type'] as String?),
    );
  }

  static EventType _parseEventType(String? typeStr) {
    if (typeStr == null) return EventType.other;
    switch (typeStr.toLowerCase()) {
      case 'weekly pooja':
      case 'weekly_pooja':
      case 'weeklypooja':
        return EventType.weeklyPooja;
      case 'special event':
      case 'special_event':
      case 'specialevent':
        return EventType.specialEvent;
      default:
        return EventType.other;
    }
  }
}

class EventCalendarScreen extends StatefulWidget {
  final DateTime? initialDate;

  const EventCalendarScreen({super.key, this.initialDate});

  @override
  _EventCalendarScreenState createState() => _EventCalendarScreenState();
}

class _EventCalendarScreenState extends State<EventCalendarScreen>
    with TickerProviderStateMixin {
  TabController? _tabController;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  Map<DateTime, List<Event>> _events = {};
  List<Event> _allEvents = [];
  List<Event> _filteredEvents = [];
  List<Event> _specialEvents = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
          final List<Event> specialEvents = [];
          for (var doc in snapshot.docs) {
            final event = Event.fromFirestore(doc);
            if (event.start_time.toDate().isBefore(today)) continue;
            allEvents.add(event);
            if (event.event_type == EventType.specialEvent) {
              specialEvents.add(event);
            }
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
            _specialEvents = specialEvents;
          });
        });
  }

  void _filterEvents() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredEvents = _allEvents.where((event) {
        final title =
            event.title_mr.toLowerCase() + event.title_en.toLowerCase();
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

  List<dynamic> _getGroupedEvents(List<Event> events) {
    final List<dynamic> grouped = [];
    String? currentMonth;
    final locale = Localizations.localeOf(context).languageCode;

    for (var event in events) {
      final date = event.start_time.toDate();
      final monthYear = DateFormat('MMMM yyyy', locale).format(date);

      if (monthYear != currentMonth) {
        grouped.add(monthYear);
        currentMonth = monthYear;
      }
      grouped.add(event);
    }
    return grouped;
  }

  Widget _buildGroupedListView(List<Event> events, {DateTime? selectedDate}) {
    if (events.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context)!.eventOnDate));
    }

    final groupedItems = _getGroupedEvents(events);
    final theme = Theme.of(context);

    return ListView.builder(
      itemCount: groupedItems.length,
      padding: const EdgeInsets.only(bottom: 16),
      itemBuilder: (context, index) {
        final item = groupedItems[index];

        if (item is String) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              item.toUpperCase(),
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          );
        } else {
          final event = item as Event;
          final isSelected =
              selectedDate != null &&
              isSameDay(event.start_time.toDate(), selectedDate);
          return _buildEventCard(event, isSelected: isSelected);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _tabController?.index == 0
              ? localizations.calendarTitle
              : _tabController?.index == 1
              ? localizations.specialEvents
              : localizations.allEventsList,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: theme.appColors.primarySwatch,
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
            icon: Image.asset(
              'resources/images/icon/Export_Calendar.png',
              width: 24,
              height: 24,
            ),
            tooltip: localizations.exportToCalendar,
            onPressed: () => CalendarExportService.exportEventsToIcs(
              _specialEvents,
              "special_events",
            ),
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
            Tab(text: localizations.specialEvents),
            Tab(text: localizations.allEvents),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        // Swiping is now enabled by default.
        children: [
          _buildCalendarView(),
          _buildSpecialEventsView(),
          _buildListView(),
        ],
      ),
      floatingActionButton: _tabController?.index == 0
          ? FloatingActionButton(
              onPressed: () => _tabController?.animateTo(2),
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
          availableGestures: AvailableGestures.none,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          eventLoader: _getEventsForDay,
          calendarStyle: CalendarStyle(
            weekendTextStyle: TextStyle(
              color: Theme.of(context).appColors.primarySwatch.shade700,
            ),
          ),
          headerStyle: HeaderStyle(
            formatButtonTextStyle: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
            ),
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
        Expanded(child: _buildEventListForCalendar()),
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
              hintText: AppLocalizations.of(context)!.searchEvent,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
          ),
        ),
        Expanded(child: _buildGroupedListView(_filteredEvents)),
      ],
    );
  }

  Widget _buildSpecialEventsView() {
    return _buildGroupedListView(_specialEvents);
  }

  Widget _buildEventListForCalendar() {
    final endDate = _selectedDay!.add(
      const Duration(days: 90),
    ); // Show 3 months of upcoming events from selected day
    final eventsToShow = _allEvents.where((event) {
      final eventDate = event.start_time.toDate();
      return (eventDate.isAfter(_selectedDay!) ||
              isSameDay(eventDate, _selectedDay)) &&
          eventDate.isBefore(endDate);
    }).toList();

    return _buildGroupedListView(eventsToShow, selectedDate: _selectedDay);
  }

  Widget _buildEventCard(Event event, {required bool isSelected}) {
    final locale = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);

    final title = locale == 'mr' ? event.title_mr : event.title_en;
    final location =
        (locale == 'mr' ? event.location_mr : event.location_en) ?? '';
    final details =
        (locale == 'mr' ? event.details_mr : event.details_en) ?? '';

    final String startTime;
    final String? endTime;

    if (locale == 'mr') {
      startTime = _formatMarathiTime(event.start_time.toDate());
      endTime = event.end_time != null
          ? _formatMarathiTime(event.end_time!.toDate())
          : null;
    } else {
      final timeFormatter = DateFormat.jm(locale);
      startTime = timeFormatter.format(event.start_time.toDate());
      endTime = event.end_time != null
          ? timeFormatter.format(event.end_time!.toDate())
          : null;
    }

    final eventDateString = DateFormat(
      'EEEE, d MMMM y',
      locale,
    ).format(event.start_time.toDate());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: theme.cardTheme.elevation,
      color: isSelected
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
          : theme.cardTheme.color,
      shape: isSelected
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.colorScheme.primary, width: 2),
            )
          : theme.cardTheme.shape,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eventDateString,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  endTime != null ? '$startTime - $endTime' : startTime,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            if (location.isNotEmpty) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: event.address != null
                    ? () => _launchMaps(event.address!)
                    : null,
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        location,
                        style: TextStyle(
                          decoration: event.address != null
                              ? TextDecoration.underline
                              : TextDecoration.none,
                          color: event.address != null
                              ? Colors.blue
                              : theme.colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (details.isNotEmpty) ...[
              const SizedBox(height: 12),
              Divider(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
              ),
              const SizedBox(height: 4),
              Text(
                details,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

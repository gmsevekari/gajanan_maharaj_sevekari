import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/utils/locale_extensions.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/admin/parayan_admin_detail_screen.dart';
import 'package:gajanan_maharaj_sevekari/utils/marathi_utils.dart';
import 'package:gajanan_maharaj_sevekari/utils/date_time_utils.dart';
import 'package:gajanan_maharaj_sevekari/parayan/utils/parayan_extensions.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/parayan_event.dart';
import 'package:gajanan_maharaj_sevekari/parayan/parayan_type.dart';
import 'package:gajanan_maharaj_sevekari/providers/parayan_service.dart';

class ParayanAdminListScreen extends StatefulWidget {
  final String title;
  final String statusFilter; // 'completed' or 'upcoming'
  final String? groupId;

  const ParayanAdminListScreen({
    super.key,
    required this.title,
    required this.statusFilter,
    this.groupId,
  });

  @override
  State<ParayanAdminListScreen> createState() => _ParayanAdminListScreenState();
}

class _ParayanAdminListScreenState extends State<ParayanAdminListScreen> {
  final ParayanService _parayanService = ParayanService();
  late Stream<List<ParayanEvent>> _eventsStream;

  @override
  void initState() {
    super.initState();
    _eventsStream = _parayanService.getAllEvents(widget.groupId!);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nowYear = DateTime.now().year;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: StreamBuilder<List<ParayanEvent>>(
        stream: _eventsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allEvents = snapshot.data ?? [];
          final filteredEvents = allEvents.where((e) {
            // Filter by status and current year
            bool matchesStatus = e.status == widget.statusFilter;
            bool matchesYear = e.startDate.year == nowYear;
            return matchesStatus && matchesYear;
          }).toList();

          // Sort: Upcoming by date ascending, Completed by date descending
          if (widget.statusFilter == 'upcoming') {
            filteredEvents.sort((a, b) => a.startDate.compareTo(b.startDate));
          } else {
            filteredEvents.sort((a, b) => b.endDate.compareTo(a.endDate));
          }

          if (filteredEvents.isEmpty) {
            return Center(
              child: Text(
                AppLocalizations.of(context)!.noParayansFound,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.appColors.secondaryText,
                ),
              ),
            );
          }

          // Group by month
          final grouped = <String, List<ParayanEvent>>{};
          for (var e in filteredEvents) {
            final locale = Localizations.localeOf(context).languageCode;
            final monthStr = formatMonthYear(e.startDate, locale);
            grouped.putIfAbsent(monthStr, () => []).add(e);
          }

          // Flatten for ListView
          final listItems = <_ListItem>[];
          grouped.forEach((month, events) {
            listItems.add(_ListItem(month: month));
            for (var e in events) {
              listItems.add(_ListItem(event: e));
            }
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: listItems.length,
            itemBuilder: (context, index) {
              final item = listItems[index];
              if (item.month != null) {
                return _MonthHeader(title: item.month!);
              } else {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _AdminEventCard(event: item.event!),
                );
              }
            },
          );
        },
      ),
    );
  }
}

class _ListItem {
  final String? month;
  final ParayanEvent? event;
  _ListItem({this.month, this.event});
}

class _MonthHeader extends StatelessWidget {
  final String title;
  const _MonthHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 12, left: 4),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _AdminEventCard extends StatelessWidget {
  final ParayanEvent event;

  const _AdminEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMarathi = Localizations.localeOf(context).useMarathiContent;
    final locale = Localizations.localeOf(context).languageCode;
    final dateStr = formatDateShort(event.startDate, locale).toUpperCase();

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ParayanAdminDetailScreen(event: event),
          ),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      dateStr,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildTypeChip(theme, event.type),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                isMarathi ? event.titleMr : event.titleEn,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isMarathi ? event.descriptionMr : event.descriptionEn,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.appColors.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(ThemeData theme, ParayanType type) {
    String label = 'Parayan';
    if (type == ParayanType.oneDay) label = '1-Day';
    if (type == ParayanType.threeDay) label = '3-Day';
    if (type == ParayanType.guruPushya) label = 'Guru Pushya';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 8,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(Icons.person, size: 10, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

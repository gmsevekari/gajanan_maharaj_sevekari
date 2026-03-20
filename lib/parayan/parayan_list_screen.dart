import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/parayan_event.dart';
import 'package:gajanan_maharaj_sevekari/parayan/parayan_detail_screen.dart';
import 'package:gajanan_maharaj_sevekari/parayan/parayan_type.dart';
import 'package:gajanan_maharaj_sevekari/providers/parayan_service.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:intl/intl.dart';

class ParayanListScreen extends StatefulWidget {
  const ParayanListScreen({super.key});

  @override
  State<ParayanListScreen> createState() => _ParayanListScreenState();
}

class _ParayanListScreenState extends State<ParayanListScreen> {
  final ParayanService _parayanService = ParayanService();
  late Stream<List<ParayanEvent>> _eventsStream;

  @override
  void initState() {
    super.initState();
    _eventsStream = _parayanService.getActiveEvents();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (localizations == null) return const SizedBox.shrink();
    final locale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.parayanListTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.orange,
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
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, Routes.settings),
          ),
        ],
      ),
      body: StreamBuilder<List<ParayanEvent>>(
        stream: _eventsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final events = snapshot.data ?? [];

          if (events.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.menu_book_outlined,
                      size: 80,
                      color: Colors.orange.withValues(alpha: 0.2),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      localizations.noActiveParayans,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          // Group events by month/year
          final grouped = <String, List<ParayanEvent>>{};
          for (final event in events) {
            final monthKey = DateFormat('MMMM yyyy', locale).format(
              event.startDate,
            );
            grouped.putIfAbsent(monthKey, () => []).add(event);
          }

          final flattened = <dynamic>[];
          grouped.forEach((month, monthEvents) {
            flattened.add(month);
            flattened.addAll(monthEvents);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: flattened.length,
            itemBuilder: (context, index) {
              final item = flattened[index];

              if (item is String) {
                // Return Month Header
                return Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 12, left: 4),
                  child: Text(
                    item.toUpperCase(),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                );
              }

              final event = item as ParayanEvent;
              final title = locale == 'mr' ? event.titleMr : event.titleEn;

              final isSingleDay =
                  event.type == ParayanType.oneDay ||
                  event.type == ParayanType.guruPushya;
              final dateRange = isSingleDay
                  ? (locale == 'mr'
                      ? DateFormat('d MMMM, yyyy', 'mr').format(event.startDate)
                      : DateFormat('MMMM d, yyyy').format(event.startDate))
                  : (locale == 'mr'
                      ? "${DateFormat('d MMMM', 'mr').format(event.startDate)} - ${DateFormat('d MMMM, yyyy', 'mr').format(event.endDate)}"
                      : "${DateFormat('MMMM d').format(event.startDate)} - ${DateFormat('MMMM d, yyyy').format(event.endDate)}");
              final typeLabel =
                  event.type == ParayanType.oneDay
                      ? localizations.oneDayParayan
                      : event.type == ParayanType.threeDay
                      ? localizations.threeDayParayan
                      : localizations.guruPushyaParayan;

              return Card(
                elevation: theme.cardTheme.elevation,
                margin: const EdgeInsets.only(bottom: 16),
                shape: theme.cardTheme.shape,
                color: theme.cardTheme.color,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ParayanDetailScreen(event: event),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                              Icons.category,
                              size: 16,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              typeLabel,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              dateRange,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

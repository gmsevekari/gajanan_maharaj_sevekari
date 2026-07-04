import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/vaari_event.dart';
import 'package:gajanan_maharaj_sevekari/providers/vaari_service.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:gajanan_maharaj_sevekari/utils/date_time_utils.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/widgets/themed_icon.dart';
import 'package:gajanan_maharaj_sevekari/utils/group_utils.dart';
import 'package:gajanan_maharaj_sevekari/utils/marathi_utils.dart';
import 'package:provider/provider.dart';

class VaariListScreen extends StatefulWidget {
  final String? groupId;
  final String? groupName;

  const VaariListScreen({super.key, this.groupId, this.groupName});

  @override
  State<VaariListScreen> createState() => _VaariListScreenState();
}

class _VaariListScreenState extends State<VaariListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Stream<List<VaariEvent>>? _activeEventsStream;
  Stream<List<VaariEvent>>? _completedEventsStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    final service = context.read<VaariService>();
    final effectiveGroupId = widget.groupId ?? GroupConstants.seattle;
    _activeEventsStream = service.getActiveEvents(effectiveGroupId);
    _completedEventsStream = service.getCompletedEvents(effectiveGroupId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            widget.groupName ?? localizations.vaariTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        backgroundColor: theme.appColors.primarySwatch,
        iconTheme: IconThemeData(color: theme.colorScheme.onPrimary),
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.onPrimary,
          unselectedLabelColor: theme.colorScheme.onPrimary.withValues(
            alpha: 0.7,
          ),
          indicatorColor: theme.colorScheme.onPrimary,
          tabs: [
            Tab(text: localizations.upcomingActiveTab),
            Tab(text: localizations.statusCompleted),
          ],
        ),
        actions: [
          IconButton(
            icon: const ThemedIcon(LogicalIcon.home),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              Routes.home,
              (route) => false,
            ),
          ),
          IconButton(
            icon: const ThemedIcon(LogicalIcon.settings),
            onPressed: () => Navigator.pushNamed(context, Routes.settings),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildEventListStream(
            _activeEventsStream!,
            localizations.noActiveVaaris,
            locale,
            theme,
          ),
          _buildEventListStream(
            _completedEventsStream!,
            localizations.noCompletedVaaris,
            locale,
            theme,
          ),
        ],
      ),
    );
  }

  Widget _buildEventListStream(
    Stream<List<VaariEvent>> stream,
    String noDataText,
    String locale,
    ThemeData theme,
  ) {
    return StreamBuilder<List<VaariEvent>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading data: ${snapshot.error}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final events = snapshot.data ?? [];
        if (events.isEmpty) {
          return _buildNoDataView(theme, noDataText);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            final title = locale == 'mr' ? event.nameMr : event.nameEn;
            final dateRange = _formatDateRange(
              event.startDate,
              event.endDate,
              locale,
            );

            final stepSuffix = locale == 'mr' ? ' पायऱ्या' : ' steps';
            final distSuffix = locale == 'mr' ? ' किमी' : ' ${event.distanceUnit}';
            final formattedSteps = formatNumberLocalized(
                  event.totalSteps,
                  locale,
                  pad: false,
                ) +
                stepSuffix;
            final formattedDistance = (locale == 'mr'
                    ? toMarathiNumerals(event.totalDistance.toStringAsFixed(1))
                    : event.totalDistance.toStringAsFixed(1)) +
                distSuffix;

            return Card(
              elevation: theme.cardTheme.elevation,
              margin: const EdgeInsets.only(bottom: 16),
              shape: theme.cardTheme.shape,
              color: theme.cardTheme.color,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    Routes.vaariDetail,
                    arguments: {
                      'id': event.id,
                      'joinCode': event.joinCode,
                    },
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
                      const SizedBox(height: 12),
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
                              color: theme.appColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.directions_walk,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                formattedSteps,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.straighten,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                formattedDistance,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
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
    );
  }

  Widget _buildNoDataView(ThemeData theme, String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text(
          text,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.appColors.secondaryText,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  String _formatDateRange(DateTime start, DateTime end, String locale) {
    return '${formatDateShort(start, locale)} - ${formatDateShort(end, locale)}';
  }
}

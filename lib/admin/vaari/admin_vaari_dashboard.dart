import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/vaari_event.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:gajanan_maharaj_sevekari/widgets/themed_icon.dart';
import 'package:gajanan_maharaj_sevekari/utils/marathi_utils.dart';
import 'package:gajanan_maharaj_sevekari/admin/widgets/admin_stats_widgets.dart';
import 'package:gajanan_maharaj_sevekari/utils/date_time_utils.dart';
import 'package:gajanan_maharaj_sevekari/models/admin_user.dart';

class AdminVaariDashboard extends StatefulWidget {
  final AdminUser adminUser;

  /// Injected for testing; defaults to [FirebaseFirestore.instance].
  final FirebaseFirestore? firestore;

  const AdminVaariDashboard({
    super.key,
    required this.adminUser,
    this.firestore,
  });

  @override
  State<AdminVaariDashboard> createState() => _AdminVaariDashboardState();
}

class _AdminVaariDashboardState extends State<AdminVaariDashboard> {
  /// Ongoing events are capped at this many cards on the dashboard; the
  /// full list is one tap away via "View All" (Routes.adminVaariList).
  static const int _maxOngoingCardsShown = 5;

  late final FirebaseFirestore _firestore;
  late Stream<QuerySnapshot> _eventsStream;

  @override
  void initState() {
    super.initState();
    _firestore = widget.firestore ?? FirebaseFirestore.instance;
    Query query = _firestore.collection('vaari_events');
    if (widget.adminUser.groupId != null) {
      query = query.where('groupId', isEqualTo: widget.adminUser.groupId);
    }
    _eventsStream = query.snapshots();
  }

  @override
  void didUpdateWidget(covariant AdminVaariDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.adminUser.groupId != oldWidget.adminUser.groupId) {
      Query query = _firestore.collection('vaari_events');
      if (widget.adminUser.groupId != null) {
        query = query.where('groupId', isEqualTo: widget.adminUser.groupId);
      }
      setState(() {
        _eventsStream = query.snapshots();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.adminVaariDashboardTitle),
        actions: [
          IconButton(
            icon: const ThemedIcon(LogicalIcon.home),
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
          ),
          IconButton(
            icon: const ThemedIcon(LogicalIcon.settings),
            onPressed: () => Navigator.pushNamed(context, Routes.settings),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _eventsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            debugPrint(
              'AdminVaariDashboard events stream error: ${snapshot.error}',
            );
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 60,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    localizations.adminVaariLoadError,
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }

          final allDocs = snapshot.data?.docs ?? [];
          final allEvents = allDocs
              .map(
                (doc) => VaariEvent.fromMap(
                  doc.id,
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList();

          final activeEvents =
              allEvents.where((e) => e.status == 'ongoing').toList()
                ..sort((a, b) => b.startDate.compareTo(a.startDate));

          final upcomingEvents =
              allEvents
                  .where(
                    (e) => e.status == 'upcoming' || e.status == 'enrolling',
                  )
                  .toList()
                ..sort((a, b) => a.startDate.compareTo(b.startDate));

          final completedEvents =
              allEvents.where((e) => e.status == 'completed').toList()
                ..sort((a, b) => b.endDate.compareTo(a.endDate));

          final activeCount = activeEvents.length;
          final completedCount = completedEvents.length;

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      _buildStatsRow(
                        context,
                        theme,
                        activeCount,
                        completedCount,
                        localizations,
                      ),
                      const SizedBox(height: 32),
                      _buildSectionHeader(
                        localizations,
                        theme,
                        localizations.adminVaariCompleted,
                        showViewAll: true,
                        onViewAll: () => Navigator.pushNamed(
                          context,
                          Routes.adminVaariList,
                          arguments: {
                            'status': 'completed',
                            'adminUser': widget.adminUser,
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Intentional: only the most recent completed event is
                      // previewed here; the "View All" link above opens the
                      // full completed list.
                      if (completedEvents.isNotEmpty)
                        _UpcomingCard(
                          event: completedEvents.first,
                          adminUser: widget.adminUser,
                        )
                      else
                        Text(
                          localizations.adminVaariNoCompleted,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.appColors.secondaryText,
                          ),
                        ),
                      const SizedBox(height: 32),
                      _buildSectionHeader(
                        localizations,
                        theme,
                        localizations.adminVaariOngoing,
                        showViewAll: false,
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              if (activeEvents.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      localizations.adminVaariNoOngoing,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _OngoingCard(
                        event: activeEvents[index],
                        adminUser: widget.adminUser,
                      ),
                      childCount: activeEvents.length > _maxOngoingCardsShown
                          ? _maxOngoingCardsShown
                          : activeEvents.length,
                    ),
                  ),
                ),
              if (upcomingEvents.isNotEmpty) ...[
                SliverPadding(
                  padding: const EdgeInsets.only(
                    left: 16,
                    top: 32,
                    bottom: 12,
                    right: 16,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _buildSectionHeader(
                      localizations,
                      theme,
                      localizations.adminVaariUpcoming,
                      showViewAll: true,
                      onViewAll: () => Navigator.pushNamed(
                        context,
                        Routes.adminVaariList,
                        arguments: {
                          'status': 'upcoming',
                          'adminUser': widget.adminUser,
                        },
                      ),
                    ),
                  ),
                ),
                // Intentional: only the next upcoming event is previewed
                // here; the "View All" link above opens the full list.
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(
                    child: _UpcomingCard(
                      event: upcomingEvents.first,
                      adminUser: widget.adminUser,
                    ),
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
              SliverToBoxAdapter(
                child: Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      Routes.adminCreateVaari,
                      arguments: widget.adminUser,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(localizations.createVaariTitle),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 48)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsRow(
    BuildContext context,
    ThemeData theme,
    int active,
    int completed,
    AppLocalizations localizations,
  ) {
    final langCode = Localizations.localeOf(context).languageCode;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: StatCard(
              label: localizations.adminVaariOngoing.toUpperCase(),
              value: formatNumberLocalized(active, langCode, pad: false),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: StatCard(
              label: localizations.adminVaariCompleted.toUpperCase(),
              value: formatNumberLocalized(completed, langCode, pad: false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    AppLocalizations localizations,
    ThemeData theme,
    String title, {
    bool showViewAll = true,
    VoidCallback? onViewAll,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (showViewAll)
          TextButton(
            onPressed: onViewAll,
            child: Text(
              localizations.viewAllLabel,
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class _OngoingCard extends StatelessWidget {
  final VaariEvent event;
  final AdminUser adminUser;

  const _OngoingCard({required this.event, required this.adminUser});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;
    final langCode = Localizations.localeOf(context).languageCode;
    final isEnglish = langCode == 'en';
    final title = isEnglish ? event.nameEn : event.nameMr;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.pushNamed(
          context,
          Routes.adminVaariDetail,
          arguments: {'eventId': event.id, 'adminUser': adminUser},
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: theme.colorScheme.primary.withValues(
                  alpha: 0.1,
                ),
                child: Icon(
                  Icons.directions_walk,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${formatDateShort(event.startDate, langCode)} - ${formatDateShort(event.endDate, langCode)}",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${localizations.adminVaariTargetDistancePrefix}${formatDistanceLocalized(event.targetDistance, langCode)} ${localizedDistanceUnitLabel(event.distanceUnit, langCode)}",
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.chevron_right, color: theme.appColors.divider),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  final VaariEvent event;
  final AdminUser adminUser;

  const _UpcomingCard({required this.event, required this.adminUser});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final langCode = Localizations.localeOf(context).languageCode;
    final isEnglish = langCode == 'en';

    return SizedBox(
      width: double.infinity,
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: () => Navigator.pushNamed(
            context,
            Routes.adminVaariDetail,
            arguments: {'eventId': event.id, 'adminUser': adminUser},
          ),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: theme.colorScheme.primary.withValues(
                        alpha: 0.1,
                      ),
                      child: Icon(
                        Icons.directions_walk,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isEnglish ? event.nameEn : event.nameMr,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        () {
                          final l10n = AppLocalizations.of(context)!;
                          switch (event.status) {
                            case 'ongoing':
                              return l10n.statusOngoing;
                            case 'enrolling':
                              return l10n.statusEnrolling;
                            case 'completed':
                              return l10n.statusCompleted;
                            default:
                              return l10n.statusUpcoming;
                          }
                        }(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "${formatDateShort(event.startDate, langCode)} - ${formatDateShort(event.endDate, langCode)}",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${AppLocalizations.of(context)!.adminVaariTargetDistancePrefix}${formatDistanceLocalized(event.targetDistance, langCode)} ${localizedDistanceUnitLabel(event.distanceUnit, langCode)}",
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
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

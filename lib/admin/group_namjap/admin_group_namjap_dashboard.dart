import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/group_namjap_event.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:gajanan_maharaj_sevekari/widgets/themed_icon.dart';
import 'package:gajanan_maharaj_sevekari/utils/marathi_utils.dart';
import 'package:gajanan_maharaj_sevekari/admin/widgets/admin_stats_widgets.dart';
import 'package:gajanan_maharaj_sevekari/utils/date_time_utils.dart';

import 'package:gajanan_maharaj_sevekari/models/admin_user.dart';

class AdminGroupNamjapDashboard extends StatefulWidget {
  final AdminUser adminUser;
  const AdminGroupNamjapDashboard({super.key, required this.adminUser});

  @override
  State<AdminGroupNamjapDashboard> createState() =>
      _AdminGroupNamjapDashboardState();
}

class _AdminGroupNamjapDashboardState extends State<AdminGroupNamjapDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Stream<QuerySnapshot> _eventsStream;

  @override
  void initState() {
    super.initState();
    // Cache stream in initState instead of build to prevent flickering natively
    _eventsStream = _firestore.collection('group_namjap_events').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.groupNamjapDashboardTitle),
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
                    'Error loading data',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.appColors.secondaryText,
                    ),
                  ),
                ],
              ),
            );
          }

          final allDocs = snapshot.data?.docs ?? [];
          final allEvents = allDocs
              .map(
                (doc) => GroupNamjapEvent.fromMap(
                  doc.id,
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList();
          final nowYear = DateTime.now().year;

          final activeEvents =
              allEvents
                  .where(
                    (e) => e.status == 'ongoing' && e.startDate.year == nowYear,
                  )
                  .toList()
                ..sort((a, b) => b.startDate.compareTo(a.startDate));

          final upcomingEvents =
              allEvents
                  .where(
                    (e) =>
                        (e.status == 'upcoming' || e.status == 'enrolling') &&
                        e.startDate.year == nowYear,
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
                        context,
                        theme,
                        localizations.groupNamjapRecentlyCompleted,
                        showViewAll: true,
                        onViewAll: () => Navigator.pushNamed(
                          context,
                          Routes.adminGroupNamjapList,
                          arguments: 'completed',
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (completedEvents.isNotEmpty)
                        _UpcomingCard(event: completedEvents.first)
                      else
                        Text(
                          localizations.groupNamjapNoCompleted,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.appColors.secondaryText,
                          ),
                        ),
                      const SizedBox(height: 32),
                      _buildSectionHeader(
                        context,
                        theme,
                        localizations.groupNamjapOngoing,
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
                      localizations.groupNamjapNoOngoing,
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
                      (context, index) =>
                          _OngoingCard(event: activeEvents[index]),
                      childCount: activeEvents.length > 5
                          ? 5
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
                      context,
                      theme,
                      localizations.groupNamjapUpcoming,
                      showViewAll: true,
                      onViewAll: () => Navigator.pushNamed(
                        context,
                        Routes.adminGroupNamjapList,
                        arguments: 'upcoming',
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(
                    child: _UpcomingCard(event: upcomingEvents.first),
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
              SliverToBoxAdapter(
                child: Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      Routes.adminCreateGroupNamjap,
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
                    child: Text(localizations.createGroupNamjapTitle),
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
              label: localizations.groupNamjapOngoing.toUpperCase(),
              value: formatNumberLocalized(active, langCode, pad: false),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: StatCard(
              label: localizations.groupNamjapCompleted,
              value: formatNumberLocalized(completed, langCode, pad: false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
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
              AppLocalizations.of(context)!.viewAllLabel,
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
  final GroupNamjapEvent event;
  const _OngoingCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final title = isEnglish ? event.nameEn : event.nameMr;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.pushNamed(
          context,
          Routes.adminGroupNamjapDetail,
          arguments: event.id,
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
                  Icons.group,
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
                      "${formatDateShort(event.startDate, Localizations.localeOf(context).languageCode)} - ${formatDateShort(event.endDate, Localizations.localeOf(context).languageCode)}",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${AppLocalizations.of(context)!.groupNamjapTargetPrefix}${formatNumberLocalized(event.targetCount, Localizations.localeOf(context).languageCode, pad: false)}",
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
  final GroupNamjapEvent event;
  const _UpcomingCard({required this.event});

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
            Routes.adminGroupNamjapDetail,
            arguments: event.id,
          ),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEnglish ? event.nameEn : event.nameMr,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${formatDateShort(event.startDate, langCode)} - ${formatDateShort(event.endDate, langCode)}",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.appColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${AppLocalizations.of(context)!.groupNamjapTargetPrefix}${formatNumberLocalized(event.targetCount, langCode, pad: false)}",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
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

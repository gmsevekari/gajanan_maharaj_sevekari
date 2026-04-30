import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/utils/locale_extensions.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/admin/parayan_admin_detail_screen.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/admin_user.dart';
import 'package:gajanan_maharaj_sevekari/models/parayan_event.dart';
import 'package:gajanan_maharaj_sevekari/parayan/parayan_type.dart';
import 'package:gajanan_maharaj_sevekari/providers/parayan_service.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:intl/intl.dart';
import 'package:gajanan_maharaj_sevekari/widgets/themed_icon.dart';

class ParayanCoordinationDashboard extends StatefulWidget {
  final AdminUser? adminUser;

  const ParayanCoordinationDashboard({super.key, this.adminUser});

  @override
  State<ParayanCoordinationDashboard> createState() =>
      _ParayanCoordinationDashboardState();
}

class _ParayanCoordinationDashboardState
    extends State<ParayanCoordinationDashboard> {
  final ParayanService _parayanService = ParayanService();
  late Stream<List<ParayanEvent>> _eventsStream;

  @override
  void initState() {
    super.initState();
    _eventsStream =
        _parayanService.getAllEvents(widget.adminUser!.groupId!);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.parayanCoordinationModuleTitle),
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
      body: StreamBuilder<List<ParayanEvent>>(
        stream: _eventsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            // Log to console as requested
            debugPrint('Parayan Dashboard Error: ${snapshot.error}');

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
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
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.appColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => setState(() {
                        // Re-initialize stream on retry
                        _eventsStream = _parayanService.getAllEvents(
                          widget.adminUser!.groupId!,
                        );
                      }),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final nowYear = DateTime.now().year;
          final allEvents = snapshot.data ?? [];

          final activeEvents = allEvents
              .where(
                (e) =>
                    (e.status == 'enrolling' ||
                        e.status == 'allocated' ||
                        e.status == 'ongoing') &&
                    e.startDate.year == nowYear,
              )
              .toList();

          final activeCount = activeEvents.length;

          final completedEvents =
              allEvents
                  .where((e) => e.status == 'completed')
                  .toList()
                ..sort((a, b) => b.endDate.compareTo(a.endDate));

          final completedCount = completedEvents.length;

          // Upcoming sorted by date
          final upcomingEvents =
              allEvents.where((e) => e.status == 'upcoming').toList()
                ..sort((a, b) => a.startDate.compareTo(b.startDate));

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 24),
                      _buildStatsRow(
                        context,
                        theme,
                        activeCount,
                        completedCount,
                      ),
                      _buildSectionHeader(
                        context,
                        theme,
                        localizations.recentlyCompletedParayanLabel,
                        showViewAll: true,
                        onViewAll: () => Navigator.pushNamed(
                          context,
                          Routes.adminParayanList,
                          arguments: {
                            'title':
                                localizations.recentlyCompletedParayanLabel,
                            'statusFilter': 'completed',
                            'groupId': widget.adminUser?.groupId,
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (completedEvents.isNotEmpty)
                        _UpcomingCard(event: completedEvents.first)
                      else
                        Text(
                          localizations.noCompletedParayans,
                          style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.appColors.secondaryText,
                          ),
                        ),
                      const SizedBox(height: 32),
                      _buildSectionHeader(
                        context,
                        theme,
                        localizations.ongoingParayansLabel,
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
                      localizations.noActiveParayans,
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
                      childCount: activeEvents.length,
                    ),
                  ),
                ),
              if (upcomingEvents.isNotEmpty) ...[
                SliverPadding(
                  padding: const EdgeInsets.only(left: 16, top: 32, bottom: 12),
                  sliver: SliverToBoxAdapter(
                    child: _buildSectionHeader(
                      context,
                      theme,
                      localizations.nextParayanLabel,
                      showViewAll: true,
                      onViewAll: () => Navigator.pushNamed(
                        context,
                        Routes.adminParayanList,
                        arguments: {
                          'title': localizations.nextParayanLabel,
                          'statusFilter': 'upcoming',
                          'groupId': widget.adminUser?.groupId,
                        },
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
                      Routes.adminCreateParayan,
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
                    child: Text(localizations.createParayanTitle),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
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
  ) {
    final localizations = AppLocalizations.of(context)!;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _StatCard(
              label: localizations.activeLabel.toUpperCase(),
              value: active.toString(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _StatCard(
              label: localizations.completedLabel.toUpperCase(),
              value: completed.toString(),
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
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
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

// ── Extracted private widgets ────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      // Inherits AppTheme.cardTheme
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 1.2,
                color: theme.appColors.secondaryText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OngoingCard extends StatelessWidget {
  final ParayanEvent event;

  const _OngoingCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: double.infinity,
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
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: theme.colorScheme.primary.withValues(
                    alpha: 0.1,
                  ),
                  child: Icon(
                    Icons.menu_book,
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
                        Localizations.localeOf(context).useMarathiContent
                            ? event.titleMr
                            : event.titleEn,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getDateRange(context, event),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getParayanTypeText(context, event.type),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.chevron_right,
                  color: theme.appColors.divider,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  final ParayanEvent event;

  const _UpcomingCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: double.infinity,
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
                Text(
                  Localizations.localeOf(context).useMarathiContent
                      ? event.titleMr
                      : event.titleEn,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _getDateRange(context, event),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _getParayanTypeText(context, event.type),
                  style: theme.textTheme.labelSmall?.copyWith(
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

String _formatNumber(BuildContext context, int number, {bool pad = false}) {
  String numStr = pad ? number.toString().padLeft(2, '0') : number.toString();
  final isMarathi = Localizations.localeOf(context).useMarathiContent;
  if (!isMarathi) return numStr;

  const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  const marathi = ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'];
  for (int i = 0; i < english.length; i++) {
    numStr = numStr.replaceAll(english[i], marathi[i]);
  }
  return numStr;
}

String _getDateRange(BuildContext context, ParayanEvent event) {
  final locale = Localizations.localeOf(context).languageCode;
  final startDay = _formatNumber(context, event.startDate.day);
  final startMonth = DateFormat.MMMM(locale).format(event.startDate);

  if (event.type == ParayanType.oneDay) {
    return '$startDay $startMonth';
  }

  final endDay = _formatNumber(context, event.endDate.day);
  final endMonth = DateFormat.MMMM(locale).format(event.endDate);

  if (startMonth == endMonth) {
    return '$startDay - $endDay $startMonth';
  }
  return '$startDay $startMonth - $endDay $endMonth';
}

String _getParayanTypeText(BuildContext context, ParayanType type) {
  final l10n = AppLocalizations.of(context)!;
  final isMarathi = Localizations.localeOf(context).useMarathiContent;

  String text;
  switch (type) {
    case ParayanType.oneDay:
      text = l10n.oneDayParayan;
      break;
    case ParayanType.threeDay:
      text = l10n.threeDayParayan;
      break;
    case ParayanType.guruPushya:
      text = l10n.guruPushyaParayan;
      break;
  }

  return isMarathi ? text : text.toUpperCase();
}

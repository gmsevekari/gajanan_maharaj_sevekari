import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/event_calendar/event_calendar_screen.dart';
import 'package:gajanan_maharaj_sevekari/notifications/notification_manager.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/utils/date_time_utils.dart';
import 'package:gajanan_maharaj_sevekari/parayan/utils/parayan_extensions.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gajanan_maharaj_sevekari/widgets/festival_launch_animation.dart';
import 'package:gajanan_maharaj_sevekari/shared/global_search_delegate.dart';
import 'package:gajanan_maharaj_sevekari/models/parayan_event.dart';
import 'package:gajanan_maharaj_sevekari/providers/festival_provider.dart';
import 'package:gajanan_maharaj_sevekari/settings/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:gajanan_maharaj_sevekari/shared/update_dialog.dart';
import 'package:gajanan_maharaj_sevekari/utils/update_service.dart';
import 'package:gajanan_maharaj_sevekari/widgets/themed_icon.dart';
import 'package:gajanan_maharaj_sevekari/widgets/themed_loading_indicator.dart';
import 'package:gajanan_maharaj_sevekari/widgets/festival_tap_effect.dart';
import 'package:gajanan_maharaj_sevekari/models/event.dart';
import 'package:gajanan_maharaj_sevekari/providers/event_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/group_selection_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/app_config_provider.dart';
import 'package:gajanan_maharaj_sevekari/models/app_config.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  String? _lastReadTimestamp;
  bool _showFestivalAnimation = false;
  FestivalAnimationType _activeAnimationType = FestivalAnimationType.fireworks;
  String _animationMessage = '';

  late PageController _carouselPageController;
  double _currentCarouselPage = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUnreadStatus();
    _carouselPageController = PageController();
    _carouselPageController.addListener(() {
      if (mounted) {
        setState(() {
          _currentCarouselPage = _carouselPageController.page ?? 0;
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      // 1. Notification Permissions
      if (!kIsWeb) {
        await NotificationManager.requestPermissions(context);
      }

      if (!mounted) return;

      // Festival Launch Check
      await _checkFestivalLaunch();

      if (!mounted) return;

      // 2. App Update Check (Both Forced and Recommended)
      if (!kIsWeb && mounted) {
        final updateResult = await UpdateService().checkForUpdate();
        if (updateResult.type != UpdateType.none && mounted) {
          UpdateDialog.show(context, updateResult);
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _carouselPageController.dispose();
    super.dispose();
  }

  Future<void> _checkFestivalLaunch() async {
    final festivalProvider = Provider.of<FestivalProvider>(
      context,
      listen: false,
    );
    final activeFestival = festivalProvider.activeFestival;
    if (activeFestival == null) return;

    final localizations = AppLocalizations.of(context);
    if (localizations == null) return;
    final prefs = await SharedPreferences.getInstance();

    if (activeFestival.id == 'diwali') {
      final hasLaunched = prefs.getBool('has_launched_diwali_2026') ?? false;
      if (!hasLaunched) {
        setState(() {
          _showFestivalAnimation = true;
          _activeAnimationType = FestivalAnimationType.fireworks;
          _animationMessage = localizations.chantHappyDiwali;
        });
        await prefs.setBool('has_launched_diwali_2026', true);
      }
    } else if (activeFestival.id == 'ganesh_chaturthi') {
      final hasLaunched =
          prefs.getBool('has_launched_ganesh_chaturthi_2026') ?? false;
      if (!hasLaunched) {
        setState(() {
          _showFestivalAnimation = true;
          _activeAnimationType = FestivalAnimationType.flowerPetals;
          _animationMessage = localizations.chantGanpatiBappa;
        });
        await prefs.setBool('has_launched_ganesh_chaturthi_2026', true);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadUnreadStatus();
    }
  }

  Future<void> _loadUnreadStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lastReadTimestamp = prefs.getString('last_read_notification_timestamp');
    });
  }

  void _launchAppStore() async {
    const appleId = '6759313202';
    const androidPackageName = 'com.gajanan.maharaj.sevekari';

    final url = Theme.of(context).platform == TargetPlatform.iOS
        ? 'https://apps.apple.com/app/id$appleId'
        : 'https://play.google.com/store/apps/details?id=$androidPackageName';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (localizations == null) return const SizedBox.shrink();

    final themeProvider = Provider.of<ThemeProvider>(context);
    final festivalProvider = Provider.of<FestivalProvider>(context);
    final activeFestival = festivalProvider.activeFestival;

    // Check if the current theme selection matches the festival's preset
    final isFestiveThemeMode =
        activeFestival != null &&
        themeProvider.themePreset == activeFestival.themePreset;

    final isGaneshotsav =
        isFestiveThemeMode && activeFestival.id == 'ganesh_chaturthi';
    final isDiwali = isFestiveThemeMode && activeFestival.id == 'diwali';

    if (festivalProvider.shouldTriggerAnimation && !_showFestivalAnimation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerAnimationFromProvider(festivalProvider);
      });
    }

    final List<Widget> cards = [];

    cards.add(
      _buildIconGridItem(
        context: context,
        title: localizations.nityopasanaTitle,
        imagePath: isGaneshotsav
            ? 'resources/images/festive_icons/ganesh_chaturthi/nityopasana.png'
            : isDiwali
            ? 'resources/images/festive_icons/diwali/nityopasana.png'
            : 'resources/images/icon/Nityopasana.png',
        imageSize: (isGaneshotsav || isDiwali) ? 84.0 : 100.0,
        onTap: () =>
            Navigator.pushNamed(context, Routes.nityopasanaConsolidated),
      ),
    );
    cards.add(
      _buildIconGridItem(
        context: context,
        title: localizations.namjapTitle,
        imagePath: isGaneshotsav
            ? 'resources/images/festive_icons/ganesh_chaturthi/naamjap.png'
            : isDiwali
            ? 'resources/images/festive_icons/diwali/naamjap.png'
            : 'resources/images/icon/Rudraksha_Mala.png',
        imageSize: (isGaneshotsav || isDiwali) ? 84.0 : 100.0,
        onTap: () => Navigator.pushNamed(context, Routes.naamjap),
      ),
    );
    cards.add(
      _buildIconGridItem(
        context: context,
        title: localizations.parayanTitle,
        imagePath: isGaneshotsav
            ? 'resources/images/festive_icons/ganesh_chaturthi/parayan.png'
            : isDiwali
            ? 'resources/images/festive_icons/diwali/parayan.png'
            : 'resources/images/icon/Parayan.png',
        imageSize: (isGaneshotsav || isDiwali) ? 84.0 : 100.0,
        onTap: () => Navigator.pushNamed(context, Routes.gajananMaharajGroups),
      ),
    );
    cards.add(
      _buildIconGridItem(
        context: context,
        title: localizations.calendarTitle,
        customWidget: (isGaneshotsav || isDiwali)
            ? null
            : const ThemedIcon(LogicalIcon.calendar, size: 60.0),
        imagePath: isGaneshotsav
            ? 'resources/images/festive_icons/ganesh_chaturthi/calendar.png'
            : isDiwali
            ? 'resources/images/festive_icons/diwali/calendar.png'
            : null,
        imageSize: (isGaneshotsav || isDiwali) ? 84.0 : 100.0,
        onTap: () => Navigator.pushNamed(context, Routes.calendar),
      ),
    );

    final scaffoldBase = Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('resources/images/logo/Home_Page_Logo.png'),
        ),
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(localizations.appName),
        ),
        actions: [
          IconButton(
            icon: const ThemedIcon(LogicalIcon.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: GlobalSearchDelegate(
                  hintText: localizations.searchHint,
                ),
              );
            },
          ),
          StreamBuilder<QuerySnapshot>(
            stream: Provider.of<FirebaseFirestore>(context, listen: false)
                .collection('notifications')
                .orderBy('timestamp', descending: true)
                .limit(1)
                .snapshots(),
            builder: (context, snapshot) {
              bool hasUnread = false;
              if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                final latestDoc =
                    snapshot.data!.docs.first.data() as Map<String, dynamic>;
                final latestTimestampStr = latestDoc['timestamp'] as String?;

                if (latestTimestampStr != null) {
                  if (_lastReadTimestamp == null) {
                    hasUnread = true;
                  } else {
                    try {
                      final latestTime = DateTime.parse(latestTimestampStr);
                      final lastReadTime = DateTime.parse(_lastReadTimestamp!);
                      if (latestTime.isAfter(lastReadTime)) {
                        hasUnread = true;
                      }
                    } catch (e) {
                      // ignore parse errors
                    }
                  }
                }
              }

              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const ThemedIcon(LogicalIcon.notifications),
                    onPressed: () async {
                      await Navigator.pushNamed(
                        context,
                        Routes.userNotifications,
                      );
                      _loadUnreadStatus(); // Refresh when returning
                    },
                  ),
                  if (hasUnread)
                    Positioned(
                      right: 12,
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const ThemedIcon(LogicalIcon.settings),
            onPressed: () => Navigator.pushNamed(context, Routes.settings),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _buildUpcomingEventCard(context, localizations),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      alignment: WrapAlignment.center,
                      children: cards,
                    ),
                  ),
                  if (kIsWeb) _buildDownloadBanner(context, localizations),
                  const SizedBox(
                    height: 80,
                  ), // Extra space to prevent bottom cards from cutting off on zoomed displays
                ],
              ),
            ),
          ),
          if (isGaneshotsav) const MouseMarquee(),

          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  (isGaneshotsav || isDiwali)
                      ? Image.asset(
                          isDiwali
                              ? 'resources/images/festive_icons/diwali/list.png'
                              : 'resources/images/festive_icons/ganesh_chaturthi/list.png',
                          width: 24,
                          height: 24,
                        )
                      : Icon(
                          Icons.spa,
                          color: theme.appColors.primarySwatch[300],
                          size: 20,
                        ),
                  const SizedBox(width: 12),
                  Text(
                    isDiwali
                        ? localizations.chantHappyDiwali
                        : isGaneshotsav
                        ? localizations.chantGanpatiBappa
                        : localizations.gajananChant,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: theme.appColors.primarySwatch[600],
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  (isGaneshotsav || isDiwali)
                      ? Image.asset(
                          isDiwali
                              ? 'resources/images/festive_icons/diwali/list.png'
                              : 'resources/images/festive_icons/ganesh_chaturthi/list.png',
                          width: 24,
                          height: 24,
                        )
                      : Icon(
                          Icons.spa,
                          color: theme.appColors.primarySwatch[300],
                          size: 20,
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (_showFestivalAnimation) {
      return Stack(
        children: [
          scaffoldBase,
          FestivalLaunchAnimation(
            message: _animationMessage,
            type: _activeAnimationType,
            onComplete: () {
              if (mounted) {
                setState(() => _showFestivalAnimation = false);
              }
            },
          ),
        ],
      );
    }

    return scaffoldBase;
  }

  void _triggerAnimationFromProvider(FestivalProvider provider) {
    if (!mounted) return;
    final activeFestival = provider.activeFestival;
    if (activeFestival == null) {
      provider.resetAnimationTrigger();
      return;
    }

    final localizations = AppLocalizations.of(context);
    if (localizations == null) return;

    setState(() {
      _showFestivalAnimation = true;
      _activeAnimationType = activeFestival.id == 'diwali'
          ? FestivalAnimationType.fireworks
          : FestivalAnimationType.flowerPetals;
      _animationMessage = activeFestival.id == 'diwali'
          ? localizations.chantHappyDiwali
          : localizations.chantGanpatiBappa;
    });
    provider.resetAnimationTrigger();
  }

  Widget _buildDownloadBanner(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: theme.cardTheme.shadowColor!,
            offset: const Offset(0, 4),
            blurRadius: 0,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: theme.cardTheme.color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
          side: BorderSide(color: theme.appColors.primarySwatch, width: 1),
        ),
        child: InkWell(
          onTap: _launchAppStore,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.phone_android,
                    color: theme.colorScheme.onPrimary,
                    size: 24.0,
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations.downloadAppTitle,
                        style: TextStyle(
                          color: theme.appColors.primarySwatch[600],
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        localizations.downloadAppSubtitle,
                        style: TextStyle(
                          color: theme.appColors.primarySwatch[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _launchAppStore,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    localizations.downloadAppButton,
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingEventCard(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    final eventProvider = context.watch<EventProvider>();
    final groupProvider = context.watch<GroupSelectionProvider>();
    final configProvider = context.watch<AppConfigProvider>();
    final selectedGroupIds = groupProvider.selectedGroupIds;

    if (selectedGroupIds.isEmpty) {
      return const SizedBox.shrink();
    }

    if (eventProvider.isLoading) {
      return Container(
        height: 200,
        margin: const EdgeInsets.all(8.0),
        child: const Center(child: ThemedLoadingIndicator()),
      );
    }

    // Filter out groups that have no upcoming events
    final activeGroups = selectedGroupIds.where((groupId) {
      final events = eventProvider.groupedEvents[groupId];
      return events != null && !events.isEmpty;
    }).toList();

    if (activeGroups.isEmpty) {
      return _buildEmptyStateCard(context, localizations);
    }

    // Calculate individual heights for each group
    final List<double> groupHeights = activeGroups.map((groupId) {
      final events = eventProvider.groupedEvents[groupId]!;
      int count = 0;
      if (events.weeklyPooja != null) count++;
      if (events.specialEvent != null) count++;
      if (events.parayan != null) count++;

      double height = 160.0; // Base for 1 event
      if (count == 2) height = 220.0;
      if (count == 3) height = 280.0;

      // Add space for the group header if carousel is active
      if (activeGroups.length > 1) height += 24.0;
      return height;
    }).toList();

    // Interpolate height based on the current scroll position
    double interpolatedHeight;
    if (activeGroups.length <= 1) {
      interpolatedHeight = groupHeights.isNotEmpty ? groupHeights.first : 160.0;
    } else {
      final int index = _currentCarouselPage.floor().clamp(0, groupHeights.length - 1);
      final double fraction = _currentCarouselPage - index;

      final h1 = groupHeights[index];
      final h2 = (index + 1 < groupHeights.length) ? groupHeights[index + 1] : h1;

      interpolatedHeight = h1 + (h2 - h1) * fraction;
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final double viewportFraction = (screenWidth - 24) / screenWidth;
    final double targetFraction = activeGroups.length > 1 ? viewportFraction : 1.0;

    // Recreate controller if the fraction needs to change (e.g. 1 group vs multiple)
    if (_carouselPageController.viewportFraction != targetFraction) {
      final lastPage = _currentCarouselPage;
      _carouselPageController.dispose();
      _carouselPageController = PageController(
        initialPage: lastPage.round(),
        viewportFraction: targetFraction,
      );
      _carouselPageController.addListener(() {
        if (mounted) {
          setState(() {
            _currentCarouselPage = _carouselPageController.page ?? 0;
          });
        }
      });
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: interpolatedHeight,
          child: PageView.builder(
            itemCount: activeGroups.length,
            controller: _carouselPageController,
            itemBuilder: (context, index) {
              final groupId = activeGroups[index];
              final events = eventProvider.groupedEvents[groupId]!;
              final allGroups =
                  configProvider.appConfig?.gajananMaharajGroups ?? [];
              final group = allGroups.firstWhere(
                (g) => g.id == groupId,
                orElse: () => GajananMaharajGroup(
                  id: groupId,
                  nameEn: groupId,
                  nameMr: groupId,
                ),
              );

              return _buildGroupEventPage(
                context,
                localizations,
                group,
                events,
                activeGroups.length > 1,
              );
            },
          ),
        ),
        if (activeGroups.length > 1)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.swipe,
                  size: 14,
                  color: Theme.of(context).appColors.primarySwatch[400],
                ),
                const SizedBox(width: 4),
                Text(
                  localizations.swipeHint,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).appColors.primarySwatch[400],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyStateCard(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: theme.cardTheme.shadowColor ?? Colors.black12,
            offset: const Offset(0, 4),
            blurRadius: 0,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: theme.cardTheme.color,
        shape: theme.cardTheme.shape,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                localizations.upcomingEvent,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.appColors.primarySwatch[600],
                ),
              ),
              const SizedBox(height: 12.0),
              Text(
                localizations.eventOnDate,
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.appColors.primarySwatch[400]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupEventPage(
    BuildContext context,
    AppLocalizations localizations,
    GajananMaharajGroup group,
    GroupEvents events,
    bool showHeader,
  ) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final groupName = locale == 'mr' ? group.nameMr : group.nameEn;

    final activeFestival = context.watch<FestivalProvider>().activeFestival;
    final themeProvider = context.watch<ThemeProvider>();
    final isFestiveTheme =
        activeFestival != null &&
        themeProvider.themePreset == activeFestival.themePreset;

    final isGaneshotsav =
        isFestiveTheme && activeFestival.id == 'ganesh_chaturthi';
    final isDiwali = isFestiveTheme && activeFestival.id == 'diwali';

    final cardContent = Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: theme.cardTheme.color,
      shape: theme.cardTheme.shape,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showHeader) ...[
                Text(
                  groupName,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.appColors.primarySwatch[400],
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                localizations.upcomingEvent,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.appColors.primarySwatch[600],
                ),
              ),
              const SizedBox(height: 4.0),
              Divider(
                color: theme.appColors.primarySwatch.withValues(alpha: 0.2),
                height: 8.0,
              ),
              if (events.weeklyPooja != null)
                _buildEventRow(
                  context,
                  events.weeklyPooja!,
                  Icons.event_repeat,
                  theme.appColors.primarySwatch,
                  localizations.weeklyPooja,
                  theme,
                ),
              if (events.weeklyPooja != null && events.specialEvent != null)
                Divider(
                  color: theme.appColors.primarySwatch.withValues(alpha: 0.2),
                  height: 8.0,
                ),
              if (events.specialEvent != null)
                _buildEventRow(
                  context,
                  events.specialEvent!,
                  Icons.celebration,
                  theme.appColors.primarySwatch,
                  localizations.specialEvents,
                  theme,
                ),
              if (events.parayan != null) ...[
                if (events.weeklyPooja != null || events.specialEvent != null)
                  Divider(
                    color: theme.appColors.primarySwatch.withValues(alpha: 0.2),
                    height: 8.0,
                  ),
                _buildParayanRow(
                  context,
                  events.parayan!,
                  theme,
                  localizations,
                ),
              ],
            ],
          ),
        ),
      ),
    );

    Widget decoratedCard;
    if (!isGaneshotsav && !isDiwali) {
      decoratedCard = Container(
        margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: theme.cardTheme.shadowColor ?? Colors.black12,
              offset: const Offset(0, 4),
              blurRadius: 0,
              spreadRadius: 0,
            ),
          ],
        ),
        child: cardContent,
      );
    } else {
      decoratedCard = Container(
        margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: isDiwali
                ? const Color(0xFFE52B7B).withValues(alpha: 0.8)
                : theme.appColors.primarySwatch.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.cardTheme.shadowColor ?? Colors.black12,
              offset: const Offset(0, 4),
              blurRadius: 0,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.only(
                top: isDiwali ? 36.0 : 8.0,
                left: 8.0,
                right: 8.0,
                bottom: 8.0,
              ),
              child: cardContent,
            ),
            if (!isDiwali)
              Positioned(
                top: 0,
                left: 0,
                child: Image.asset(
                  'resources/images/festive_icons/ganesh_chaturthi/hibiscus.png',
                  width: 32,
                  height: 32,
                ),
              ),
            if (!isDiwali)
              Positioned(
                top: 0,
                right: 0,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationY(3.14159),
                  child: Image.asset(
                    'resources/images/festive_icons/ganesh_chaturthi/hibiscus.png',
                    width: 32,
                    height: 32,
                  ),
                ),
              ),
            if (isDiwali)
              Positioned(
                top: -6,
                left: 0,
                right: 0,
                child: Image.asset(
                  'resources/images/festive_icons/diwali/toran_final_flat.png',
                  height: 48,
                  alignment: Alignment.topCenter,
                  fit: BoxFit.fitWidth,
                ),
              ),
            if (!isDiwali)
              Positioned(
                bottom: 0,
                left: 0,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationX(3.14159),
                  child: Image.asset(
                    'resources/images/festive_icons/ganesh_chaturthi/hibiscus.png',
                    width: 32,
                    height: 32,
                  ),
                ),
              ),
            if (!isDiwali)
              Positioned(
                bottom: 0,
                right: 0,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationZ(3.14159),
                  child: Image.asset(
                    'resources/images/festive_icons/ganesh_chaturthi/hibiscus.png',
                    width: 32,
                    height: 32,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return decoratedCard;
  }

  Widget _buildEventRow(
    BuildContext context,
    Event event,
    IconData icon,
    Color iconColor,
    String eventTypeLabel,
    ThemeData theme,
  ) {
    final activeFestival = context.watch<FestivalProvider>().activeFestival;
    final themeProvider = context.watch<ThemeProvider>();

    final isFestiveTheme =
        activeFestival != null &&
        themeProvider.themePreset == activeFestival.themePreset;

    final isGaneshotsav =
        isFestiveTheme && activeFestival.id == 'ganesh_chaturthi';
    final isDiwali = isFestiveTheme && activeFestival.id == 'diwali';
    final locale = Localizations.localeOf(context).languageCode;
    final eventTitle = locale == 'mr' ? event.title_mr : event.title_en;
    final eventDate = event.start_time.toDate();
    final eventDateString = formatDateWithDay(eventDate, locale);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventCalendarScreen(initialDate: eventDate),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: (isGaneshotsav || isDiwali)
                  ? Image.asset(
                      isDiwali
                          ? 'resources/images/festive_icons/diwali/crackers.png'
                          : 'resources/images/festive_icons/ganesh_chaturthi/modak.png',
                      width: 36,
                      height: 36,
                      color:
                          iconColor, // Optional tint if desired, but we want full color
                      colorBlendMode: BlendMode.dst,
                    )
                  : Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eventTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.appColors.primarySwatch[600],
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    eventDateString,
                    style: TextStyle(
                      color: theme.appColors.primarySwatch[600],
                      fontSize: 13.0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8.0),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 4.0,
              ),
              decoration: BoxDecoration(
                color: iconColor,
                borderRadius: BorderRadius.circular(6.0),
              ),
              child: Text(
                eventTypeLabel.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParayanRow(
    BuildContext context,
    ParayanEvent event,
    ThemeData theme,
    AppLocalizations localizations,
  ) {
    final activeFestival = context.watch<FestivalProvider>().activeFestival;
    final themeProvider = context.watch<ThemeProvider>();

    final isFestiveTheme =
        activeFestival != null &&
        themeProvider.themePreset == activeFestival.themePreset;

    final isGaneshotsav =
        isFestiveTheme && activeFestival.id == 'ganesh_chaturthi';
    final isDiwali = isFestiveTheme && activeFestival.id == 'diwali';
    final locale = Localizations.localeOf(context).languageCode;
    final title = locale == 'mr' ? event.titleMr : event.titleEn;
    final dateRange = event.getSmartDate(locale, includeTime: false);

    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, Routes.parayanDetail, arguments: event);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: theme.appColors.primarySwatch.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: (isGaneshotsav || isDiwali)
                  ? Image.asset(
                      isDiwali
                          ? 'resources/images/festive_icons/diwali/crackers.png'
                          : 'resources/images/festive_icons/ganesh_chaturthi/modak.png',
                      width: 36,
                      height: 36,
                    )
                  : Icon(Icons.menu_book, color: theme.appColors.primarySwatch),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.appColors.primarySwatch[600],
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    dateRange,
                    style: TextStyle(
                      color: theme.appColors.primarySwatch[600],
                      fontSize: 13.0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8.0),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 4.0,
              ),
              decoration: BoxDecoration(
                color: theme.appColors.primarySwatch,
                borderRadius: BorderRadius.circular(6.0),
              ),
              child: Text(
                localizations.parayanTitle.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconGridItem({
    required BuildContext context,
    required String title,
    IconData? icon,
    Widget? customWidget,
    String? imagePath,
    double imageSize = 40.0,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final size = imageSize;

    return SizedBox(
      width: (MediaQuery.of(context).size.width - 40) / 2,
      child: AspectRatio(
        aspectRatio: 1.4,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: [
              BoxShadow(
                color: theme.cardTheme.shadowColor!,
                offset: const Offset(0, 4),
                blurRadius: 0,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            color: theme.cardTheme.color,
            shape: theme.cardTheme.shape,
            child: FestivalTapEffect(
              child: InkWell(
                onTap: onTap,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 8),
                    Flexible(
                      child:
                          customWidget ??
                          (imagePath != null
                              ? Image.asset(
                                  imagePath,
                                  height: size,
                                  width: size,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(
                                        Icons.error_outline,
                                        size: size,
                                        color: theme.iconTheme.color,
                                      ),
                                )
                              : Icon(
                                  icon,
                                  size: size,
                                  color: theme.iconTheme.color,
                                )),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.appColors.primarySwatch[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MouseMarquee extends StatefulWidget {
  const MouseMarquee({super.key});

  @override
  State<MouseMarquee> createState() => _MouseMarqueeState();
}

class _MouseMarqueeState extends State<MouseMarquee>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final mouseWidth = screenWidth * 0.25;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Precise distance to ensure that as the trail leaves (x = screenWidth + 1.6*mw),
        // the lead immediately enters (x = -mw) on the next loop iteration.
        final totalDistance = screenWidth + (mouseWidth * 2.6);
        final xPos = -mouseWidth + (_controller.value * totalDistance);

        Widget buildMouse(int index) {
          // Phase shift based on the index so their feet hit the ground at different times
          final phase = index * (math.pi / 2.5);
          final bounce =
              -5.0 *
              (math.sin((_controller.value * math.pi * 20) + phase).abs());
          final rotation =
              math.sin((_controller.value * math.pi * 40) + phase) * 0.02;

          return Positioned(
            left:
                xPos -
                (index *
                    (mouseWidth *
                        0.8)), // Compress the distance so they overlap/follow closely
            top: bounce,
            child: Transform.rotate(
              angle: rotation,
              alignment: Alignment.centerRight,
              child: Image.asset(
                'resources/images/festive_icons/ganesh_chaturthi/mouse_garland.png',
                width: mouseWidth,
                height: 60,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            ),
          );
        }

        return SizedBox(
          height: 60,
          width: screenWidth,
          child: Stack(
            clipBehavior: Clip.none,
            // Build in reverse order so the front mouse (index 0) draws on top of the follower (index 1)
            children: [buildMouse(2), buildMouse(1), buildMouse(0)],
          ),
        );
      },
    );
  }
}

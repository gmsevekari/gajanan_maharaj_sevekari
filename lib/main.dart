import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/about_maharaj/about_maharaj_screen.dart';
import 'package:gajanan_maharaj_sevekari/aarti/aarti_screen.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/donations/donations_screen.dart';
import 'package:gajanan_maharaj_sevekari/event_calendar/event_calendar_screen.dart';
import 'package:gajanan_maharaj_sevekari/firebase_options.dart';
import 'package:gajanan_maharaj_sevekari/gallery/gallery_screen.dart';
import 'package:gajanan_maharaj_sevekari/home/home_screen.dart';
import 'package:gajanan_maharaj_sevekari/home/nityopasana_consolidated_screen.dart';
import 'package:gajanan_maharaj_sevekari/models/admin_user.dart';
import 'package:gajanan_maharaj_sevekari/models/app_config.dart';
import 'package:gajanan_maharaj_sevekari/namavali/namavali_screen.dart';
import 'package:gajanan_maharaj_sevekari/notifications/notification_manager.dart';
import 'package:gajanan_maharaj_sevekari/parayan/parayan_list_screen.dart';
import 'package:gajanan_maharaj_sevekari/shared/gajanan_maharaj_group_screen.dart';
import 'package:gajanan_maharaj_sevekari/parayan/parayan_detail_screen.dart';
import 'package:gajanan_maharaj_sevekari/parayan/preallocated_parayan_detail_screen.dart';
import 'package:gajanan_maharaj_sevekari/models/parayan_event.dart';
import 'package:gajanan_maharaj_sevekari/shared/content_detail_screen.dart';
import 'package:gajanan_maharaj_sevekari/shared/content_list_screen.dart';
import 'package:gajanan_maharaj_sevekari/providers/app_config_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/group_selection_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/playlist_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/group_namjap_service.dart';
import 'package:gajanan_maharaj_sevekari/providers/group_namjap_provider.dart';
import 'package:gajanan_maharaj_sevekari/sankalp/sankalp_screen.dart';
import 'package:gajanan_maharaj_sevekari/providers/festival_provider.dart';
import 'package:gajanan_maharaj_sevekari/widgets/festival_overlay.dart';
import 'package:gajanan_maharaj_sevekari/settings/font_provider.dart';
import 'package:gajanan_maharaj_sevekari/settings/locale_provider.dart';
import 'package:gajanan_maharaj_sevekari/settings/settings_screen.dart';
import 'package:gajanan_maharaj_sevekari/settings/theme_provider.dart';
import 'package:gajanan_maharaj_sevekari/signups/signups_screen.dart';
import 'package:gajanan_maharaj_sevekari/social_media/social_media_screen.dart';
import 'package:gajanan_maharaj_sevekari/splash/splash_screen.dart';
import 'package:gajanan_maharaj_sevekari/jap_mala/namjap_screen.dart';
import 'package:gajanan_maharaj_sevekari/jap_mala/individual_namjap_screen.dart';
import 'package:gajanan_maharaj_sevekari/jap_mala/group_namjap_list_screen.dart';
import 'package:gajanan_maharaj_sevekari/jap_mala/group_namjap_detail_screen.dart';
import 'package:gajanan_maharaj_sevekari/admin/admin_login_screen.dart';
import 'package:gajanan_maharaj_sevekari/admin/admin_dashboard_screen.dart';
import 'package:gajanan_maharaj_sevekari/admin/admin_temple_notifications_screen.dart';
import 'package:gajanan_maharaj_sevekari/admin/admin_typo_reports_screen.dart';
import 'package:gajanan_maharaj_sevekari/admin/parayan_coordination_dashboard.dart';
import 'package:gajanan_maharaj_sevekari/admin/manage_group_admins_screen.dart';
import 'package:gajanan_maharaj_sevekari/admin/parayan_admin_detail_screen.dart';
import 'package:gajanan_maharaj_sevekari/admin/parayan_admin_list_screen.dart';
import 'package:gajanan_maharaj_sevekari/admin/admin_parayan_group_screen.dart';
import 'package:gajanan_maharaj_sevekari/admin/create_parayan_screen.dart';
import 'package:gajanan_maharaj_sevekari/admin/group_namjap/admin_group_namjap_dashboard.dart';
import 'package:gajanan_maharaj_sevekari/admin/group_namjap/create_group_namjap_screen.dart';
import 'package:gajanan_maharaj_sevekari/admin/group_namjap/admin_group_namjap_detail_screen.dart';
import 'package:gajanan_maharaj_sevekari/admin/group_namjap/admin_group_namjap_list_screen.dart';
import 'package:gajanan_maharaj_sevekari/notifications/user_notifications_screen.dart';
import 'package:gajanan_maharaj_sevekari/onboarding/group_selection_screen.dart';
import 'package:gajanan_maharaj_sevekari/providers/event_provider.dart';
import 'package:gajanan_maharaj_sevekari/other/favorites_screen.dart';
import 'package:gajanan_maharaj_sevekari/other/favorite_item_list_screen.dart';
import 'package:gajanan_maharaj_sevekari/story/story_type_picker_screen.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:gajanan_maharaj_sevekari/utils/navigator_service.dart';
import 'package:gajanan_maharaj_sevekari/utils/deeplink_manager.dart';
import 'package:gajanan_maharaj_sevekari/utils/notification_service_helper.dart';
import 'package:gajanan_maharaj_sevekari/utils/group_utils.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Register background handler at the very top (must be top-level function)
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (!kIsWeb) {
    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider: kDebugMode
            ? AndroidProvider.debug
            : AndroidProvider.playIntegrity,
        appleProvider: kDebugMode
            ? AppleProvider.debug
            : AppleProvider.deviceCheck,
      );
    } catch (e) {
      debugPrint('Firebase App Check failed to activate: $e');
    }
  }

  await GoogleSignIn.instance.initialize();

  await NotificationManager.initialize(NavigatorService.navigatorKey);

  // Process any pending FCM subscriptions from previous sessions
  await NotificationServiceHelper.processOnStartup();

  final themeProvider = ThemeProvider();
  final localeProvider = LocaleProvider();
  final fontProvider = FontProvider();
  final appConfigProvider = AppConfigProvider();
  final playlistProvider = PlaylistProvider();
  final festivalProvider = FestivalProvider();
  final groupSelectionProvider = GroupSelectionProvider();

  await Future.wait([
    themeProvider.loadTheme(),
    localeProvider.loadLocale(),
    fontProvider.loadFonts(),
    appConfigProvider.loadAppConfig(),
    playlistProvider.init(),
    festivalProvider.loadFestivals(),
    groupSelectionProvider.loadPreferences(),
  ]);

  // After loading, check if we need to auto-apply a festival theme
  await themeProvider.checkAndApplyFestivalTheme(
    festivalProvider.activeFestival,
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<FirebaseFirestore>.value(value: FirebaseFirestore.instance),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: localeProvider),
        ChangeNotifierProvider.value(value: fontProvider),
        ChangeNotifierProvider.value(value: appConfigProvider),
        ChangeNotifierProvider.value(value: playlistProvider),
        ChangeNotifierProvider(create: (_) => GroupNamjapService()),
        ChangeNotifierProxyProvider<GroupNamjapService, GroupNamjapProvider>(
          create: (context) =>
              GroupNamjapProvider(service: context.read<GroupNamjapService>()),
          update: (context, service, previous) =>
              previous ?? GroupNamjapProvider(service: service),
        ),
        ChangeNotifierProvider.value(value: festivalProvider),
        ChangeNotifierProvider.value(value: groupSelectionProvider),
        ChangeNotifierProvider(
          create: (context) => EventProvider(
            groupSelectionProvider: context.read<GroupSelectionProvider>(),
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // Check initial link if app was closed
    final appLink = await _appLinks.getInitialLink();
    if (appLink != null) {
      _handleDeepLink(appLink);
    }

    // Handle link when app is in background or foreground
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) {
    // 0. Deduplicate links (prevents Android cold-boot double-triggers)
    if (!DeepLinkManager.shouldHandle(uri)) return;

    debugPrint('Deep Link Received: $uri');
    String? id;

    // 1. Handle Custom Scheme: gmsevekari://parayan/ID or gmsevekari:///parayan/ID
    if (uri.scheme == 'gmsevekari') {
      if ((uri.host == 'parayan' || uri.host == 'namjap') &&
          uri.pathSegments.isNotEmpty) {
        id = uri.pathSegments.first;
      } else if (uri.pathSegments.length >= 2 &&
          (uri.pathSegments[0] == 'parayan' ||
              uri.pathSegments[0] == 'namjap')) {
        id = uri.pathSegments[1];
      }
    }
    // 2. Handle Web Links: https://gajananmaharajsevekari.org/parayan/ID or /namjap/ID
    else if (uri.pathSegments.length >= 2 &&
        (uri.pathSegments[0] == 'parayan' || uri.pathSegments[0] == 'namjap')) {
      id = uri.pathSegments[1];
    }
    // 3. Handle Legacy Query Parameters: /parayan_detail?id=ID
    else if (uri.path == '/parayan_detail' ||
        uri.path.endsWith('/parayan_detail')) {
      id = uri.queryParameters['id'];
    }

    String? joinCode =
        uri.queryParameters['joinCode'] ?? uri.queryParameters['code'];

    final bool isNamjap =
        uri.toString().contains('/namjap/') || uri.host == 'namjap';
    final String routeName = isNamjap
        ? Routes.groupNamjapDetail
        : Routes.parayanDetail;

    if (id != null) {
      debugPrint(
        'Deep Link: Navigating to ${isNamjap ? "Namjap" : "Parayan"} ID: $id with code: $joinCode',
      );
      DeepLinkManager.setPendingRoute(routeName, {
        'id': id,
        'joinCode': joinCode,
      });

      // ONLY navigate directly if the app is already past the Splash screen.
      // During startup, SplashScreen will consume the result from consumePendingRoute().
      final navState = NavigatorService.navigatorKey.currentState;
      bool isAtSplash = true;
      navState?.popUntil((route) {
        if (route.settings.name != Routes.splash) {
          isAtSplash = false;
        }
        return true;
      });

      if (navState != null && !isAtSplash) {
        _safeNavigate(routeName, {'id': id, 'joinCode': joinCode});
      } else {
        debugPrint(
          '[DeepLinkManager] App is starting. Deferring navigation to SplashScreen.',
        );
      }
    }
  }

  void _safeNavigate(String routeName, dynamic arguments) {
    final state = NavigatorService.navigatorKey.currentState;
    if (state == null) {
      debugPrint('Navigator state is null, retrying in 500ms...');
      Future.delayed(const Duration(milliseconds: 500), () {
        _safeNavigate(routeName, arguments);
      });
      return;
    }
    state.pushNamed(routeName, arguments: arguments);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer5<
      ThemeProvider,
      LocaleProvider,
      FontProvider,
      AppConfigProvider,
      FestivalProvider
    >(
      builder:
          (
            context,
            themeProvider,
            localeProvider,
            fontProvider,
            appConfigProvider,
            festivalProvider,
            child,
          ) {
            final isMarathi = localeProvider.locale.languageCode == 'mr';
            final fontFamily = isMarathi
                ? fontProvider.marathiFontFamily
                : fontProvider.englishFontFamily;

            final activePreset = themeProvider.themePreset;

            final lightTextTheme = GoogleFonts.getTextTheme(
              fontFamily,
              AppTheme.getTheme(
                activePreset,
                false,
                customColor: themeProvider.customColor,
              ).textTheme,
            );
            final darkTextTheme = GoogleFonts.getTextTheme(
              fontFamily,
              AppTheme.getTheme(
                activePreset,
                true,
                customColor: themeProvider.customColor,
              ).textTheme,
            );

            return MaterialApp(
              navigatorKey: NavigatorService.navigatorKey,
              scaffoldMessengerKey: NavigatorService.scaffoldMessengerKey,
              builder: (context, child) =>
                  FestivalOverlay(child: child ?? const SizedBox.shrink()),
              onGenerateTitle: (context) =>
                  AppLocalizations.of(context)!.appName,
              theme: AppTheme.getTheme(
                activePreset,
                false,
                customColor: themeProvider.customColor,
              ).copyWith(textTheme: lightTextTheme),
              darkTheme: AppTheme.getTheme(
                activePreset,
                true,
                customColor: themeProvider.customColor,
              ).copyWith(textTheme: darkTextTheme),
              themeMode: themeProvider.themeMode,
              locale: localeProvider.locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              initialRoute: Routes.splash,
              routes: {
                Routes.splash: (context) => const SplashScreen(),
                Routes.home: (context) => const HomeScreen(),
                Routes.calendar: (context) => const EventCalendarScreen(),
                Routes.gallery: (context) => const GalleryScreen(),
                Routes.settings: (context) => const SettingsScreen(),
                Routes.sankalp: (context) => const SankalpScreen(),
                Routes.naamjap: (context) => const NamjapScreen(),
                Routes.individualNamjap: (context) =>
                    const IndividualNamjapScreen(),
                Routes.groupNamjap: (context) {
                  final args =
                      ModalRoute.of(context)?.settings.arguments as Map?;
                  return GroupNamjapListScreen(
                    groupId: args?['groupId'],
                    groupName: args?['groupName'],
                  );
                },
                Routes.groupNamjapDetail: (context) {
                  final args = ModalRoute.of(context)!.settings.arguments;
                  String? eventId;
                  String? joinCode;

                  if (args is String) {
                    eventId = args;
                  } else if (args is Map) {
                    eventId = args['id'];
                    joinCode = args['joinCode'];
                  }

                  return GroupNamjapDetailScreen(
                    eventId: eventId!,
                    prefilledJoinCode: joinCode,
                  );
                },
                Routes.adminLogin: (context) => const AdminLoginScreen(),
                Routes.adminDashboard: (context) =>
                    const AdminDashboardScreen(),
                Routes.adminTempleNotifications: (context) =>
                    const AdminTempleNotificationsScreen(),
                Routes.adminParayanCoordination: (context) {
                  final adminUser =
                      ModalRoute.of(context)?.settings.arguments as AdminUser?;
                  return ParayanCoordinationDashboard(adminUser: adminUser);
                },
                Routes.adminCreateParayan: (context) {
                  final adminUser =
                      ModalRoute.of(context)?.settings.arguments as AdminUser?;
                  return CreateParayanScreen(adminUser: adminUser);
                },
                Routes.adminGajananMaharajGroups: (context) {
                  final adminUser =
                      ModalRoute.of(context)?.settings.arguments as AdminUser;
                  return AdminParayanGroupScreen(adminUser: adminUser);
                },
                Routes.userNotifications: (context) =>
                    const UserNotificationsScreen(),
                Routes.gajananMaharajGroups: (context) =>
                    const GajananMaharajGroupScreen(),
                Routes.parayanList: (context) {
                  final args =
                      ModalRoute.of(context)?.settings.arguments as Map?;
                  return ParayanListScreen(
                    groupId: args?['groupId'],
                    groupName: args?['groupName'],
                  );
                },
                Routes.nityopasanaConsolidated: (context) =>
                    const NityopasanaConsolidatedScreen(),
                Routes.favorites: (context) => const FavoritesScreen(),
                Routes.favoriteItemList: (context) =>
                    const FavoriteItemListScreen(),
                Routes.adminTypoReports: (context) =>
                    const AdminTypoReportsScreen(),
                Routes.adminGroupNamjapDashboard: (context) =>
                    const AdminGroupNamjapDashboard(),
                Routes.adminCreateGroupNamjap: (context) =>
                    const CreateGroupNamjapScreen(),
                Routes.onboarding: (context) => const GroupSelectionScreen(),
                Routes.adminManageGroupAdmins: (context) {
                  final admin = ModalRoute.of(context)!.settings.arguments as AdminUser;
                  return ManageGroupAdminsScreen(currentAdmin: admin);
                },
                Routes.adminAddGroupAdmin: (context) =>
                    const Scaffold(body: Center(child: Text('Add Group Admin Placeholder'))),
              },
              onGenerateRoute: (settings) {
                final DeityConfig? deity = settings.arguments is DeityConfig
                    ? settings.arguments as DeityConfig
                    : null;

                switch (settings.name) {
                  case Routes.aarti:
                    return MaterialPageRoute(
                      builder: (context) => AartiScreen(deity: deity!),
                    );
                  case Routes.aboutMaharaj:
                    return MaterialPageRoute(
                      builder: (context) => AboutMaharajScreen(deity: deity!),
                    );
                  case Routes.donations:
                    return MaterialPageRoute(
                      builder: (context) => DonationsScreen(deity: deity!),
                    );
                  case Routes.signups:
                    return MaterialPageRoute(
                      builder: (context) => SignupsScreen(deity: deity!),
                    );
                  case Routes.socialMedia:
                    return MaterialPageRoute(
                      builder: (context) => SocialMediaScreen(deity: deity!),
                    );
                  case Routes.namavali:
                    return MaterialPageRoute(
                      builder: (context) => NamavaliScreen(deity: deity!),
                    );
                  case Routes.stories:
                    return MaterialPageRoute(
                      builder: (context) =>
                          StoryTypePickerScreen(deity: deity!),
                    );
                  case Routes.songs:
                    return MaterialPageRoute(
                      builder: (context) => ContentListScreen(
                        deity: deity!,
                        title: AppLocalizations.of(context)!.songTitle,
                        contentType: ContentType.song,
                        content: deity.songs!,
                      ),
                    );
                  case Routes.parayanDetail:
                    String? eventId;
                    ParayanEvent? event;
                    String? joinCode;

                    if (settings.arguments is ParayanEvent) {
                      event = settings.arguments as ParayanEvent;
                      eventId = event.id;
                    } else if (settings.arguments is Map) {
                      final args = settings.arguments as Map;
                      eventId = args['id'];
                      joinCode = args['joinCode'];
                    }

                    if (eventId != null &&
                        eventId.startsWith(GroupConstants.gunjan)) {
                      return MaterialPageRoute(
                        builder: (context) => PreallocatedParayanDetailScreen(
                          event: event,
                          eventId: eventId,
                        ),
                      );
                    }

                    if (event != null) {
                      return MaterialPageRoute(
                        builder: (context) => ParayanDetailScreen(event: event),
                      );
                    } else if (eventId != null) {
                      return MaterialPageRoute(
                        builder: (context) => ParayanDetailScreen(
                          eventId: eventId,
                          prefilledJoinCode: joinCode,
                        ),
                      );
                    }
                    return null;
                  case Routes.adminParayanDetail:
                    final event = settings.arguments as ParayanEvent;
                    return MaterialPageRoute(
                      builder: (context) =>
                          ParayanAdminDetailScreen(event: event),
                    );
                  case Routes.adminParayanList:
                    final args = settings.arguments as Map<String, dynamic>;
                    return MaterialPageRoute(
                      builder: (context) => ParayanAdminListScreen(
                        title: args['title'] as String,
                        statusFilter: args['statusFilter'] as String,
                        groupId: args['groupId'] as String?,
                      ),
                    );
                  case Routes.adminGroupNamjapDetail:
                    final eventId = settings.arguments as String;
                    return MaterialPageRoute(
                      builder: (context) =>
                          AdminGroupNamjapDetailScreen(eventId: eventId),
                    );
                  case Routes.adminGroupNamjapList:
                    final status = settings.arguments as String;
                    return MaterialPageRoute(
                      builder: (context) =>
                          AdminGroupNamjapListScreen(status: status),
                    );
                  default:
                    return null;
                }
              },
            );
          },
    );
  }
}

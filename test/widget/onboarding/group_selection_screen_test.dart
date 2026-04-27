import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/models/app_config.dart';
import 'package:gajanan_maharaj_sevekari/providers/app_config_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/group_selection_provider.dart';
import 'package:gajanan_maharaj_sevekari/onboarding/group_selection_screen.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:provider/provider.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/utils/deeplink_manager.dart';

class MockAppConfigProvider extends AppConfigProvider {
  final List<GajananMaharajGroup> _groups;

  MockAppConfigProvider(this._groups);

  @override
  AppConfig? get appConfig => AppConfig.fromJson({
    'appName': {'en': 'Test'},
    'latestVersion': '1.0',
    'forceUpdate': 'false',
    'updateMessage': {'en': 'msg'},
    'gajanan_maharaj_groups': _groups
        .map(
          (g) => {
            'id': g.id,
            'name_en': g.nameEn,
            'name_mr': g.nameMr,
            'icon': g.icon,
          },
        )
        .toList(),
    'social_media_links': [],
    'playStoreUrl': '',
    'appStoreUrl': '',
  });
}

class MockGroupSelectionProvider extends GroupSelectionProvider {
  List<String> _selectedGroupIds;
  bool _onboardingCompleted = false;

  MockGroupSelectionProvider(this._selectedGroupIds);

  @override
  List<String> get selectedGroupIds => _selectedGroupIds;

  @override
  Future<void> addGroup(String groupId) async {
    if (!_selectedGroupIds.contains(groupId)) {
      _selectedGroupIds.add(groupId);
      notifyListeners();
    }
  }

  @override
  Future<void> removeGroup(String groupId) async {
    _selectedGroupIds.remove(groupId);
    notifyListeners();
  }

  @override
  Future<void> setSelectedGroups(List<String> groupIds) async {
    _selectedGroupIds = groupIds;
    notifyListeners();
  }

  @override
  Future<void> completeOnboarding() async {
    _onboardingCompleted = true;
    notifyListeners();
  }

  bool get onboardingCompleted => _onboardingCompleted;
}

void main() {
  group('GroupSelectionScreen Widget Tests', () {
    late List<GajananMaharajGroup> mockGroups;

    setUp(() {
      mockGroups = [
        GajananMaharajGroup(
          id: 'g1',
          nameEn: 'Group 1',
          nameMr: 'गट १',
          icon: 'resources/images/icon/Space_Needle.png',
        ),
        GajananMaharajGroup(
          id: 'g2',
          nameEn: 'Group 2',
          nameMr: 'गट २',
          icon: 'resources/images/icon/Gajanan_Gunjan.png',
        ),
      ];
    });

    Widget createScreen(List<String> initialSelected) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AppConfigProvider>(
            create: (_) => MockAppConfigProvider(mockGroups),
          ),
          ChangeNotifierProvider<GroupSelectionProvider>(
            create: (_) => MockGroupSelectionProvider(initialSelected),
          ),
        ],
        child: MaterialApp(
          theme: ThemeData(
            cardTheme: const CardThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
            ),
          ),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          routes: {
            Routes.home: (context) => const Scaffold(body: Text('Home')),
            'test_route': (context) => const Scaffold(body: Text('test_route')),
          },
          home: const GroupSelectionScreen(),
        ),
      );
    }

    testWidgets('renders onboarding welcome text and logo', (tester) async {
      await tester.pumpWidget(createScreen([]));
      expect(find.text('Shree Gajanan Maharaj Sevekari'), findsOneWidget);
    });

    testWidgets(
      'tapping a group checkbox updates selection (select and unselect)',
      (tester) async {
        await tester.pumpWidget(createScreen([]));
        final checkbox = find.byType(Checkbox).first;

        await tester.tap(checkbox);
        await tester.pumpAndSettle();
        var card = tester.widget<Card>(find.byType(Card).first);
        expect((card.shape as RoundedRectangleBorder?)?.side.width, 2.0);

        await tester.tap(checkbox);
        await tester.pumpAndSettle();
        card = tester.widget<Card>(find.byType(Card).first);
        expect((card.shape as RoundedRectangleBorder?)?.side.width, 0.0);
      },
    );

    testWidgets('renders fallback icon when no group icon is provided', (
      tester,
    ) async {
      final groupsWithFallback = [
        ...mockGroups,
        GajananMaharajGroup(id: 'g3', nameEn: 'Group 3', nameMr: 'गट ३'),
      ];

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AppConfigProvider>(
              create: (_) => MockAppConfigProvider(groupsWithFallback),
            ),
            ChangeNotifierProvider<GroupSelectionProvider>(
              create: (_) => MockGroupSelectionProvider([]),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const GroupSelectionScreen(),
          ),
        ),
      );

      expect(find.text('Group 3', skipOffstage: false), findsOneWidget);
      expect(
        find.byIcon(Icons.location_on_outlined, skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets('can reorder groups', (tester) async {
      await tester.pumpWidget(createScreen(['g1', 'g2']));
      final dragHandle = find.byIcon(Icons.drag_indicator).first;
      await tester.drag(dragHandle, const Offset(0, 100));
      await tester.pumpAndSettle();
    });

    testWidgets('Finish Onboarding navigates to home and resumes deep link', (
      tester,
    ) async {
      DeepLinkManager.setPendingRoute('test_route', 'test_args');
      await tester.pumpWidget(createScreen(['g1']));

      final saveButton = find.text('Save');
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Home should be in the tree (possibly behind test_route)
      expect(find.text('Home', skipOffstage: false), findsOneWidget);
      // test_route should be visible
      expect(find.text('test_route', skipOffstage: false), findsOneWidget);
    });
  });
}

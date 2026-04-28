import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/jap_mala/namjap_screen.dart';
import 'package:gajanan_maharaj_sevekari/providers/app_config_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/group_selection_provider.dart';
import 'package:gajanan_maharaj_sevekari/shared/gajanan_maharaj_group_screen.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/settings/theme_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/festival_provider.dart';
import 'package:provider/provider.dart';
import 'package:mocktail/mocktail.dart';
import '../mocks.dart';

void main() {
  late MockGroupSelectionProvider mockGroupSelectionProvider;
  late MockAppConfigProvider mockAppConfigProvider;

  setUp(() {
    mockGroupSelectionProvider = MockGroupSelectionProvider();
    mockAppConfigProvider = MockAppConfigProvider();
  });

  Widget createWidget() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => FestivalProvider()),
        ChangeNotifierProvider<GroupSelectionProvider>.value(value: mockGroupSelectionProvider),
        ChangeNotifierProvider<AppConfigProvider>.value(value: mockAppConfigProvider),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        onGenerateRoute: (settings) {
          if (settings.name == Routes.naamjap) {
            return MaterialPageRoute(builder: (_) => const NamjapScreen());
          }
          if (settings.name == Routes.groupNamjap) {
            return MaterialPageRoute(builder: (_) => Text('Group Namjap List: ${settings.arguments}'));
          }
          if (settings.name == Routes.gajananMaharajGroups) {
            final config = settings.arguments as GroupScreenConfig;
            return MaterialPageRoute(builder: (_) => Text('Group Selection: ${config.title}'));
          }
          return null;
        },
        initialRoute: Routes.naamjap,
      ),
    );
  }

  testWidgets('Navigates directly to GroupNamjapList when exactly 1 group is selected', (WidgetTester tester) async {
    when(() => mockGroupSelectionProvider.selectedGroupIds).thenReturn(['seattle']);
    
    await tester.pumpWidget(createWidget());
    await tester.tap(find.text('Group Namjap'));
    await tester.pumpAndSettle();
    
    // In current implementation (before Phase 3), it always goes to groupNamjap but without arguments
    // Or it might fail if arguments don't match.
    // We expect it to navigate specifically with the groupId and groupName in Phase 3.
    expect(find.textContaining('Group Namjap List'), findsOneWidget);
  });

  testWidgets('Navigates to Group Selection when multiple groups are selected', (WidgetTester tester) async {
    when(() => mockGroupSelectionProvider.selectedGroupIds).thenReturn(['seattle', 'gunjan']);
    
    await tester.pumpWidget(createWidget());
    await tester.tap(find.text('Group Namjap'));
    await tester.pumpAndSettle();
    
    // In Phase 3, this should show "Group Selection"
    expect(find.textContaining('Group Selection'), findsOneWidget);
  });
}

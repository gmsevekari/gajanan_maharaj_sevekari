import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/festival_provider.dart';
import 'package:gajanan_maharaj_sevekari/settings/theme_provider.dart';
import 'package:gajanan_maharaj_sevekari/widgets/themed_icon.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FestivalProvider festivalProvider;
  late ThemeProvider themeProvider;

  setUp(() {
    festivalProvider = FestivalProvider();
    themeProvider = ThemeProvider();
  });

  Widget createThemedIconWidget(LogicalIcon icon, {IconData? fallbackIcon, String? defaultImagePath}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<FestivalProvider>.value(value: festivalProvider),
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: ThemedIcon(
            icon,
            fallbackIcon: fallbackIcon,
            defaultImagePath: defaultImagePath,
          ),
        ),
      ),
    );
  }

  group('ThemedIcon Widget Tests', () {
    testWidgets('renders default Icon for every LogicalIcon enum value', (WidgetTester tester) async {
      for (final icon in LogicalIcon.values) {
        await tester.pumpWidget(createThemedIconWidget(icon));
        expect(find.byType(ThemedIcon), findsOneWidget);
      }
    });

    testWidgets('renders fallbackIcon when provided', (WidgetTester tester) async {
      await tester.pumpWidget(createThemedIconWidget(LogicalIcon.home, fallbackIcon: Icons.star));
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('renders Image.asset when defaultImagePath is provided', (WidgetTester tester) async {
      await tester.pumpWidget(createThemedIconWidget(LogicalIcon.home, defaultImagePath: 'resources/images/festive/ganesh_stotras.png'));
      tester.takeException();
      expect(find.byType(Image), findsOneWidget);
    });
  });
}

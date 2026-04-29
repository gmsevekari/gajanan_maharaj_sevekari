import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:gajanan_maharaj_sevekari/admin/add_group_admin_screen.dart';
import 'package:gajanan_maharaj_sevekari/models/admin_user.dart';
import 'package:gajanan_maharaj_sevekari/settings/theme_provider.dart';
import 'package:gajanan_maharaj_sevekari/settings/font_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/festival_provider.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import '../mocks.dart';

void main() {
  late MockThemeProvider mockThemeProvider;
  late MockFontProvider mockFontProvider;
  late MockFestivalProvider mockFestivalProvider;

  setUp(() {
    mockThemeProvider = MockThemeProvider();
    mockFontProvider = MockFontProvider();
    mockFestivalProvider = MockFestivalProvider();

    when(() => mockThemeProvider.themePreset).thenReturn(ThemePreset.tulsi);
    when(() => mockThemeProvider.themeMode).thenReturn(ThemeMode.light);
    when(() => mockThemeProvider.customColor).thenReturn(null);
    when(() => mockFestivalProvider.activeFestival).thenReturn(null);
  });

  Widget createTestWidget(AdminUser admin) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>.value(value: mockThemeProvider),
        ChangeNotifierProvider<FontProvider>.value(value: mockFontProvider),
        ChangeNotifierProvider<FestivalProvider>.value(value: mockFestivalProvider),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AddGroupAdminScreen(currentAdmin: admin),
      ),
    );
  }

  testWidgets('renders basic screen structure', (tester) async {
    final admin = AdminUser(email: 'test@admin.com', roles: ['super_admin']);
    await tester.pumpWidget(createTestWidget(admin));
    await tester.pumpAndSettle();

    expect(find.text('Add Group Admin'), findsOneWidget);
    expect(find.byIcon(Icons.home), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);
    expect(find.text('Form Fields Coming Soon'), findsOneWidget);
  });
}

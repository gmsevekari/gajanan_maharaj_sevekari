import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gajanan_maharaj_sevekari/admin/admin_dashboard_screen.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:gajanan_maharaj_sevekari/settings/theme_provider.dart';
import 'package:gajanan_maharaj_sevekari/settings/font_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/festival_provider.dart';
import '../mocks.dart';

void main() {
  late MockFirebaseAuth mockAuth;
  late MockFirestore mockFirestore;
  late MockUser mockUser;
  late MockCollectionReference mockCollection;
  late MockDocumentReference mockDoc;
  late MockThemeProvider mockThemeProvider;
  late MockFontProvider mockFontProvider;
  late MockFestivalProvider mockFestivalProvider;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockFirestore = MockFirestore();
    mockUser = MockUser();
    mockCollection = MockCollectionReference();
    mockDoc = MockDocumentReference();
    mockThemeProvider = MockThemeProvider();
    mockFontProvider = MockFontProvider();
    mockFestivalProvider = MockFestivalProvider();

    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockUser.email).thenReturn('admin@test.com');
    when(() => mockFirestore.collection('admin_allowlist')).thenReturn(mockCollection);
    when(() => mockCollection.doc(any())).thenReturn(mockDoc);
    
    when(() => mockThemeProvider.themePreset).thenReturn(ThemePreset.tulsi);
    when(() => mockThemeProvider.themeMode).thenReturn(ThemeMode.light);
    when(() => mockThemeProvider.customColor).thenReturn(null);
    when(() => mockFestivalProvider.activeFestival).thenReturn(null);
  });

  Widget createTestWidget() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>.value(value: mockThemeProvider),
        ChangeNotifierProvider<FontProvider>.value(value: mockFontProvider),
        ChangeNotifierProvider<FestivalProvider>.value(value: mockFestivalProvider),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AdminDashboardScreen(
          auth: mockAuth,
          firestore: mockFirestore,
        ),
      ),
    );
  }

  group('AdminDashboardScreen Module Visibility', () {
    testWidgets('should show Manage Group Admins card for super_admin', (tester) async {
      final mockSnapshot = MockDocumentSnapshot();
      when(() => mockSnapshot.exists).thenReturn(true);
      when(() => mockSnapshot.data()).thenReturn({
        'roles': ['super_admin'],
      });
      when(() => mockDoc.snapshots()).thenAnswer((_) => Stream.value(mockSnapshot));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Manage Group Admins'), findsOneWidget);
    });

    testWidgets('should show Manage Group Admins card for group_admin with groupId', (tester) async {
      final mockSnapshot = MockDocumentSnapshot();
      when(() => mockSnapshot.exists).thenReturn(true);
      when(() => mockSnapshot.data()).thenReturn({
        'roles': ['group_admin'],
        'groupId': 'group_1',
      });
      when(() => mockDoc.snapshots()).thenAnswer((_) => Stream.value(mockSnapshot));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Manage Group Admins'), findsOneWidget);
    });

    testWidgets('should NOT show Manage Group Admins card for group_admin WITHOUT groupId', (tester) async {
      final mockSnapshot = MockDocumentSnapshot();
      when(() => mockSnapshot.exists).thenReturn(true);
      when(() => mockSnapshot.data()).thenReturn({
        'roles': ['group_admin'],
        'groupId': null,
      });
      when(() => mockDoc.snapshots()).thenAnswer((_) => Stream.value(mockSnapshot));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Manage Group Admins'), findsNothing);
    });

    testWidgets('should NOT show Manage Group Admins card for other roles', (tester) async {
      final mockSnapshot = MockDocumentSnapshot();
      when(() => mockSnapshot.exists).thenReturn(true);
      when(() => mockSnapshot.data()).thenReturn({
        'roles': ['parayan_coordinator'],
      });
      when(() => mockDoc.snapshots()).thenAnswer((_) => Stream.value(mockSnapshot));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Manage Group Admins'), findsNothing);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gajanan_maharaj_sevekari/jap_mala/widgets/namjap_signup_dialog.dart';
import 'package:gajanan_maharaj_sevekari/models/group_namjap_event.dart';
import 'package:gajanan_maharaj_sevekari/providers/group_namjap_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/app_config_provider.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';

class MockGroupNamjapProvider extends Mock implements GroupNamjapProvider {}
class MockAppConfigProvider extends Mock implements AppConfigProvider {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockGroupNamjapProvider mockGroupProvider;
  late MockAppConfigProvider mockAppConfigProvider;
  late GroupNamjapEvent testEvent;

  setUp(() {
    mockGroupProvider = MockGroupNamjapProvider();
    mockAppConfigProvider = MockAppConfigProvider();

    when(() => mockAppConfigProvider.appConfig).thenReturn(null);
    when(() => mockGroupProvider.hasProfile).thenReturn(true);
    when(() => mockGroupProvider.memberName).thenReturn('Abhishek');
    when(() => mockGroupProvider.phone).thenReturn('+12065550199');

    testEvent = GroupNamjapEvent(
      id: 'event_1',
      nameEn: 'Namjap Event',
      nameMr: 'नामजप इव्हेंट',
      sankalpEn: 'Sankalp',
      sankalpMr: 'संकल्प',
      mantra: 'Mantra',
      targetCount: 10000,
      totalCount: 2000,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 5)),
      createdAt: DateTime.now(),
      status: 'enrolling',
      joinCode: '123456',
      groupId: 'seattle',
    );
  });

  Widget createDialogWidget({bool isEdit = false, String? prefilledJoinCode}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<GroupNamjapProvider>.value(value: mockGroupProvider),
        ChangeNotifierProvider<AppConfigProvider>.value(value: mockAppConfigProvider),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => NamjapSignupDialog(
                      event: testEvent,
                      isEdit: isEdit,
                      prefilledJoinCode: prefilledJoinCode,
                    ),
                  );
                },
                child: const Text('Open Dialog'),
              );
            },
          ),
        ),
      ),
    );
  }

  group('NamjapSignupDialog Widget Tests', () {
    testWidgets('renders dialog with prefilled user profile', (WidgetTester tester) async {
      await tester.pumpWidget(createDialogWidget());
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(NamjapSignupDialog), findsOneWidget);
      expect(find.text('Abhishek'), findsOneWidget);
    });

    testWidgets('populates prefilledJoinCode when passed', (WidgetTester tester) async {
      await tester.pumpWidget(createDialogWidget(prefilledJoinCode: '654321'));
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('654321'), findsOneWidget);
    });
  });
}

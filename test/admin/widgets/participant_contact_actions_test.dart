import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:gajanan_maharaj_sevekari/admin/widgets/participant_contact_actions.dart';

class FakeUrlLauncher extends Fake
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {
  final List<String> launchedUrls = [];
  bool canLaunchResult = true;

  @override
  Future<bool> canLaunch(String url) async => canLaunchResult;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launchedUrls.add(url);
    return true;
  }
}

void main() {
  late FakeUrlLauncher fakeLauncher;

  setUp(() {
    fakeLauncher = FakeUrlLauncher();
    UrlLauncherPlatform.instance = fakeLauncher;
  });

  Widget createWidget(String phone) {
    return MaterialApp(
      home: Scaffold(body: ParticipantContactActions(phone: phone)),
    );
  }

  group('ParticipantContactActions', () {
    testWidgets('renders a Text and a WhatsApp icon button with tooltips', (
      tester,
    ) async {
      await tester.pumpWidget(createWidget('+911234567890'));

      expect(find.byTooltip('Text'), findsOneWidget);
      expect(find.byTooltip('WhatsApp'), findsOneWidget);
    });

    testWidgets('tapping the WhatsApp button launches a wa.me link with '
        'digits only (no leading +)', (tester) async {
      await tester.pumpWidget(createWidget('+91 12345-67890'));

      await tester.tap(find.byTooltip('WhatsApp'));
      await tester.pumpAndSettle();

      expect(fakeLauncher.launchedUrls, ['https://wa.me/911234567890']);
    });

    testWidgets('tapping the Text button launches an sms: link keeping the '
        'leading + but stripping other formatting', (tester) async {
      await tester.pumpWidget(createWidget('+91 12345-67890'));

      await tester.tap(find.byTooltip('Text'));
      await tester.pumpAndSettle();

      expect(fakeLauncher.launchedUrls, ['sms:+911234567890']);
    });

    testWidgets('does nothing when the WhatsApp app cannot be launched', (
      tester,
    ) async {
      fakeLauncher.canLaunchResult = false;
      await tester.pumpWidget(createWidget('+911234567890'));

      await tester.tap(find.byTooltip('WhatsApp'));
      await tester.pumpAndSettle();

      expect(fakeLauncher.launchedUrls, isEmpty);
    });

    testWidgets('does nothing when no SMS app can be launched', (tester) async {
      fakeLauncher.canLaunchResult = false;
      await tester.pumpWidget(createWidget('+911234567890'));

      await tester.tap(find.byTooltip('Text'));
      await tester.pumpAndSettle();

      expect(fakeLauncher.launchedUrls, isEmpty);
    });

    testWidgets('sanitizes a phone number with no country code for both '
        'actions', (tester) async {
      await tester.pumpWidget(createWidget('(123) 456-7890'));

      await tester.tap(find.byTooltip('Text'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('WhatsApp'));
      await tester.pumpAndSettle();

      expect(fakeLauncher.launchedUrls, [
        'sms:1234567890',
        'https://wa.me/1234567890',
      ]);
    });
  });
}

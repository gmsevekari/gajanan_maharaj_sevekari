import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/models/app_config.dart';
import 'package:gajanan_maharaj_sevekari/providers/app_config_provider.dart';
import 'package:gajanan_maharaj_sevekari/utils/default_timezone.dart';
import 'package:gajanan_maharaj_sevekari/utils/event_timezone.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockAppConfigProvider extends Mock implements AppConfigProvider {}

void main() {
  AppConfig config() => AppConfig(
    deities: const [],
    gajananMaharajGroups: [
      GajananMaharajGroup(
        id: 'seattle',
        nameEn: 'Seattle',
        nameMr: 'सिॲटल',
        defaultTimezone: EventTimezone.pacific,
      ),
      GajananMaharajGroup(
        id: 'gunjan',
        nameEn: 'Gunjan',
        nameMr: 'गुंजन',
        defaultTimezone: EventTimezone.india,
      ),
    ],
    socialMediaLinks: const [],
    appName: const {},
    updateMessage: const {},
    latestVersion: '1.0.0',
    forceUpdate: 'false',
    playStoreUrl: '',
    appStoreUrl: '',
  );

  /// Builds a widget under an optional provider and returns what
  /// [defaultTimezoneFor] gives for [groupId].
  Future<String> resolve(
    WidgetTester tester, {
    AppConfigProvider? provider,
    String? groupId,
  }) async {
    late String result;
    final probe = Builder(
      builder: (context) {
        result = defaultTimezoneFor(context, groupId);
        return const SizedBox();
      },
    );
    await tester.pumpWidget(
      MaterialApp(
        home: provider == null
            ? probe
            : ChangeNotifierProvider<AppConfigProvider>.value(
                value: provider,
                child: probe,
              ),
      ),
    );
    return result;
  }

  testWidgets('returns the group\'s timezone from the app config', (
    tester,
  ) async {
    final provider = _MockAppConfigProvider();
    when(() => provider.appConfig).thenReturn(config());

    expect(
      await resolve(tester, provider: provider, groupId: 'gunjan'),
      EventTimezone.india,
    );
    expect(
      await resolve(tester, provider: provider, groupId: 'seattle'),
      EventTimezone.pacific,
    );
  });

  testWidgets('falls back to Pacific for an unknown or missing group', (
    tester,
  ) async {
    final provider = _MockAppConfigProvider();
    when(() => provider.appConfig).thenReturn(config());

    expect(
      await resolve(tester, provider: provider, groupId: 'nobody'),
      EventTimezone.pacific,
    );
    expect(await resolve(tester, provider: provider), EventTimezone.pacific);
  });

  testWidgets('falls back to Pacific while the config has not loaded', (
    tester,
  ) async {
    final provider = _MockAppConfigProvider();
    when(() => provider.appConfig).thenReturn(null);

    expect(
      await resolve(tester, provider: provider, groupId: 'gunjan'),
      EventTimezone.pacific,
    );
  });

  testWidgets('falls back to Pacific when there is no provider at all', (
    tester,
  ) async {
    expect(await resolve(tester, groupId: 'gunjan'), EventTimezone.pacific);
  });
}

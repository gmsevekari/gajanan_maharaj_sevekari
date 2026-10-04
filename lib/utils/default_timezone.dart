import 'package:flutter/widgets.dart';
import 'package:gajanan_maharaj_sevekari/providers/app_config_provider.dart';
import 'package:gajanan_maharaj_sevekari/utils/event_timezone.dart';
import 'package:provider/provider.dart';

/// The timezone new sign-up slots default to for [groupId], from the app
/// config when one is provided above [context], else Pacific. Tolerates a
/// missing provider (and a config that hasn't loaded yet) so widgets using it
/// can be built without the app shell. Mirrors `defaultCountryCodeFor`.
String defaultTimezoneFor(BuildContext context, String? groupId) {
  try {
    return context.read<AppConfigProvider>().appConfig?.getDefaultTimezone(
          groupId,
        ) ??
        EventTimezone.defaultZone;
  } on ProviderNotFoundException {
    return EventTimezone.defaultZone;
  }
}

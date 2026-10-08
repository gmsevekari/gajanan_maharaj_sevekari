import 'package:gajanan_maharaj_sevekari/utils/routes.dart';

/// Where tapping a notification should take the devotee.
class NotificationTarget {
  final String route;
  final Object? arguments;

  const NotificationTarget(this.route, [this.arguments]);
}

/// Works out where a tapped notification goes: a sign-up slot reminder opens
/// its sign-up (where "My Sign Ups" is a tap away), everything else opens the
/// notifications inbox.
class NotificationRouting {
  /// The `type` the reminder function puts in the message's data (see
  /// `buildReminderMessage` in functions/signupReminders.js).
  static const String signupReminderType = 'SIGNUP_REMINDER';

  static const String _signupPayloadPrefix = 'signup:';

  static const NotificationTarget _inbox = NotificationTarget(
    Routes.userNotifications,
  );

  /// For a push message's `data`.
  static NotificationTarget forMessageData(Map<String, dynamic> data) {
    final signupId = data['signup_id'];
    if (data['type'] == signupReminderType &&
        signupId is String &&
        signupId.isNotEmpty) {
      return _signup(signupId);
    }
    return _inbox;
  }

  /// The payload a locally shown sign-up reminder carries, so a tap on it can
  /// be routed by [forPayload].
  static String payloadForSignup(String signupId) =>
      '$_signupPayloadPrefix$signupId';

  /// For the payload of a tapped local notification.
  static NotificationTarget forPayload(String? payload) {
    if (payload != null && payload.startsWith(_signupPayloadPrefix)) {
      final signupId = payload.substring(_signupPayloadPrefix.length);
      if (signupId.isNotEmpty) return _signup(signupId);
    }
    return _inbox;
  }

  static NotificationTarget _signup(String signupId) =>
      NotificationTarget(Routes.signupDetail, {'signupId': signupId});
}

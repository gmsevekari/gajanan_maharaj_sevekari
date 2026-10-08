import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gajanan_maharaj_sevekari/notifications/notification_routing.dart';

/// The Android notification channels the app registers itself, and which one
/// a push is shown under when the app has to show it (it is open).
///
/// A channel is what Android lists in the system's notification settings, so
/// a devotee can mute sign-up reminders without muting everything else.
class NotificationChannels {
  /// The channel the reminder function names in its messages.
  static const String signupRemindersId = 'signup_reminders';

  static const String _templeId = 'temple_notifications';

  static const AndroidNotificationChannel signupReminders =
      AndroidNotificationChannel(
        signupRemindersId,
        'Sign-up reminders',
        description:
            'Reminders a day and an hour before the sign-up slots you '
            'signed up for',
        importance: Importance.high,
      );

  /// How to show a push the app is displaying itself: sign-up reminders under
  /// their own channel, anything else as before under the temple one.
  static AndroidNotificationDetails detailsFor(Map<String, dynamic> data) {
    if (data['type'] == NotificationRouting.signupReminderType) {
      return AndroidNotificationDetails(
        signupRemindersId,
        signupReminders.name,
        channelDescription: signupReminders.description,
        importance: signupReminders.importance,
        priority: Priority.high,
        showWhen: true,
        styleInformation: const BigTextStyleInformation(''),
      );
    }
    return const AndroidNotificationDetails(
      _templeId,
      'Temple Notifications',
      channelDescription: 'Broadcast notifications for temple events',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      styleInformation: BigTextStyleInformation(''),
    );
  }

  /// Registers the sign-up reminders channel with Android, so a reminder
  /// pushed while the app is closed is shown under it (Android would
  /// otherwise fall back to its default channel). Does nothing on other
  /// platforms. Creating an existing channel changes nothing.
  static Future<void> createSignupReminders(
    FlutterLocalNotificationsPlugin plugin,
  ) async {
    await plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(signupReminders);
  }
}

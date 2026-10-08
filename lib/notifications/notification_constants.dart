class NotificationConstants {
  static const String weeklyPoojaTopic = 'weekly_pooja';
  static const String weeklyPoojaReminderPrefKey = 'weekly_pooja_reminder';
  static const String templeNotificationsTopic = 'temple_notifications';
  static const String templeNotificationsPrefKey = 'temple_notifications_pref';

  static const String parayanRemindersPrefKey = 'parayan_reminders_pref';

  /// Whether the devotee wants reminders for the sign-up slots they have an
  /// entry on (on unless turned off).
  static const String signupRemindersPrefKey = 'signup_reminders_pref';

  static String getParayanReminderTopic(String eventId, int day) {
    return 'parayan_${eventId}_day$day';
  }

  /// The topic a device subscribes to for a sign-up slot it has an entry on:
  /// one per slot. The reminder function sends to the same name (see
  /// `reminderTopic` in functions/signupReminders.js), so change both
  /// together.
  static String getSignupSlotReminderTopic(String signupId, String slotId) {
    return 'signup_slot_${signupId}_$slotId';
  }
}

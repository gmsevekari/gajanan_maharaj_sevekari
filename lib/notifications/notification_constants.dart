class NotificationConstants {
  static const String weeklyPoojaTopic = 'weekly_pooja';
  static const String weeklyPoojaReminderPrefKey = 'weekly_pooja_reminder';
  static const String templeNotificationsTopic = 'temple_notifications';
  static const String templeNotificationsPrefKey = 'temple_notifications_pref';

  static const String parayanRemindersPrefKey = 'parayan_reminders_pref';

  static String getParayanReminderTopic(String eventId, int day) {
    return 'parayan_${eventId}_day$day';
  }
}

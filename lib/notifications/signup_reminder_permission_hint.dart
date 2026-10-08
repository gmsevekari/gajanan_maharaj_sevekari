import 'package:app_settings/app_settings.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/notifications/signup_reminder_subscriptions.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A one-time nudge, after a devotee signs up or claims their sign-up, when
/// notifications are off for the app: without them the reminders they are now
/// subscribed to can't be shown. Never repeated, never shown when reminders
/// are already switched off or notifications already allowed, and never
/// allowed to disturb the sign-up it follows.
class SignupReminderPermissionHint {
  static const String _shownKey = 'signup_reminder_hint_shown';
  static const Duration _visibleFor = Duration(seconds: 8);

  /// Each of these can be replaced in tests; they default to the real thing.
  final Future<AuthorizationStatus> Function()? authorizationStatus;
  final Future<void> Function()? requestPermission;
  final Future<void> Function()? openSettings;

  const SignupReminderPermissionHint({
    this.authorizationStatus,
    this.requestPermission,
    this.openSettings,
  });

  /// Shows the hint (a snackbar with one action) if it is needed and hasn't
  /// been shown before. The snackbar is queued behind the sign-up's own
  /// confirmation. It is worded with [l10n], which the caller (the English-only
  /// sign-up screens) passes in, so it reads like the confirmation before it.
  Future<void> showIfNeeded(BuildContext context, AppLocalizations l10n) async {
    if (kIsWeb) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (!await SignupReminderSubscriptions.isEnabled()) return;
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_shownKey) ?? false) return;

      final status = await (authorizationStatus ?? _currentStatus)();
      if (status == AuthorizationStatus.authorized ||
          status == AuthorizationStatus.provisional) {
        return;
      }
      await prefs.setBool(_shownKey, true);

      final canAsk = status == AuthorizationStatus.notDetermined;
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.signupRemindersPermissionHint),
          duration: _visibleFor,
          action: SnackBarAction(
            label: canAsk ? l10n.signupRemindersAllow : l10n.openSettings,
            onPressed: () => _act(canAsk),
          ),
        ),
      );
    } on Exception catch (error) {
      debugPrint('SignupReminderPermissionHint: not shown: $error');
    }
  }

  Future<void> _act(bool ask) async {
    try {
      if (ask) {
        await (requestPermission ?? _request)();
      } else {
        await (openSettings ?? _open)();
      }
    } on Exception catch (error) {
      debugPrint('SignupReminderPermissionHint: action failed: $error');
    }
  }

  static Future<AuthorizationStatus> _currentStatus() async =>
      (await FirebaseMessaging.instance.getNotificationSettings())
          .authorizationStatus;

  static Future<void> _request() async {
    await FirebaseMessaging.instance.requestPermission();
  }

  static Future<void> _open() =>
      AppSettings.openAppSettings(type: AppSettingsType.notification);
}

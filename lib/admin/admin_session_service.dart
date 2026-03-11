import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:gajanan_maharaj_sevekari/utils/navigator_service.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AdminSessionService {
  static Timer? _inactivityTimer;
  static DateTime _lastActivity = DateTime.now();
  static const Duration _timeout = Duration(minutes: 10);

  static void startSession() {
    debugPrint('Admin session started');
    _lastActivity = DateTime.now();
    _scheduleTimer();
  }

  static void registerInteraction() {
    if (FirebaseAuth.instance.currentUser == null) return;

    final now = DateTime.now();
    if (now.difference(_lastActivity) >= _timeout) {
      debugPrint('Interaction detected after timeout, forcing logout');
      _forceLogout();
      return;
    }

    _lastActivity = now;
    _scheduleTimer();
  }

  static void _scheduleTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_timeout, _handleTimeout);
  }

  static Future<void> _handleTimeout() async {
    final now = DateTime.now();
    final difference = now.difference(_lastActivity);

    if (difference >= _timeout) {
      debugPrint('Admin session timed out');
      await _forceLogout();
    } else {
      // Timer fired early, reschedule for the remaining duration
      final remaining = _timeout - difference;
      _inactivityTimer = Timer(remaining, _handleTimeout);
    }
  }

  static Future<void> _forceLogout() async {
    _inactivityTimer?.cancel();

    // Check if already logged out to prevent redundant popups
    if (FirebaseAuth.instance.currentUser == null) return;

    debugPrint('Executing admin force logout');
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn.instance.signOut();

    // Use global keys for navigation and snackbar
    final context = NavigatorService.navigatorKey.currentContext;
    if (context != null) {
      // ignore: use_build_context_synchronously
      final localizations = AppLocalizations.of(context)!;
      NavigatorService.scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(localizations.logoutInactivity)),
      );
    }

    NavigatorService.navigatorKey.currentState?.pushNamedAndRemoveUntil(
      Routes.home,
      (route) => false,
    );
  }

  static void clearSession() {
    debugPrint('Admin session cleared');
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
  }
}

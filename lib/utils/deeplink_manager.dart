import 'package:flutter/material.dart';

class DeepLinkManager {
  static String? _pendingRoute;
  static dynamic _pendingArguments;
  static Uri? _lastHandledUri;
  static DateTime? _lastHandledTime;

  static void setPendingRoute(String route, dynamic arguments) {
    debugPrint(
      '[DeepLinkManager] Setting pending route: $route with args: $arguments',
    );
    _pendingRoute = route;
    _pendingArguments = arguments;
  }

  /// Checks if a URI should be handled, preventing duplicate triggers
  /// within a short interval (1000ms).
  static bool shouldHandle(Uri uri) {
    final now = DateTime.now();
    if (_lastHandledUri == uri &&
        _lastHandledTime != null &&
        now.difference(_lastHandledTime!).inMilliseconds < 1000) {
      debugPrint('[DeepLinkManager] Ignoring duplicate URI: $uri');
      return false;
    }
    _lastHandledUri = uri;
    _lastHandledTime = now;
    return true;
  }

  static Map<String, dynamic>? consumePendingRoute() {
    if (_pendingRoute == null) return null;

    final result = {'route': _pendingRoute!, 'arguments': _pendingArguments};

    debugPrint('[DeepLinkManager] Consuming pending route: $_pendingRoute');
    _pendingRoute = null;
    _pendingArguments = null;
    return result;
  }
}

import 'package:flutter/material.dart';

class DeepLinkManager {
  static String? _pendingRoute;
  static dynamic _pendingArguments;

  static void setPendingRoute(String route, dynamic arguments) {
    debugPrint(
      '[DeepLinkManager] Setting pending route: $route with args: $arguments',
    );
    _pendingRoute = route;
    _pendingArguments = arguments;
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

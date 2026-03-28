import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/utils/region_manager.dart';

class RegionProvider extends ChangeNotifier {
  String? _currentRegion;
  bool _initialized = false;

  String? get currentRegion => _currentRegion;
  bool get isInitialized => _initialized;

  /// Returns true if the verified physical location is the United States.
  bool get isInUS => _currentRegion?.toUpperCase() == 'US';

  /// Initialized the region status.
  /// 1. Immediately loads the last known region from cache to prevent UI flicker.
  /// 2. Triggers a fresh background check if the cache is stale.
  Future<void> initialize() async {
    // Stage 1: Fast cache load
    _currentRegion = await RegionManager.getCachedCountryCode();
    _initialized = true;
    notifyListeners();

    // Stage 2: Fresh background check
    // (Actual logic for checking 24h expiration is within RegionManager)
    final freshRegion = await RegionManager.getFreshCountryCode();

    if (freshRegion != null && freshRegion != _currentRegion) {
      _currentRegion = freshRegion;
      notifyListeners();
    }
  }
}

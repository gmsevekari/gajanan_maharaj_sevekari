import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegionManager {
  static const String _regionCacheKey = 'cached_region_code';
  static const String _lastCheckKey = 'last_region_check_time';

  /// Performs a strict GPS check to see if the user is physically in the US.
  /// This bypasses spoofed system settings.
  static Future<bool> isPhysicallyInUS() async {
    final code = await getFreshCountryCode();
    return code?.toUpperCase() == 'US';
  }

  /// Returns the cached country code synchronously-style (via SharedPreferences).
  static Future<String?> getCachedCountryCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_regionCacheKey);
  }

  /// Performs a fresh GPS check and returns the ISO country code.
  static Future<String?> getFreshCountryCode() async {
    if (kIsWeb) {
      debugPrint('RegionManager: Geocoding is not supported on Web.');
      return null;
    }

    try {
      // 1. Check Cache (1 day validity to avoid constant GPS drain)
      final prefs = await SharedPreferences.getInstance();
      final cachedCode = prefs.getString(_regionCacheKey);
      final lastCheckMillis = prefs.getInt(_lastCheckKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      if (cachedCode != null && (now - lastCheckMillis) < 24 * 60 * 60 * 1000) {
        debugPrint('RegionManager: Using cached region: $cachedCode');
        return cachedCode;
      }

      // 2. Check Permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('RegionManager: Location permission denied.');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('RegionManager: Location permission denied forever.');
        return null;
      }

      // 3. Get Position
      debugPrint('RegionManager: Requesting current position (Strict GPS)...');
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low, // Coarse is enough for country-level
        ),
      );

      // 4. Reverse Geocode to get Country Code
      final List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final countryCode = placemarks.first.isoCountryCode;
        debugPrint(
          'RegionManager: Detected Physical Country Code: $countryCode',
        );

        // Cache the result
        if (countryCode != null) {
          await prefs.setString(_regionCacheKey, countryCode);
          await prefs.setInt(_lastCheckKey, now);
          return countryCode;
        }
      }

      return null;
    } catch (e) {
      debugPrint('RegionManager: Error during strict region detection: $e');
      return null;
    }
  }

  /// Helper to check if a feature should be shown based on a list of allowed regions.
  static Future<bool> shouldShowFeature(List<String> allowedRegions) async {
    if (allowedRegions.isEmpty) return true;
    if (!allowedRegions.contains('US')) return true;

    return await isPhysicallyInUS();
  }
}

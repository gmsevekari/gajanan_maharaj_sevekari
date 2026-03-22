import 'dart:io';
import 'package:android_id/android_id.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

class UniqueIdService {
  static const String _uuidKey = 'app_unique_uuid';
  static String? _cachedId;

  /// Returns a persistent unique identifier for this device.
  /// 
  /// Priority:
  /// 1. Cached ID (memory)
  /// 2. Android ID (Hardware-bound) or iOS IdentifierForVendor
  /// 3. Previously stored UUID from SharedPreferences
  /// 4. Newly generated UUID (stored for future use)
  static Future<String> getUniqueId() async {
    if (_cachedId != null) return _cachedId!;

    String? hardwareId;
    try {
      if (Platform.isAndroid) {
        const androidIdPlugin = AndroidId();
        hardwareId = await androidIdPlugin.getId();
      } else if (Platform.isIOS) {
        final deviceInfo = DeviceInfoPlugin();
        final iosInfo = await deviceInfo.iosInfo;
        hardwareId = iosInfo.identifierForVendor;
      }
    } catch (e) {
      debugPrint('Error fetching hardware ID: $e');
    }

    // Use hardware ID if available
    if (hardwareId != null && hardwareId.isNotEmpty) {
      _cachedId = hardwareId;
      return hardwareId;
    }

    // Fallback to SharedPreferences UUID
    final prefs = await SharedPreferences.getInstance();
    String? storedUuid = prefs.getString(_uuidKey);
    
    if (storedUuid != null && storedUuid.isNotEmpty) {
      _cachedId = storedUuid;
      return storedUuid;
    }

    // Final fallback: Generate and store new UUID
    final newUuid = const Uuid().v4();
    await prefs.setString(_uuidKey, newUuid);
    _cachedId = newUuid;
    return newUuid;
  }
}

import 'dart:io';
import 'package:android_id/android_id.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

class UniqueIdService {
  static String? _cachedId;
  static const String _uuidKey = 'unique_device_id';
  static const _secureStorage = FlutterSecureStorage();

  /// Returns a persistent unique identifier for this device.
  ///
  /// Priority for iOS (Keychain Fallback):
  /// 1. Cached ID (memory)
  /// 2. Keychain (Secure persistence across updates/reinstalls)
  /// 3. identifierForVendor (IDFV)
  ///
  /// Priority for Android:
  /// 1. Cached ID (memory)
  /// 2. Hardware ID (Android ID)
  /// 3. SharedPreferences UUID (Fallback)
  static Future<String> getUniqueId() async {
    if (_cachedId != null) return _cachedId!;

    // Case: iOS Keychain Fallback Strategy
    if (!kIsWeb && Platform.isIOS) {
      try {
        // 1. Check Keychain
        String? keychainId = await _secureStorage.read(key: _uuidKey);
        if (keychainId != null && keychainId.isNotEmpty) {
          _cachedId = keychainId;
          return keychainId;
        }

        // 2. Fetch IDFV
        final deviceInfo = DeviceInfoPlugin();
        final iosInfo = await deviceInfo.iosInfo;
        String? idfv = iosInfo.identifierForVendor;

        if (idfv != null && idfv.isNotEmpty) {
          // 3. Persist IDFV in Keychain
          await _secureStorage.write(key: _uuidKey, value: idfv);
          _cachedId = idfv;
          return idfv;
        }
      } catch (e) {
        debugPrint('Error in iOS Keychain fallback: $e');
      }
    }

    // Default/Android Strategy
    String? hardwareId;
    try {
      if (!kIsWeb && Platform.isAndroid) {
        const androidIdPlugin = AndroidId();
        hardwareId = await androidIdPlugin.getId();
      }
    } catch (e) {
      debugPrint('Error fetching hardware ID: $e');
    }

    // Use hardware ID if available (Android ID)
    if (hardwareId != null && hardwareId.isNotEmpty) {
      _cachedId = hardwareId;
      return hardwareId;
    }

    // Fallback to SharedPreferences UUID (Used for Android if ID fails, or non-mobile platforms)
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

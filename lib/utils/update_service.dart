import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:flutter/foundation.dart';

enum UpdateType { none, recommended, forced }

class UpdateResult {
  final UpdateType type;
  final String latestVersion;
  final String currentVersion;
  final String storeUrl;

  UpdateResult({
    required this.type,
    required this.latestVersion,
    required this.currentVersion,
    required this.storeUrl,
  });
}

class UpdateService {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UpdateResult> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = Version.parse(packageInfo.version);
      debugPrint('[UpdateService] Current App Version: $currentVersion');

      final doc = await _firestore
          .collection('app_config')
          .doc('version')
          .get();
      if (!doc.exists) {
        return UpdateResult(
          type: UpdateType.none,
          latestVersion: '',
          currentVersion: packageInfo.version,
          storeUrl: '',
        );
      }

      final data = doc.data() as Map<String, dynamic>;
      final platformKey = Platform.isAndroid ? 'android' : 'ios';

      if (!data.containsKey(platformKey)) {
        return UpdateResult(
          type: UpdateType.none,
          latestVersion: '',
          currentVersion: packageInfo.version,
          storeUrl: '',
        );
      }

      final platformData = data[platformKey] as Map<String, dynamic>;
      final latestVersionStr = platformData['latest_version'] as String;
      final minVersionStr = platformData['min_version'] as String;
      final storeUrl = platformData['store_url'] as String;

      final latestVersion = Version.parse(latestVersionStr);
      final minVersion = Version.parse(minVersionStr);

      if (currentVersion < minVersion) {
        return UpdateResult(
          type: UpdateType.forced,
          latestVersion: latestVersionStr,
          currentVersion: packageInfo.version,
          storeUrl: storeUrl,
        );
      } else if (currentVersion < latestVersion) {
        return UpdateResult(
          type: UpdateType.recommended,
          latestVersion: latestVersionStr,
          currentVersion: packageInfo.version,
          storeUrl: storeUrl,
        );
      }

      return UpdateResult(
        type: UpdateType.none,
        latestVersion: latestVersionStr,
        currentVersion: packageInfo.version,
        storeUrl: storeUrl,
      );
    } catch (e) {
      // In case of error (network, parse error), fail gracefully and let user use the app
      debugPrint('Update check failed: $e');
      PackageInfo? packageInfo;
      try {
        packageInfo = await PackageInfo.fromPlatform();
      } catch (_) {}

      return UpdateResult(
        type: UpdateType.none,
        latestVersion: '',
        currentVersion: packageInfo?.version ?? '',
        storeUrl: '',
      );
    }
  }
}

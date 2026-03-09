import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gajanan_maharaj_sevekari/models/app_config.dart';

class AppConfigProvider extends ChangeNotifier {
  AppConfig? _appConfig;
  AppConfig? get appConfig => _appConfig;

  Future<void> loadAppConfig() async {
    // Load the main app config file
    final String appConfigResponse = await rootBundle.loadString('resources/config/app_config.json');
    final appConfigData = json.decode(appConfigResponse);

    // Load the favorites config file
    final String favoritesResponse = await rootBundle.loadString(appConfigData['favorites_config']);
    final favoritesData = json.decode(favoritesResponse);
    final favoritesConfig = FavoritesConfig.fromJson(favoritesData);

    // Load all deity configurations in parallel
    final List<Future<DeityConfig>> futureDeities = (appConfigData['deities'] as List).map((d) async {
      final deityConfigPath = d['configFile']; // Corrected key
      final String deityResponse = await rootBundle.loadString(deityConfigPath);
      final deityData = json.decode(deityResponse);
      return DeityConfig.fromJson(deityData);
    }).toList();

    final loadedDeities = await Future.wait(futureDeities);

    // Create the final AppConfig object
    _appConfig = AppConfig(
      deities: loadedDeities,
      favorites: favoritesConfig,
    );

    notifyListeners();
  }
}

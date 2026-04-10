import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/playlist.dart';

class PlaylistProvider extends ChangeNotifier {
  static const String _playlistsKey = 'user_playlists';
  static const String _deletedDefaultsKey = 'deleted_default_playlist_ids';
  static const String _defaultPlaylistNameEn = 'My Favorites';
  static const String _defaultPlaylistNameMr = 'माझे फेव्हरेट्स';

  List<Playlist> _playlists = [];
  List<Playlist> get playlists => _playlists;

  Playlist? get defaultPlaylist => _playlists.isNotEmpty
      ? _playlists.firstWhere(
          (p) => p.isDefault,
          orElse: () => _playlists.first,
        )
      : null;

  bool _isInit = false;

  Future<void> init() async {
    if (_isInit) return;
    await _loadPlaylists();
    _isInit = true;
  }

  Future<void> _loadPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final String? playlistsJsonString = prefs.getString(_playlistsKey);

    if (playlistsJsonString != null && playlistsJsonString.isNotEmpty) {
      final List<dynamic> decodedList = json.decode(playlistsJsonString);
      _playlists = decodedList.map((item) => Playlist.fromJson(item)).toList();
    } else {
      // First time launch or no playlists, create "My Favorites"
      final defaultPl = Playlist(
        name_en: _defaultPlaylistNameEn,
        name_mr: _defaultPlaylistNameMr,
        isDefault: true,
      );
      _playlists = [defaultPl];
    }

    // Always attempt to merge configurations from favorites.json (for legacy users)
    final List<String> deletedIds =
        prefs.getStringList(_deletedDefaultsKey) ?? [];
    try {
      final configString = await rootBundle.loadString(
        'resources/config/favorites.json',
      );
      if (configString.isNotEmpty) {
        final List<dynamic> defaultList = json.decode(configString);
        for (var item in defaultList) {
          final configPl = Playlist.fromJson(item);
          final existingIndex = _playlists.indexWhere(
            (p) => p.id == configPl.id,
          );

          if (existingIndex == -1) {
            // Case 1: New playlist from config, not in local list
            if (!deletedIds.contains(configPl.id)) {
              if (_playlists.isNotEmpty) {
                _playlists.insert(1, configPl);
              } else {
                _playlists.add(configPl);
              }
            }
          } else {
            // Case 2: Already exists locally. Enforce position and refresh metadata
            final existingPl = _playlists[existingIndex];

            final updatedPl = existingPl.copyWith(
              name_en: configPl.name_en,
              name_mr: configPl.name_mr,
            );

            // Enforce position (index 1)
            if (existingIndex != 1 && _playlists.length > 1) {
              _playlists.removeAt(existingIndex);
              _playlists.insert(1, updatedPl);
            } else {
              _playlists[existingIndex] = updatedPl;
            }
          }
        }
      }
    } catch (e) {
      // Silently ignore if favorites.json is missing or invalid
    }

    await _savePlaylists();
    notifyListeners();
  }

  Future<void> _savePlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedList = json.encode(
      _playlists.map((pl) => pl.toJson()).toList(),
    );
    await prefs.setString(_playlistsKey, encodedList);
  }

  Future<void> createPlaylist(String name) async {
    if (_playlists.length >= 20) {
      throw Exception('Maximum 20 playlists allowed.');
    }
    if (_playlists.any(
      (p) =>
          p.name_en.toLowerCase() == name.toLowerCase() ||
          p.name_mr.toLowerCase() == name.toLowerCase(),
    )) {
      throw Exception('A playlist with this name already exists.');
    }

    final newPlaylist = Playlist(name_en: name, name_mr: name);
    _playlists.add(newPlaylist);
    await _savePlaylists();
    notifyListeners();
  }

  Future<void> renamePlaylist(String id, String newName) async {
    final index = _playlists.indexWhere((p) => p.id == id);
    if (index == -1) return;

    if (_playlists.any(
      (p) =>
          (p.name_en.toLowerCase() == newName.toLowerCase() ||
              p.name_mr.toLowerCase() == newName.toLowerCase()) &&
          p.id != id,
    )) {
      throw Exception('A playlist with this name already exists.');
    }

    _playlists[index] = _playlists[index].copyWith(
      name_en: newName,
      name_mr: newName,
    );
    await _savePlaylists();
    notifyListeners();
  }

  Future<void> deletePlaylist(String id) async {
    final index = _playlists.indexWhere((p) => p.id == id);
    if (index == -1) return;

    if (_playlists[index].isDefault) {
      throw Exception('Default playlist cannot be deleted.');
    }

    final deletedId = _playlists[index].id;
    _playlists.removeAt(index);
    await _savePlaylists();

    final prefs = await SharedPreferences.getInstance();
    final deletedIds = prefs.getStringList(_deletedDefaultsKey) ?? [];
    if (!deletedIds.contains(deletedId)) {
      deletedIds.add(deletedId);
      await prefs.setStringList(_deletedDefaultsKey, deletedIds);
    }
    notifyListeners();
  }

  Future<void> addAarti(String playlistId, String aartiId) async {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index == -1) return;

    if (_playlists[index].aartiIds.length >= 100) {
      throw Exception('Maximum 100 aartis per playlist allowed.');
    }

    if (!_playlists[index].aartiIds.contains(aartiId)) {
      final updatedAartis = List<String>.from(_playlists[index].aartiIds)
        ..add(aartiId);
      _playlists[index] = _playlists[index].copyWith(aartiIds: updatedAartis);
      await _savePlaylists();
      notifyListeners();
    }
  }

  Future<void> removeAarti(String playlistId, String aartiId) async {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index == -1) return;

    if (_playlists[index].aartiIds.contains(aartiId)) {
      final updatedAartis = List<String>.from(_playlists[index].aartiIds)
        ..remove(aartiId);
      _playlists[index] = _playlists[index].copyWith(aartiIds: updatedAartis);
      await _savePlaylists();
      notifyListeners();
    }
  }

  Future<void> reorderAartis(
    String playlistId,
    int oldIndex,
    int newIndex,
  ) async {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index == -1) return;

    final updatedAartis = List<String>.from(_playlists[index].aartiIds);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = updatedAartis.removeAt(oldIndex);
    updatedAartis.insert(newIndex, item);

    _playlists[index] = _playlists[index].copyWith(aartiIds: updatedAartis);
    await _savePlaylists();
    notifyListeners();
  }

  bool isAddedToPlaylist(String playlistId, String aartiId) {
    if (!_isInit) return false;
    final playlist = _playlists.firstWhere(
      (p) => p.id == playlistId,
      orElse: () => Playlist(name_en: '', name_mr: ''),
    );
    if (playlist.id.isEmpty) return false;
    return playlist.aartiIds.contains(aartiId);
  }

  bool isFavorite(String aartiId) {
    if (!_isInit || defaultPlaylist == null) return false;
    return defaultPlaylist!.aartiIds.contains(aartiId);
  }

  Future<void> toggleFavorite(String aartiId) async {
    if (defaultPlaylist == null) return;

    if (isFavorite(aartiId)) {
      await removeAarti(defaultPlaylist!.id, aartiId);
    } else {
      await addAarti(defaultPlaylist!.id, aartiId);
    }
  }
}

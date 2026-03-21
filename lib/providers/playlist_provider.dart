import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/playlist.dart';

class PlaylistProvider extends ChangeNotifier {
  static const String _playlistsKey = 'user_playlists';
  static const String _defaultPlaylistName = 'My Favorites';

  List<Playlist> _playlists = [];
  List<Playlist> get playlists => _playlists;

  Playlist? get defaultPlaylist => _playlists.isNotEmpty ? _playlists.firstWhere((p) => p.isDefault, orElse: () => _playlists.first) : null;

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
        name: _defaultPlaylistName,
        isDefault: true,
      );
      _playlists = [defaultPl];
      await _savePlaylists();
    }
    notifyListeners();
  }

  Future<void> _savePlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedList = json.encode(_playlists.map((pl) => pl.toJson()).toList());
    await prefs.setString(_playlistsKey, encodedList);
  }

  Future<void> createPlaylist(String name) async {
    if (_playlists.length >= 20) {
      throw Exception('Maximum 20 playlists allowed.');
    }
    if (_playlists.any((p) => p.name.toLowerCase() == name.toLowerCase())) {
      throw Exception('A playlist with this name already exists.');
    }

    final newPlaylist = Playlist(name: name);
    _playlists.add(newPlaylist);
    await _savePlaylists();
    notifyListeners();
  }

  Future<void> renamePlaylist(String id, String newName) async {
    final index = _playlists.indexWhere((p) => p.id == id);
    if (index == -1) return;

    if (_playlists.any((p) => p.name.toLowerCase() == newName.toLowerCase() && p.id != id)) {
      throw Exception('A playlist with this name already exists.');
    }

    _playlists[index] = _playlists[index].copyWith(name: newName);
    await _savePlaylists();
    notifyListeners();
  }

  Future<void> deletePlaylist(String id) async {
    final index = _playlists.indexWhere((p) => p.id == id);
    if (index == -1) return;

    if (_playlists[index].isDefault) {
      throw Exception('Default playlist cannot be deleted.');
    }

    _playlists.removeAt(index);
    await _savePlaylists();
    notifyListeners();
  }

  Future<void> addAarti(String playlistId, String aartiId) async {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index == -1) return;

    if (_playlists[index].aartiIds.length >= 100) {
      throw Exception('Maximum 100 aartis per playlist allowed.');
    }

    if (!_playlists[index].aartiIds.contains(aartiId)) {
      final updatedAartis = List<String>.from(_playlists[index].aartiIds)..add(aartiId);
      _playlists[index] = _playlists[index].copyWith(aartiIds: updatedAartis);
      await _savePlaylists();
      notifyListeners();
    }
  }

  Future<void> removeAarti(String playlistId, String aartiId) async {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index == -1) return;

    if (_playlists[index].aartiIds.contains(aartiId)) {
      final updatedAartis = List<String>.from(_playlists[index].aartiIds)..remove(aartiId);
      _playlists[index] = _playlists[index].copyWith(aartiIds: updatedAartis);
      await _savePlaylists();
      notifyListeners();
    }
  }

  Future<void> reorderAartis(String playlistId, int oldIndex, int newIndex) async {
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
    final playlist = _playlists.firstWhere((p) => p.id == playlistId, orElse: () => Playlist(name: ''));
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

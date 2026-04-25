import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GroupSelectionProvider extends ChangeNotifier {
  static const String _storageKey = 'selected_groups';
  List<String> _selectedGroupIds = [];

  List<String> get selectedGroupIds => List.unmodifiable(_selectedGroupIds);

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedGroupIds = prefs.getStringList(_storageKey) ?? [];
    notifyListeners();
  }

  Future<void> setSelectedGroups(List<String> groupIds) async {
    _selectedGroupIds = List.from(groupIds);
    await _savePreferences();
  }

  Future<void> addGroup(String groupId) async {
    if (!_selectedGroupIds.contains(groupId)) {
      _selectedGroupIds.add(groupId);
      await _savePreferences();
    }
  }

  Future<void> removeGroup(String groupId) async {
    if (_selectedGroupIds.remove(groupId)) {
      await _savePreferences();
    }
  }

  Future<void> reorderGroups(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final String item = _selectedGroupIds.removeAt(oldIndex);
    _selectedGroupIds.insert(newIndex, item);
    await _savePreferences();
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, _selectedGroupIds);
    notifyListeners();
  }
}

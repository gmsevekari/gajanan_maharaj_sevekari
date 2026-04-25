import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gajanan_maharaj_sevekari/providers/group_selection_provider.dart';

void main() {
  group('GroupSelectionProvider', () {
    late GroupSelectionProvider provider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('initial state should be empty if no preferences exist', () async {
      provider = GroupSelectionProvider();
      await provider.loadPreferences();
      expect(provider.selectedGroupIds, isEmpty);
    });

    test('should load persisted groups from preferences', () async {
      SharedPreferences.setMockInitialValues({
        'selected_groups': ['gajanan_maharaj_seattle', 'gajanan_gunjan'],
      });
      provider = GroupSelectionProvider();
      await provider.loadPreferences();
      
      expect(provider.selectedGroupIds, ['gajanan_maharaj_seattle', 'gajanan_gunjan']);
    });

    test('setSelectedGroups should update state and persist to SharedPreferences', () async {
      provider = GroupSelectionProvider();
      await provider.loadPreferences();
      
      await provider.setSelectedGroups(['g1', 'g2']);
      
      expect(provider.selectedGroupIds, ['g1', 'g2']);
      
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('selected_groups'), ['g1', 'g2']);
    });

    test('addGroup should add a new group to the list and persist', () async {
      SharedPreferences.setMockInitialValues({
        'selected_groups': ['g1'],
      });
      provider = GroupSelectionProvider();
      await provider.loadPreferences();
      
      await provider.addGroup('g2');
      
      expect(provider.selectedGroupIds, ['g1', 'g2']);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('selected_groups'), ['g1', 'g2']);
    });

    test('addGroup should not add duplicate groups', () async {
      SharedPreferences.setMockInitialValues({
        'selected_groups': ['g1'],
      });
      provider = GroupSelectionProvider();
      await provider.loadPreferences();
      
      await provider.addGroup('g1');
      
      expect(provider.selectedGroupIds, ['g1']);
    });

    test('removeGroup should remove a group from the list and persist', () async {
      SharedPreferences.setMockInitialValues({
        'selected_groups': ['g1', 'g2'],
      });
      provider = GroupSelectionProvider();
      await provider.loadPreferences();
      
      await provider.removeGroup('g1');
      
      expect(provider.selectedGroupIds, ['g2']);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('selected_groups'), ['g2']);
    });

    test('reorderGroups should update the list order and persist', () async {
      SharedPreferences.setMockInitialValues({
        'selected_groups': ['g1', 'g2', 'g3'],
      });
      provider = GroupSelectionProvider();
      await provider.loadPreferences();
      
      await provider.reorderGroups(0, 2); // Move 'g1' to index 2 (which becomes index 1 after removal of original)
      
      expect(provider.selectedGroupIds, ['g2', 'g1', 'g3']);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('selected_groups'), ['g2', 'g1', 'g3']);
    });
  });
}

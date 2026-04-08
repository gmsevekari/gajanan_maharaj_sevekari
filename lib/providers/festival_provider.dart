import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:gajanan_maharaj_sevekari/models/festival.dart';

class FestivalProvider extends ChangeNotifier {
  List<Festival> _festivals = [];
  Festival? _activeFestival;
  bool _shouldTriggerAnimation = false;

  Festival? get activeFestival => _activeFestival;
  bool get shouldTriggerAnimation => _shouldTriggerAnimation;

  void triggerAnimation() {
    _shouldTriggerAnimation = true;
    notifyListeners();
  }

  void resetAnimationTrigger() {
    _shouldTriggerAnimation = false;
    // We don't notify here to prevent unnecessary rebuilds while the animation is already active
  }

  Future<void> loadFestivals() async {
    try {
      final jsonString = await rootBundle.loadString(
        'resources/config/festivals.json',
      );
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      if (jsonData.containsKey('festivals') && jsonData['festivals'] is List) {
        _festivals = (jsonData['festivals'] as List)
            .map((e) => Festival.fromJson(e as Map<String, dynamic>))
            .toList();

        _evaluateActiveFestival();
      }
    } catch (e) {
      debugPrint('Error loading festivals: $e');
    }
  }

  void _evaluateActiveFestival() {
    final now = DateTime.now();
    Festival? currentActive;

    for (var festival in _festivals) {
      if (festival.isActive(now)) {
        currentActive = festival;
        break; // Assume only one active festival at a time for simplicity
      }
    }

    if (_activeFestival?.id != currentActive?.id) {
      _activeFestival = currentActive;
      notifyListeners();
    }
  }

  // Callable if app state resumes from background to re-eval
  void checkActiveFestival() {
    _evaluateActiveFestival();
  }
}

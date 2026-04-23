import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JapMalaProvider with ChangeNotifier {
  static const int countsPerMala = 108;

  int _currentCount = 0;
  int _completedMalas = 0;
  int _targetMalas = 1; // Default target
  int? _customTargetMalas;

  // Time-based state
  int _selectedHours = 0;
  int _selectedMinutes = 10;
  int _remainingSeconds = 0;
  Timer? _timer;

  bool _isPlaying = false;
  bool _isTimerExpired = false;
  int _japsPlayedSinceStart = 0;

  // Getters
  int get currentCount => _currentCount;
  int get completedMalas => _completedMalas;
  int get targetMalas => _targetMalas;
  int? get customTargetMalas => _customTargetMalas;
  int get selectedHours => _selectedHours;
  int get selectedMinutes => _selectedMinutes;
  int get remainingSeconds => _remainingSeconds;
  bool get isPlaying => _isPlaying;
  bool get isTimerExpired => _isTimerExpired;
  int get japsPlayedSinceStart => _japsPlayedSinceStart;
  int get totalCount => (completedMalas * countsPerMala) + currentCount;

  // Configuration Constants
  static const String keyCustomTarget = 'customTargetMalas';
  static const String keyHours = 'timeBasedJapHours';
  static const String keyMinutes = 'timeBasedJapMinutes';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _customTargetMalas = prefs.getInt(keyCustomTarget);
    _selectedHours = prefs.getInt(keyHours) ?? 0;
    _selectedMinutes = prefs.getInt(keyMinutes) ?? 10;
    notifyListeners();
  }

  void setTarget(int target) {
    if (_isPlaying) return;
    _targetMalas = target;
    reset();
  }

  Future<void> setCustomTarget(int target) async {
    if (_isPlaying) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(keyCustomTarget, target);
    _customTargetMalas = target;
    setTarget(target);
  }

  Future<void> setDuration(int hours, int minutes) async {
    if (_isPlaying) return;
    _selectedHours = hours;
    _selectedMinutes = minutes;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(keyHours, hours);
    await prefs.setInt(keyMinutes, minutes);
    
    reset();
  }

  void increment() {
    _currentCount++;
    _japsPlayedSinceStart++;
    
    if (_currentCount >= countsPerMala) {
      _completedMalas++;
      _currentCount = 0;
    }
    notifyListeners();
  }

  void decrement() {
    if (_currentCount > 0) {
      _currentCount--;
      _japsPlayedSinceStart--;
    } else if (_completedMalas > 0) {
      _completedMalas--;
      _currentCount = countsPerMala - 1;
      _japsPlayedSinceStart--;
    }
    notifyListeners();
  }

  void startCountingSession() {
    _isPlaying = true;
    _japsPlayedSinceStart = 0;
    notifyListeners();
  }

  void startTimeBasedSession() {
    if (_selectedHours == 0 && _selectedMinutes == 0) return;
    
    _isPlaying = true;
    _isTimerExpired = false;
    if (_remainingSeconds == 0) {
      _remainingSeconds = (_selectedHours * 3600) + (_selectedMinutes * 60);
      _currentCount = 0;
      _completedMalas = 0;
    }
    
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        if (_remainingSeconds == 0) {
          _isTimerExpired = true;
          timer.cancel();
        }
        notifyListeners();
      }
    });
    notifyListeners();
  }

  void stop() {
    _timer?.cancel();
    _isPlaying = false;
    notifyListeners();
  }

  void reset() {
    stop();
    _currentCount = 0;
    _completedMalas = 0;
    _remainingSeconds = 0;
    _isTimerExpired = false;
    _japsPlayedSinceStart = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

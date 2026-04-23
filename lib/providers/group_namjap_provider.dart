import 'package:flutter/foundation.dart';
import 'package:gajanan_maharaj_sevekari/models/group_namjap_participant.dart';
import 'package:gajanan_maharaj_sevekari/providers/group_namjap_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GroupNamjapProvider extends ChangeNotifier {
  final GroupNamjapService _service;

  String? _memberName;
  String? _phone;
  bool _isLoading = false;

  // Track which events the user has joined in this session
  final Map<String, bool> _joinedEvents = {};

  GroupNamjapProvider({required GroupNamjapService service})
    : _service = service;

  String? get memberName => _memberName;
  String? get phone => _phone;
  bool get isLoading => _isLoading;

  /// Returns true if the user has a profile (name and phone) stored locally.
  bool get hasProfile => _memberName != null && _phone != null;

  /// Returns true if the user has successfully joined this specific event.
  bool isJoined(String eventId) => _joinedEvents[eventId] ?? false;

  static const String keyMemberName = 'group_namjap_member_name';
  static const String keyPhone = 'group_namjap_phone';

  Future<void> loadLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    _memberName = prefs.getString(keyMemberName);
    _phone = prefs.getString(keyPhone);
    notifyListeners();
  }

  Future<bool> signUp({
    required String eventId,
    required String joinCode,
    required String memberName,
    required String phone,
    required String deviceId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final participant = GroupNamjapParticipant(
        memberName: memberName,
        deviceId: deviceId,
        phone: phone,
        joinedAt: DateTime.now(),
        totalCount: 0,
      );

      final success = await _service.joinEvent(
        eventId: eventId,
        joinCode: joinCode,
        participant: participant,
      );

      if (success) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(keyMemberName, memberName);
        await prefs.setString(keyPhone, phone);

        _memberName = memberName;
        _phone = phone;
        _joinedEvents[eventId] = true;
      }
      return success;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> syncParticipation(String eventId, String deviceId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final participant = await _service.checkParticipation(eventId, deviceId);
      if (participant != null) {
        // Update local profile if not already set or if different
        if (_memberName == null || _phone == null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(keyMemberName, participant.memberName);
          await prefs.setString(keyPhone, participant.phone);

          _memberName = participant.memberName;
          _phone = participant.phone;
        }
        _joinedEvents[eventId] = true;
      } else {
        _joinedEvents[eventId] = false;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteSignUp(String eventId, String deviceId) async {
    if (_memberName == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _service.deleteParticipation(
        eventId: eventId,
        deviceId: deviceId,
        memberName: _memberName!,
      );
      _joinedEvents[eventId] = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

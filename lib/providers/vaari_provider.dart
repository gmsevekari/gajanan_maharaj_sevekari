import 'package:flutter/foundation.dart';
import 'package:gajanan_maharaj_sevekari/providers/vaari_service.dart';

class VaariProvider extends ChangeNotifier {
  final VaariService _service;

  String? _memberName;
  String? _phone;
  bool _isLoading = false;

  final Map<String, bool> _joinedEvents = {};

  VaariProvider({required VaariService service}) : _service = service;

  String? get memberName => _memberName;
  String? get phone => _phone;
  bool get isLoading => _isLoading;

  bool get hasProfile => _memberName != null && _phone != null;

  bool isJoined(String eventId) => _joinedEvents[eventId] ?? false;

  static const String keyMemberName = 'vaari_member_name';
  static const String keyPhone = 'vaari_phone';

  Future<void> loadLocalData() async {
    throw UnimplementedError();
  }

  Future<bool> signUp({
    required String eventId,
    required String joinCode,
    required String memberName,
    required String phone,
    required String deviceId,
  }) async {
    throw UnimplementedError();
  }

  Future<void> syncParticipation(String eventId, String deviceId) async {
    throw UnimplementedError();
  }

  Future<void> deleteSignUp(String eventId, String deviceId) async {
    throw UnimplementedError();
  }
}

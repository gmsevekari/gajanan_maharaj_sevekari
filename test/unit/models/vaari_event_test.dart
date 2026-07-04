import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/models/vaari_event.dart';

void main() {
  group('VaariEvent Model Tests', () {
    final now = DateTime.now();
    final eventMap = {
      'createdAt': Timestamp.fromDate(now),
      'endDate': Timestamp.fromDate(now.add(const Duration(days: 3))),
      'groupId': 'gajanan_gunjan',
      'joinCode': '123456',
      'name_en': 'Weekly Vaari Challenge',
      'name_mr': 'साप्ताहिक वारी',
      'description_en': 'Walk and report steps',
      'description_mr': 'चालून पायऱ्या रिपोर्ट करा',
      'startDate': Timestamp.fromDate(now),
      'status': 'ongoing',
      'timezone': 'Asia/Kolkata',
      'totalSteps': 50000,
      'totalDistance': 40.0,
      'distanceUnit': 'km',
    };

    test('should correctly deserialize from Firestore map', () {
      final event = VaariEvent.fromMap('doc_123', eventMap);

      expect(event.id, 'doc_123');
      expect(event.groupId, 'gajanan_gunjan');
      expect(event.joinCode, '123456');
      expect(event.nameEn, 'Weekly Vaari Challenge');
      expect(event.nameMr, 'साप्ताहिक वारी');
      expect(event.descriptionEn, 'Walk and report steps');
      expect(event.descriptionMr, 'चालून पायऱ्या रिपोर्ट करा');
      expect(event.status, 'ongoing');
      expect(event.timezone, 'Asia/Kolkata');
      expect(event.totalSteps, 50000);
      expect(event.totalDistance, 40.0);
      expect(event.distanceUnit, 'km');
      expect(event.startDate, isA<DateTime>());
      expect(event.endDate, isA<DateTime>());
      expect(event.createdAt, isA<DateTime>());
    });

    test('should correctly serialize to Firestore map', () {
      final event = VaariEvent(
        id: 'doc_123',
        groupId: 'gajanan_gunjan',
        joinCode: '123456',
        nameEn: 'Weekly Vaari Challenge',
        nameMr: 'साप्ताहिक वारी',
        descriptionEn: 'Walk and report steps',
        descriptionMr: 'चालून पायऱ्या रिपोर्ट करा',
        startDate: now,
        endDate: now.add(const Duration(days: 3)),
        status: 'ongoing',
        timezone: 'Asia/Kolkata',
        totalSteps: 50000,
        totalDistance: 40.0,
        distanceUnit: 'km',
        createdAt: now,
      );

      final map = event.toMap();

      expect(map['groupId'], 'gajanan_gunjan');
      expect(map['joinCode'], '123456');
      expect(map['name_en'], 'Weekly Vaari Challenge');
      expect(map['name_mr'], 'साप्ताहिक वारी');
      expect(map['description_en'], 'Walk and report steps');
      expect(map['description_mr'], 'चालून पायऱ्या रिपोर्ट करा');
      expect(map['status'], 'ongoing');
      expect(map['timezone'], 'Asia/Kolkata');
      expect(map['totalSteps'], 50000);
      expect(map['totalDistance'], 40.0);
      expect(map['distanceUnit'], 'km');
      expect(map['startDate'], isA<Timestamp>());
      expect(map['endDate'], isA<Timestamp>());
      expect(map['createdAt'], isA<Timestamp>());
    });

    test('should support copyWith', () {
      final event = VaariEvent(
        id: 'doc_123',
        groupId: 'gajanan_gunjan',
        joinCode: '123456',
        nameEn: 'Weekly Vaari Challenge',
        nameMr: 'साप्ताहिक वारी',
        descriptionEn: 'Walk and report steps',
        descriptionMr: 'चालून पायऱ्या रिपोर्ट करा',
        startDate: now,
        endDate: now.add(const Duration(days: 3)),
        status: 'ongoing',
        timezone: 'Asia/Kolkata',
        totalSteps: 50000,
        totalDistance: 40.0,
        distanceUnit: 'km',
        createdAt: now,
      );

      final copied = event.copyWith(totalSteps: 60000, status: 'completed');

      expect(copied.id, 'doc_123');
      expect(copied.totalSteps, 60000);
      expect(copied.status, 'completed');
      expect(copied.groupId, 'gajanan_gunjan');
    });
  });
}

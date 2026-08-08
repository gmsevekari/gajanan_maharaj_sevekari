import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/utils/navigator_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('NavigatorService provides static global keys', () {
    expect(NavigatorService.navigatorKey, isA<GlobalKey<NavigatorState>>());
    expect(NavigatorService.scaffoldMessengerKey, isA<GlobalKey<ScaffoldMessengerState>>());
  });
}

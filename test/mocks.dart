import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:gajanan_maharaj_sevekari/providers/parayan_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:gajanan_maharaj_sevekari/providers/festival_provider.dart';
import 'package:gajanan_maharaj_sevekari/settings/theme_provider.dart';
import 'package:gajanan_maharaj_sevekari/settings/font_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/app_config_provider.dart';
import 'package:gajanan_maharaj_sevekari/settings/locale_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/group_selection_provider.dart';

class MockFirestore extends Mock implements FirebaseFirestore {}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

class MockFirebaseMessaging extends Mock implements FirebaseMessaging {}

// For UpdateService
class MockPackageInfo extends Mock implements PackageInfo {}

// For Cloud Functions
class MockFirebaseFunctions extends Mock implements FirebaseFunctions {}

class MockHttpsCallable extends Mock implements HttpsCallable {}

class MockHttpsCallableResult extends Mock implements HttpsCallableResult {}

class MockQuerySnapshot extends Mock
    implements QuerySnapshot<Map<String, dynamic>> {}

class MockQueryDocumentSnapshot extends Mock
    implements QueryDocumentSnapshot<Map<String, dynamic>> {}

class MockWriteBatch extends Mock implements WriteBatch {}

class MockSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

// For Services
class MockParayanService extends Mock implements ParayanService {}

// For Providers
class MockFestivalProvider extends Mock implements FestivalProvider {}

class MockThemeProvider extends Mock implements ThemeProvider {}

class MockFontProvider extends Mock implements FontProvider {}

class MockAppConfigProvider extends Mock implements AppConfigProvider {}

class MockLocaleProvider extends Mock implements LocaleProvider {}

class MockQuery extends Mock implements Query<Map<String, dynamic>> {}

class MockGroupSelectionProvider extends Mock
    implements GroupSelectionProvider {}

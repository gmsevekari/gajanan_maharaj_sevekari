import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/utils/constants.dart';
import 'package:gajanan_maharaj_sevekari/utils/group_utils.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';

void main() {
  group('Constants', () {
    test('appName is correct', () {
      expect(Constants.appName, equals('Gajanan Maharaj Sevekari'));
    });

    test('all Marathi title constants are non-empty', () {
      expect(Constants.granthTitle, isNotEmpty);
      expect(Constants.stotraTitle, isNotEmpty);
      expect(Constants.namavaliTitle, isNotEmpty);
      expect(Constants.aartiTitle, isNotEmpty);
      expect(Constants.bhajanTitle, isNotEmpty);
      expect(Constants.sankalpTitle, isNotEmpty);
      expect(Constants.parayanTitle, isNotEmpty);
      expect(Constants.aboutMaharajTitle, isNotEmpty);
      expect(Constants.calendarTitle, isNotEmpty);
      expect(Constants.donationsTitle, isNotEmpty);
    });
  });

  group('GroupConstants', () {
    test('seattle group ID is correct', () {
      expect(GroupConstants.seattle, equals('gajanan_maharaj_seattle'));
    });

    test('gunjan group ID is correct', () {
      expect(GroupConstants.gunjan, equals('gajanan_gunjan'));
    });

    test('defaultCountryCode is +1', () {
      expect(GroupConstants.defaultCountryCode, equals('+1'));
    });
  });

  group('Routes', () {
    test('all route strings are non-empty and start with /', () {
      final routes = [
        Routes.splash,
        Routes.home,
        Routes.granth,
        Routes.stotra,
        Routes.namavali,
        Routes.aarti,
        Routes.bhajan,
        Routes.sankalp,
        Routes.aboutMaharaj,
        Routes.calendar,
        Routes.donations,
        Routes.gallery,
        Routes.settings,
        Routes.socialMedia,
        Routes.nityopasana,
        Routes.signups,
        Routes.other,
        Routes.fontSelection,
        Routes.songs,
        Routes.naamjap,
        Routes.individualNamjap,
        Routes.groupNamjap,
        Routes.groupNamjapDetail,
        Routes.adminLogin,
        Routes.adminDashboard,
        Routes.adminTempleNotifications,
        Routes.adminParayanCoordination,
        Routes.adminGajananMaharajGroups,
        Routes.adminCreateParayan,
        Routes.adminParayanDetail,
        Routes.adminParayanList,
        Routes.parayanList,
        Routes.gajananMaharajGroups,
        Routes.parayanDetail,
        Routes.userNotifications,
        Routes.nityopasanaConsolidated,
        Routes.favorites,
        Routes.favoriteItemList,
        Routes.stories,
        Routes.adminTypoReports,
        Routes.adminGroupNamjapDashboard,
        Routes.adminCreateGroupNamjap,
        Routes.adminGroupNamjapDetail,
        Routes.adminGroupNamjapList,
        Routes.onboarding,
        Routes.adminManageGroupAdmins,
        Routes.adminAddGroupAdmin,
        Routes.adminCreateParayanWithAllocation,
        Routes.vaariList,
        Routes.vaariDetail,
        Routes.adminVaariDashboard,
        Routes.adminCreateVaari,
        Routes.adminVaariDetail,
        Routes.adminVaariList,
        Routes.adminCreateSignupSheet,
        Routes.adminSignupSheetsDashboard,
        Routes.adminSignupSheetDetail,
      ];

      for (final route in routes) {
        expect(route, startsWith('/'),
            reason: '$route should start with /');
        expect(route, isNotEmpty);
      }
    });

    test('splash route is /', () {
      expect(Routes.splash, equals('/'));
    });

    test('home route is /home', () {
      expect(Routes.home, equals('/home'));
    });

    test('all routes are unique', () {
      final routes = [
        Routes.splash, Routes.home, Routes.granth, Routes.stotra,
        Routes.namavali, Routes.aarti, Routes.bhajan, Routes.sankalp,
        Routes.aboutMaharaj, Routes.calendar, Routes.donations, Routes.gallery,
        Routes.settings, Routes.socialMedia, Routes.nityopasana, Routes.signups,
        Routes.other, Routes.fontSelection, Routes.songs, Routes.naamjap,
        Routes.individualNamjap, Routes.groupNamjap, Routes.groupNamjapDetail,
        Routes.adminLogin, Routes.adminDashboard, Routes.adminTempleNotifications,
        Routes.adminParayanCoordination, Routes.adminGajananMaharajGroups,
        Routes.adminCreateParayan, Routes.adminParayanDetail, Routes.adminParayanList,
        Routes.parayanList, Routes.gajananMaharajGroups, Routes.parayanDetail,
        Routes.userNotifications, Routes.nityopasanaConsolidated, Routes.favorites,
        Routes.favoriteItemList, Routes.stories, Routes.adminTypoReports,
        Routes.adminGroupNamjapDashboard, Routes.adminCreateGroupNamjap,
        Routes.adminGroupNamjapDetail, Routes.adminGroupNamjapList,
        Routes.onboarding, Routes.adminManageGroupAdmins, Routes.adminAddGroupAdmin,
        Routes.adminCreateParayanWithAllocation, Routes.vaariList, Routes.vaariDetail,
        Routes.adminVaariDashboard, Routes.adminCreateVaari, Routes.adminVaariDetail,
        Routes.adminVaariList, Routes.adminCreateSignupSheet,
        Routes.adminSignupSheetsDashboard, Routes.adminSignupSheetDetail,
      ];
      expect(routes.toSet().length, equals(routes.length));
    });
  });
}

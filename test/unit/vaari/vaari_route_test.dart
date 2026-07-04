import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/vaari/vaari_route.dart';

void main() {
  group('dnyaneshwarPalkhiRoute', () {
    test('starts at Alandi with zero cumulative distance', () {
      expect(dnyaneshwarPalkhiRoute.first.name, 'Alandi');
      expect(dnyaneshwarPalkhiRoute.first.cumulativeMiles, 0.0);
    });

    test('ends at Pandharpur with the full route distance', () {
      expect(dnyaneshwarPalkhiRoute.last.name, 'Pandharpur');
      expect(dnyaneshwarPalkhiRoute.last.cumulativeMiles, 155.0);
    });

    test('cumulative distance is strictly increasing', () {
      for (var i = 1; i < dnyaneshwarPalkhiRoute.length; i++) {
        expect(
          dnyaneshwarPalkhiRoute[i].cumulativeMiles,
          greaterThan(dnyaneshwarPalkhiRoute[i - 1].cumulativeMiles),
        );
      }
    });

    test(
      'matches the published leg-by-leg distances scaled to a 155-mile total',
      () {
        const legs = [
          13.1,
          18.5,
          10.2,
          10.2,
          13.7,
          4.1,
          13.7,
          11.3,
          14.3,
          7.2,
          13.7,
          13.7,
          7.2,
          4.1,
        ];
        for (var i = 0; i < legs.length; i++) {
          final legDistance =
              dnyaneshwarPalkhiRoute[i + 1].cumulativeMiles -
              dnyaneshwarPalkhiRoute[i].cumulativeMiles;
          expect(legDistance, closeTo(legs[i], 0.01));
        }
      },
    );
  });

  group('distanceUnitToMiles', () {
    test('returns the value unchanged when unit is "mi"', () {
      expect(distanceUnitToMiles(100.0, 'mi'), 100.0);
    });

    test('converts km to miles', () {
      expect(distanceUnitToMiles(160.934, 'km'), closeTo(100.0, 0.001));
    });
  });

  group('milesToDistanceUnit', () {
    test('returns the value unchanged when unit is "mi"', () {
      expect(milesToDistanceUnit(100.0, 'mi'), 100.0);
    });

    test('converts miles to km', () {
      expect(milesToDistanceUnit(100.0, 'km'), closeTo(160.934, 0.001));
    });

    test('round-trips through distanceUnitToMiles', () {
      final miles = distanceUnitToMiles(42.0, 'km');
      expect(milesToDistanceUnit(miles, 'km'), closeTo(42.0, 0.0001));
    });
  });
}

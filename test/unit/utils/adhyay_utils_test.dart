import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/utils/adhyay_utils.dart';

void main() {
  group('getNextAdhyays', () {
    test('returns [1, 2, 3] for empty list', () {
      expect(getNextAdhyays([]), [1, 2, 3]);
    });

    test('returns [4, 5, 6] for [1, 2, 3]', () {
      expect(getNextAdhyays([1, 2, 3]), [4, 5, 6]);
    });

    test('wraps around: [19, 20, 21] → [1, 2, 3]', () {
      expect(getNextAdhyays([19, 20, 21]), [1, 2, 3]);
    });

    test('mid-wraparound: [20, 21, 1] → [2, 3, 4]', () {
      expect(getNextAdhyays([20, 21, 1]), [2, 3, 4]);
    });

    test('mid-cycle: [7, 8, 9] → [10, 11, 12]', () {
      expect(getNextAdhyays([7, 8, 9]), [10, 11, 12]);
    });

    test('wraparound start: [21, 1, 2] → [3, 4, 5]', () {
      expect(getNextAdhyays([21, 1, 2]), [3, 4, 5]);
    });

    test('single element [5] → [6, 7, 8]', () {
      expect(getNextAdhyays([5]), [6, 7, 8]);
    });

    test('single element at boundary [21] → [1, 2, 3]', () {
      expect(getNextAdhyays([21]), [1, 2, 3]);
    });
  });
}

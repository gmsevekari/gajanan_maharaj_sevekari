import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';

/// The strings for a slot's start/end date and time inputs.
void main() {
  late AppLocalizations en;
  late AppLocalizations mr;
  late AppLocalizations enMr;

  setUpAll(() async {
    en = await AppLocalizations.delegate.load(const Locale('en'));
    mr = await AppLocalizations.delegate.load(const Locale('mr'));
    enMr = await AppLocalizations.delegate.load(const Locale('en', 'MR'));
  });

  test('English wording', () {
    expect(en.signupSlotStartsLabel, 'Starts');
    expect(en.signupSlotEndsLabel, 'Ends');
    expect(en.signupSlotStartTimeLabel, 'Start Time');
    expect(en.signupSlotEndTimeLabel, 'End Time');
    expect(en.signupSlotTimeOptionalLabel, 'Time (optional)');
    expect(en.signupSlotClearTimeTooltip, 'Clear Time');
    expect(en.signupSlotEndBeforeStartError, 'End must be after the start');
  });

  test('every string is translated into Marathi, not left as English', () {
    final marathi = {
      'starts': mr.signupSlotStartsLabel,
      'ends': mr.signupSlotEndsLabel,
      'startTime': mr.signupSlotStartTimeLabel,
      'endTime': mr.signupSlotEndTimeLabel,
      'timeOptional': mr.signupSlotTimeOptionalLabel,
      'clearTime': mr.signupSlotClearTimeTooltip,
      'endBeforeStart': mr.signupSlotEndBeforeStartError,
    };
    final english = {
      'starts': en.signupSlotStartsLabel,
      'ends': en.signupSlotEndsLabel,
      'startTime': en.signupSlotStartTimeLabel,
      'endTime': en.signupSlotEndTimeLabel,
      'timeOptional': en.signupSlotTimeOptionalLabel,
      'clearTime': en.signupSlotClearTimeTooltip,
      'endBeforeStart': en.signupSlotEndBeforeStartError,
    };
    expect(mr.signupSlotClearTimeTooltip, 'वेळ काढून टाका');
    for (final key in marathi.keys) {
      expect(marathi[key], isNotEmpty, reason: key);
      expect(marathi[key], isNot(english[key]), reason: key);
      expect(
        RegExp(r'[ऀ-ॿ]').hasMatch(marathi[key]!),
        isTrue,
        reason: '$key should contain Devanagari',
      );
    }
  });

  test('Minglish uses the Marathi wording (there is no English loanword in '
      'any of them)', () {
    expect(enMr.signupSlotStartsLabel, mr.signupSlotStartsLabel);
    expect(enMr.signupSlotEndsLabel, mr.signupSlotEndsLabel);
    expect(enMr.signupSlotStartTimeLabel, mr.signupSlotStartTimeLabel);
    expect(enMr.signupSlotEndTimeLabel, mr.signupSlotEndTimeLabel);
    expect(enMr.signupSlotTimeOptionalLabel, mr.signupSlotTimeOptionalLabel);
    expect(enMr.signupSlotClearTimeTooltip, mr.signupSlotClearTimeTooltip);
    expect(
      enMr.signupSlotEndBeforeStartError,
      mr.signupSlotEndBeforeStartError,
    );
  });
}

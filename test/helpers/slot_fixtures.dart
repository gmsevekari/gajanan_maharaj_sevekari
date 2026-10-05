import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';
import 'package:gajanan_maharaj_sevekari/utils/event_timezone.dart';

/// A UTC instant for a wall-clock time in [timezone], independent of the
/// machine running the tests.
DateTime wallClock(
  int year,
  int month,
  int day, [
  int hour = 0,
  int minute = 0,
  String timezone = EventTimezone.pacific,
]) => wallClockToUtc(
  year: year,
  month: month,
  day: day,
  hour: hour,
  minute: minute,
  timezone: timezone,
);

/// A slot running from one wall-clock time to another in [timezone]. Leave
/// [start] null for a slot with no schedule.
SignupSlot scheduledSlot({
  String? id = 'slot_1',
  String labelEn = 'Week 1',
  String labelMr = 'आठवडा १',
  DateTime? start,
  DateTime? end,
  String timezone = EventTimezone.pacific,
  int capacity = 3,
  int claimedCount = 0,
  double? suggestedAmount,
  int sortOrder = 0,
}) => SignupSlot(
  id: id,
  labelEn: labelEn,
  labelMr: labelMr,
  startAt: start,
  endAt: end,
  timezone: timezone,
  capacity: capacity,
  claimedCount: claimedCount,
  suggestedAmount: suggestedAmount,
  sortOrder: sortOrder,
  createdAt: DateTime.utc(2026),
);

/// An all-day slot on one calendar day in [timezone].
SignupSlot allDaySlot(
  int year,
  int month,
  int day, {
  String timezone = EventTimezone.pacific,
  String labelEn = 'Week 1',
  int capacity = 3,
  int claimedCount = 0,
  double? suggestedAmount,
}) => scheduledSlot(
  labelEn: labelEn,
  start: wallClock(year, month, day, 0, 0, timezone),
  end: wallClock(year, month, day, 23, 59, timezone),
  timezone: timezone,
  capacity: capacity,
  claimedCount: claimedCount,
  suggestedAmount: suggestedAmount,
);

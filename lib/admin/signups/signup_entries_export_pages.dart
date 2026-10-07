import 'dart:math' as math;

import 'package:gajanan_maharaj_sevekari/models/signup_entry.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';

/// One image of the sign-ups export: some whole slots and their entries.
class SignupExportPage {
  /// Taller than this (in logical pixels, by [paginateSignupExport]'s
  /// estimate) and a new page is started. At the ideal pixel ratio it stays
  /// under the 8192 px many phones' GPUs can draw.
  static const double maxPageHeight = 3600;

  /// The largest image height, in device pixels, to ask a GPU for. Some
  /// devices stop at 8192.
  static const double maxTexturePixels = 8000;

  static const double idealPixelRatio = 2;
  static const double minPixelRatio = 1;

  /// Rough heights of what a page holds, deliberately on the tall side (a
  /// date or title that wraps makes a row taller than one line).
  static const double rowHeight = 64;
  static const double slotMinHeight = 100;
  static const double chromeHeight = 170;

  final List<SignupSlot> slots;
  final List<SignupEntry> entries;

  const SignupExportPage({required this.slots, required this.entries});

  /// Estimated height of the image, in logical pixels.
  double get estimatedHeight => chromeHeight + _bodyHeight(slots, entries);

  /// The sharpest ratio that keeps the image within [maxTexturePixels]: the
  /// ideal one, unless a single slot is so long it needs less.
  double get pixelRatio => (maxTexturePixels / estimatedHeight).clamp(
    minPixelRatio,
    idealPixelRatio,
  );

  static double _bodyHeight(List<SignupSlot> slots, List<SignupEntry> entries) {
    var total = 0.0;
    for (final slot in slots) {
      final count = entries.where((e) => e.slotId == slot.id).length;
      total += math.max(count * rowHeight, slotMinHeight);
    }
    return total;
  }
}

/// Splits the export of [entries] into images short enough to render: slots
/// in date order, each with its entries, filled onto a page until the next
/// would make it too tall. A slot is never split across pages, so one longer
/// than a page gets a page to itself (drawn at a lower pixel ratio). Slots
/// without entries, and entries of slots not in [slots], are left out; with no
/// entries at all there are no pages.
List<SignupExportPage> paginateSignupExport({
  required List<SignupSlot> slots,
  required List<SignupEntry> entries,
}) {
  final withEntries = [
    for (final slot in slots)
      if (entries.any((e) => e.slotId == slot.id)) slot,
  ]..sort(SignupSlot.compareByStart);

  final pages = <SignupExportPage>[];
  var pageSlots = <SignupSlot>[];
  for (final slot in withEntries) {
    final candidate = [...pageSlots, slot];
    final candidatePage = _pageOf(candidate, entries);
    if (pageSlots.isNotEmpty &&
        candidatePage.estimatedHeight > SignupExportPage.maxPageHeight) {
      pages.add(_pageOf(pageSlots, entries));
      pageSlots = [slot];
    } else {
      pageSlots = candidate;
    }
  }
  if (pageSlots.isNotEmpty) pages.add(_pageOf(pageSlots, entries));
  return pages;
}

SignupExportPage _pageOf(List<SignupSlot> slots, List<SignupEntry> entries) {
  final ids = {for (final slot in slots) slot.id};
  return SignupExportPage(
    slots: slots,
    entries: [
      for (final entry in entries)
        if (ids.contains(entry.slotId)) entry,
    ],
  );
}

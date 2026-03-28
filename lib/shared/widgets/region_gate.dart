import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/providers/region_provider.dart';
import 'package:provider/provider.dart';

class RegionGate extends StatelessWidget {
  final Widget child;
  final List<String> allowedRegions;
  final Widget? fallback;

  /// A widget that asynchronously checks RegionManager and shows/hides content.
  const RegionGate({
    super.key,
    required this.child,
    required this.allowedRegions,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    // If no specific regions are restricted, show the child directly
    if (allowedRegions.isEmpty) return child;

    // Use synchronous provider status to prevent flickering
    final regionProvider = context.watch<RegionProvider>();

    // If still initializing (should be very rare due to main.dart check),
    // show a placeholder to avoid layout shifts.
    if (!regionProvider.isInitialized) {
      return fallback ?? const SizedBox.shrink();
    }

    // Currently, we only have strict US gating
    if (allowedRegions.contains('US')) {
      if (regionProvider.isInUS) {
        return child;
      } else {
        return fallback ?? const SizedBox.shrink();
      }
    }

    // If a different region was requested but we don't handle it yet,
    // default to showing for now or add logic here.
    return child;
  }
}

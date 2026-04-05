import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/providers/festival_provider.dart';
import 'package:provider/provider.dart';

class FestivalOverlay extends StatelessWidget {
  final Widget child;

  const FestivalOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<FestivalProvider>(
      builder: (context, festivalProvider, _) {
        final activeFestival = festivalProvider.activeFestival?.id;

        if (activeFestival == 'ganesh_chaturthi') {
          return Directionality(
            textDirection: TextDirection.ltr,
            child: Stack(
              children: [
                child,
                // Top-level IgnorePointer overlay ensures it doesn't block taps
                Positioned.fill(
                  child: IgnorePointer(
                    child: _buildGaneshChaturthiOverlay(context),
                  ),
                ),
              ],
            ),
          );
        }

        // Return untouched child if no special overlay is needed
        return child;
      },
    );
  }

  Widget _buildGaneshChaturthiOverlay(BuildContext context) {
    // A composite overlay:
    // 1. Subtle gold/maroon shimmer gradient framing the edges at very low opacity
    // 2. Translucent "mandala/gear" watermark located discreetly in top corner or background

    return Stack(
      children: [
        // Subtle edge vignette
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.5,
              colors: [
                Colors.transparent,
                const Color(
                  0xFF9B3746,
                ).withValues(alpha: 0.03), // Faint maroon edges
                const Color(
                  0xFFFFD700,
                ).withValues(alpha: 0.05), // Faint gold corners
              ],
              stops: const [0.4, 0.8, 1.0],
            ),
          ),
        ),

        // Large, barely visible mandala watermark centered in bottom half
        Positioned(
          bottom: -50,
          right: -50,
          child: Opacity(
            opacity:
                0.04, // Extremely subtle so it doesn't interfere with text reading
            child: Icon(
              Icons.blur_circular, // Mandala proxy
              size: 300,
              color: const Color(0xFFFFD700), // Gold
            ),
          ),
        ),

        // Floating decorative corner element (top-right, padded enough to avoid some AppBars or subtly blend in)
        Positioned(
          top: 80,
          right: 10,
          child: Opacity(
            opacity: 0.15,
            child: Column(
              children: [
                Icon(
                  Icons.temple_hindu,
                  size: 30,
                  color: const Color(0xFFFFD700),
                ),
                Icon(Icons.flare, size: 15, color: Colors.orange),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

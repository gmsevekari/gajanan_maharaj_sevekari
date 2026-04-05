import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/providers/festival_provider.dart';
import 'package:provider/provider.dart';

class ThemedLoadingIndicator extends StatefulWidget {
  final double size;
  final Color? color;

  const ThemedLoadingIndicator({super.key, this.size = 36.0, this.color});

  @override
  State<ThemedLoadingIndicator> createState() => _ThemedLoadingIndicatorState();
}

class _ThemedLoadingIndicatorState extends State<ThemedLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeFestivalId = context.select<FestivalProvider, String?>(
      (prov) => prov.activeFestival?.id,
    );

    if (activeFestivalId == 'ganesh_chaturthi') {
      final theme = Theme.of(context);
      final effectiveColor = widget.color ?? const Color(0xFFFFD700); // Gold

      return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.rotate(
            angle: _controller.value * 2 * math.pi,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              // Chakra / Modak proxy rotating spinner
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.data_usage, // Rotating chakra feel
                    color: effectiveColor,
                    size: widget.size,
                  ),
                  Icon(
                    Icons.star, // Inner sparkle
                    color: effectiveColor.withValues(alpha: 0.5),
                    size: widget.size * 0.4,
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: CircularProgressIndicator(color: widget.color),
    );
  }
}

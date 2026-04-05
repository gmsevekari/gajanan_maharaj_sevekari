import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/providers/festival_provider.dart';
import 'package:provider/provider.dart';

class FestivalTapEffect extends StatelessWidget {
  final Widget child;

  const FestivalTapEffect({super.key, required this.child});

  void _spawnFallingPetals(BuildContext context) {
    final activeFestival = context.read<FestivalProvider>().activeFestival?.id;
    if (activeFestival != 'ganesh_chaturthi') return;

    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _FallingPetalsOverlay(
        onComplete: () => entry.remove(),
      ),
    );

    overlay.insert(entry);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _spawnFallingPetals(context),
      child: child,
    );
  }
}

class _FallingPetalsOverlay extends StatefulWidget {
  final VoidCallback onComplete;

  const _FallingPetalsOverlay({required this.onComplete});

  @override
  State<_FallingPetalsOverlay> createState() => _FallingPetalsOverlayState();
}

class _FallingPetalsOverlayState extends State<_FallingPetalsOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_PetalParticle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000), // Fall over 2 seconds
    );

    // Spawn rich falling rose petals
    final count = _random.nextInt(8) + 12; // 12-20 petals
    for (int i = 0; i < count; i++) {
      final isGold = _random.nextDouble() > 0.8;
      
      _particles.add(
        _PetalParticle(
          id: i,
          startX: _random.nextDouble() * 400, // Maps to relative screen width
          startY: -50 - _random.nextDouble() * 150, // Start slightly off top edge
          angle: _random.nextDouble() * 2 * math.pi, // Random initial spin
          distance: 600 + _random.nextDouble() * 400, // Travel down far
          size: 10 + _random.nextDouble() * 12, // Distinct shapes
          // Rich Rose Petal Colors with optional gold accent
          color: isGold
              ? const Color(0xFFFFD700)
              : [
                  Colors.pink.shade300,
                  Colors.red.shade400,
                  Colors.pinkAccent.shade200,
                ][_random.nextInt(3)],
        ),
      );
    }

    _controller.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final progress = _controller.value;
          return Stack(
            clipBehavior: Clip.none,
            children: _particles.map((p) {
              // Map 0..400 abstract coordinate to real screen width
              final startX = (p.startX / 400.0) * size.width;
              // Fall downwards with slight gravity acceleration curve
              final currentY = p.startY +
                  (p.distance * progress) +
                  (progress * progress * 150);
              // Drift horizontally simulating wind
              final currentX = startX + math.sin(progress * 5 + p.id) * 40;
              // Fade out softly at the end of the falling lifecycle
              final opacity = progress > 0.75 ? (1.0 - progress) * 4 : 1.0;

              return Positioned(
                left: currentX,
                top: currentY,
                child: Opacity(
                  opacity: math.max(0.0, opacity),
                  child: Transform.rotate(
                    angle: progress * math.pi * 4 + p.angle, // Tumble
                    child: Container(
                      width: p.size,
                      height: p.size * 1.3,
                      decoration: BoxDecoration(
                        color: p.color,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(p.size),
                          bottomRight: Radius.circular(p.size),
                          bottomLeft: Radius.circular(p.size * 0.2),
                          topRight: Radius.circular(p.size * 0.2),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _PetalParticle {
  final int id;
  final double startX;
  final double startY;
  final double angle;
  final double distance;
  final double size;
  final Color color;

  _PetalParticle({
    required this.id,
    required this.startX,
    required this.startY,
    required this.angle,
    required this.distance,
    required this.size,
    required this.color,
  });
}

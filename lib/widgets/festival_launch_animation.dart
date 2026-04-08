import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

enum FestivalAnimationType {
  fireworks,
  flowerPetals,
}

class FestivalLaunchAnimation extends StatefulWidget {
  final String message;
  final FestivalAnimationType type;
  final VoidCallback onComplete;

  const FestivalLaunchAnimation({
    super.key,
    required this.message,
    required this.type,
    required this.onComplete,
  });

  @override
  State<FestivalLaunchAnimation> createState() => _FestivalLaunchAnimationState();
}

class _FestivalLaunchAnimationState extends State<FestivalLaunchAnimation> {
  late final ConfettiController _controllerCenter;
  late final ConfettiController _controllerLeft;
  late final ConfettiController _controllerRight;
  late final ConfettiController _controllerTopLeft;
  late final ConfettiController _controllerTopRight;
  
  double _textOpacity = 0.0;
  double _ganeshaOpacity = 0.0;
  bool _showHibiscus = false;
  bool _showFireworks = false;
  double _fireworksOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    final isFireworks = widget.type == FestivalAnimationType.fireworks;
    
    // For fireworks, we want quick, explosive bursts. For petals, a consistent stream.
    // Note: Ganesh Chaturthi now uses custom hibiscus falling logic instead of confetti streams.
    final animDuration = isFireworks 
        ? const Duration(milliseconds: 100) 
        : const Duration(seconds: 4);
    
    _controllerCenter = ConfettiController(duration: animDuration);
    _controllerLeft = ConfettiController(duration: animDuration);
    _controllerRight = ConfettiController(duration: animDuration);
    _controllerTopLeft = ConfettiController(duration: animDuration);
    _controllerTopRight = ConfettiController(duration: animDuration);

    _startAnimation();
  }

  void _startAnimation() async {
    final isFireworks = widget.type == FestivalAnimationType.fireworks;

    if (isFireworks) {
      // 1. Fireworks Reveal
      setState(() {
        _showFireworks = true;
        _fireworksOpacity = 1.0;
      });

      // Firework Bursts in sequence
      _controllerCenter.play();
      await Future.delayed(const Duration(milliseconds: 400));
      _controllerLeft.play();
      _controllerTopRight.play();
      await Future.delayed(const Duration(milliseconds: 400));
      _controllerRight.play();
      _controllerTopLeft.play();

      // 2. Wait for display to mostly clear before showing message
      await Future.delayed(const Duration(seconds: 2));
    } else {
      // Ganesh Chaturthi: Hibiscus flowers falling for 4 seconds
      setState(() => _showHibiscus = true);
      
      // Wait for 4 seconds of falling (slow fall as requested)
      await Future.delayed(const Duration(seconds: 4));
      
      if (mounted) {
        setState(() {
          _showHibiscus = false; // Stop falling
          _ganeshaOpacity = 1.0;
        });
      }

      // Small delay before text appears
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (mounted) {
      setState(() {
        _textOpacity = 1.0;
      });
    }

    // 3. Auto-dismissal
    await Future.delayed(isFireworks ? const Duration(seconds: 4) : const Duration(milliseconds: 1500));
    if (mounted) {
      setState(() {
        _textOpacity = 0.0;
        _ganeshaOpacity = 0.0;
        _fireworksOpacity = 0.0;
      });
      // Wait for the longest fade (1200ms) to complete
      await Future.delayed(const Duration(milliseconds: 1200));
      widget.onComplete();
    }
  }

  /// Helper to draw circle particles for a firecracker/spark effect
  Path _drawCircle(Size size) {
    final path = Path();
    path.addOval(Rect.fromLTWH(0, 0, size.width, size.height));
    return path;
  }

  @override
  void dispose() {
    _controllerCenter.dispose();
    _controllerLeft.dispose();
    _controllerRight.dispose();
    _controllerTopLeft.dispose();
    _controllerTopRight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Choose colors based on festival type
    final List<Color> animationColors;
    if (widget.type == FestivalAnimationType.fireworks) {
      animationColors = [
        const Color(0xFFFFD700), // Gold
        const Color(0xFFFFA500), // Orange
        const Color(0xFFFFE4B5), // Moccasin
        const Color(0xFFFFFFFF), // White
        const Color(0xFFFF4500), // OrangeRed
      ];
    } else {
      // Flower Petals (Pink, Orange, Yellow, Red)
      animationColors = [
        const Color(0xFFE52B7B), // Hibiscus Pink
        const Color(0xFFFF9800), // Marigold Orange
        const Color(0xFFFFEB3B), // Yellow
        const Color(0xFFD32F2F), // Red
        const Color(0xFFF06292), // Light Pink
      ];
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          if (widget.type == FestivalAnimationType.fireworks) ...[
            // Fireworks (Explosive burst-style at multiple locations)
            if (_showFireworks)
              AnimatedOpacity(
                duration: const Duration(milliseconds: 1200),
                opacity: _fireworksOpacity,
                child: Stack(
                  children: [
                    Align(
                      alignment: const Alignment(0.0, -0.4), // Upper Center
                      child: ConfettiWidget(
                        confettiController: _controllerCenter,
                        blastDirectionality: BlastDirectionality.explosive,
                        emissionFrequency: 1.0,
                        numberOfParticles: 80,
                        maxBlastForce: 100,
                        minBlastForce: 40,
                        gravity: 0.15,
                        colors: animationColors,
                        createParticlePath: _drawCircle,
                      ),
                    ),
                    Align(
                      alignment: const Alignment(-0.6, -0.2), // Upper Left
                      child: ConfettiWidget(
                        confettiController: _controllerTopLeft,
                        blastDirectionality: BlastDirectionality.explosive,
                        emissionFrequency: 1.0,
                        numberOfParticles: 60,
                        maxBlastForce: 80,
                        minBlastForce: 30,
                        gravity: 0.15,
                        colors: animationColors,
                        createParticlePath: _drawCircle,
                      ),
                    ),
                    Align(
                      alignment: const Alignment(0.6, -0.6), // Top Right
                      child: ConfettiWidget(
                        confettiController: _controllerTopRight,
                        blastDirectionality: BlastDirectionality.explosive,
                        emissionFrequency: 1.0,
                        numberOfParticles: 60,
                        maxBlastForce: 80,
                        minBlastForce: 30,
                        gravity: 0.15,
                        colors: animationColors,
                        createParticlePath: _drawCircle,
                      ),
                    ),
                    Align(
                      alignment: const Alignment(-0.4, 0.4), // Bottom Left area
                      child: ConfettiWidget(
                        confettiController: _controllerLeft,
                        blastDirectionality: BlastDirectionality.explosive,
                        emissionFrequency: 1.0,
                        numberOfParticles: 60,
                        maxBlastForce: 80,
                        minBlastForce: 30,
                        gravity: 0.15,
                        colors: animationColors,
                        createParticlePath: _drawCircle,
                      ),
                    ),
                    Align(
                      alignment: const Alignment(0.4, 0.2), // Center Right area
                      child: ConfettiWidget(
                        confettiController: _controllerRight,
                        blastDirectionality: BlastDirectionality.explosive,
                        emissionFrequency: 1.0,
                        numberOfParticles: 60,
                        maxBlastForce: 80,
                        minBlastForce: 30,
                        gravity: 0.15,
                        colors: animationColors,
                        createParticlePath: _drawCircle,
                      ),
                    ),
                  ],
                ),
              ),
          ] else ...[
            // Hibiscus falling layer
            if (_showHibiscus)
              const _FallingHibiscusLayer(),
          ],

          // Ganesha Reveal (Always rendered to enable smooth AnimatedOpacity/Scale)
          if (widget.type == FestivalAnimationType.flowerPetals)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 1200),
                    opacity: _ganeshaOpacity,
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 1200),
                      scale: _ganeshaOpacity,
                      child: Image.asset(
                        'resources/images/festive_icons/ganesh_chaturthi/list.png',
                        width: 280,
                        height: 280,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Message Overlay (Orange radiant text with Black Border)
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 1200),
                    opacity: _textOpacity,
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 1200),
                      scale: _textOpacity > 0 ? 1.0 : 0.8,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Stroke/Border
                          Text(
                            widget.message,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              foreground: Paint()
                                ..style = PaintingStyle.stroke
                                ..strokeWidth = 4
                                ..color = Colors.black,
                            ),
                          ),
                          // Solid Text
                          Text(
                            widget.message,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.displaySmall?.copyWith(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.orange.withValues(alpha: 0.6), // Radiant glow
                                  offset: const Offset(0, 0),
                                  blurRadius: 15,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Message Overlay (Used for Diwali only now as Ganeshotsav has its own reveal column)
          if (widget.type == FestivalAnimationType.fireworks)
            Center(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 1200),
                opacity: _textOpacity,
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 1200),
                  scale: _textOpacity,
                  child: Stack(
                    children: [
                      // Stroke/Border
                      Text(
                        widget.message,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          foreground: Paint()
                            ..style = PaintingStyle.stroke
                            ..strokeWidth = 4
                            ..color = Colors.black,
                        ),
                      ),
                      // Solid Text
                      Text(
                        widget.message,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.displaySmall?.copyWith(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.orange.withValues(alpha: 0.6), // Radiant glow
                              offset: const Offset(0, 0),
                              blurRadius: 15,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FallingHibiscusLayer extends StatefulWidget {
  const _FallingHibiscusLayer();

  @override
  State<_FallingHibiscusLayer> createState() => _FallingHibiscusLayerState();
}

class _FallingHibiscusLayerState extends State<_FallingHibiscusLayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_HibiscusParticle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Spawn 45-50 hibiscus flowers for "in plenty" feel
    final count = _random.nextInt(6) + 45;
    for (int i = 0; i < count; i++) {
      _particles.add(
        _HibiscusParticle(
          id: i,
          startX: _random.nextDouble(), // 0.0 to 1.0 (relative width)
          startY: -0.4 - _random.nextDouble() * 0.8, // Start staggered high
          speed: 0.6 + _random.nextDouble() * 0.4, // Slower fall (requested)
          drift: 0.2 + _random.nextDouble() * 0.3,
          rotationSpeed: 0.5 + _random.nextDouble() * 1.2,
          scale: 0.4 + _random.nextDouble() * 0.5,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: _particles.map((p) {
            final progress = _controller.value;
            final x = (p.startX * size.width) + (math.sin(progress * 5 + p.id) * 40 * p.drift);
            // Increase Y range so they reach the bottom (1.5 factor to ensure they clear)
            final y = (p.startY + (p.speed * progress * 2.0)) * size.height;
            final rotation = progress * math.pi * 2 * p.rotationSpeed;
            final opacity = progress > 0.8 ? (1.0 - progress) * 5 : 1.0;

            return Positioned(
              left: x,
              top: y,
              child: Opacity(
                opacity: math.max(0.0, opacity),
                child: Transform.rotate(
                  angle: rotation,
                  child: Image.asset(
                  'resources/images/festive_icons/ganesh_chaturthi/hibiscus.png',
                  width: 60 * p.scale,
                  height: 60 * p.scale,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _HibiscusParticle {
  final int id;
  final double startX;
  final double startY;
  final double speed;
  final double drift;
  final double rotationSpeed;
  final double scale;

  _HibiscusParticle({
    required this.id,
    required this.startX,
    required this.startY,
    required this.speed,
    required this.drift,
    required this.rotationSpeed,
    required this.scale,
  });
}

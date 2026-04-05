import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';

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
  
  bool _showText = false;
  double _textOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _controllerCenter = ConfettiController(duration: const Duration(seconds: 3));
    _controllerLeft = ConfettiController(duration: const Duration(seconds: 3));
    _controllerRight = ConfettiController(duration: const Duration(seconds: 3));

    _startAnimation();
  }

  void _startAnimation() async {
    // 1. Initial burst
    _controllerCenter.play();
    
    await Future.delayed(const Duration(milliseconds: 500));
    _controllerLeft.play();
    _controllerRight.play();

    // 2. Show text
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _showText = true;
        _textOpacity = 1.0;
      });
    }

    // 3. Auto-dismissal
    await Future.delayed(const Duration(seconds: 4));
    if (mounted) {
      setState(() {
        _textOpacity = 0.0;
      });
      await Future.delayed(const Duration(milliseconds: 500));
      widget.onComplete();
    }
  }

  @override
  void dispose() {
    _controllerCenter.dispose();
    _controllerLeft.dispose();
    _controllerRight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Choose colors based on festival type
    final List<Color> animationColors;
    if (widget.type == FestivalAnimationType.fireworks) {
      animationColors = [
        const Color(0xFFF2C249), // Gold
        const Color(0xFFE52B7B), // Pink
        const Color(0xFF154C8C), // Royal Blue
        const Color(0xFFD50000), // Cherry Red
        const Color(0xFF388E3C), // Green
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
            // Fireworks (Bottom-Up)
            Align(
              alignment: Alignment.bottomLeft,
              child: ConfettiWidget(
                confettiController: _controllerLeft,
                blastDirection: -math.pi / 1.5, // Up and Left
                emissionFrequency: 0.1,
                numberOfParticles: 20,
                maxBlastForce: 100,
                minBlastForce: 50,
                gravity: 0.1,
                colors: animationColors,
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: ConfettiWidget(
                confettiController: _controllerRight,
                blastDirection: -math.pi / 3, // Up and Right
                emissionFrequency: 0.1,
                numberOfParticles: 20,
                maxBlastForce: 100,
                minBlastForce: 50,
                gravity: 0.1,
                colors: animationColors,
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: ConfettiWidget(
                confettiController: _controllerCenter,
                blastDirection: -math.pi / 2, // Straight Up
                emissionFrequency: 0.1,
                numberOfParticles: 30,
                maxBlastForce: 120,
                minBlastForce: 60,
                gravity: 0.1,
                colors: animationColors,
              ),
            ),
          ] else ...[
            // Flower Petals (Top-Down)
            Align(
              alignment: Alignment.topLeft,
              child: ConfettiWidget(
                confettiController: _controllerLeft,
                blastDirection: math.pi / 3, // Down and Right
                emissionFrequency: 0.05,
                numberOfParticles: 15,
                maxBlastForce: 30,
                minBlastForce: 10,
                gravity: 0.1,
                colors: animationColors,
              ),
            ),
            Align(
              alignment: Alignment.topRight,
              child: ConfettiWidget(
                confettiController: _controllerRight,
                blastDirection: 2 * math.pi / 3, // Down and Left
                emissionFrequency: 0.05,
                numberOfParticles: 15,
                maxBlastForce: 30,
                minBlastForce: 10,
                gravity: 0.1,
                colors: animationColors,
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _controllerCenter,
                blastDirection: math.pi / 2, // Straight Down
                emissionFrequency: 0.1,
                numberOfParticles: 30,
                maxBlastForce: 40,
                minBlastForce: 20,
                gravity: 0.1,
                colors: animationColors,
              ),
            ),
          ],

          // Message Overlay
          if (_showText)
            Center(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 800),
                opacity: _textOpacity,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                      color: theme.appColors.primarySwatch,
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.appColors.primarySwatch.withValues(alpha: 0.3),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Text(
                    widget.message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: theme.appColors.primarySwatch,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        const Shadow(
                          color: Colors.black,
                          offset: Offset(2, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

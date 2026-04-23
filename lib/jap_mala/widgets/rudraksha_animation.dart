import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';

class RudrakshaAnimation extends StatelessWidget {
  final Animation<double> animation;
  final double beadHeight;
  final int visibleBeads;
  final bool compact;
  final bool enabled;

  const RudrakshaAnimation({
    super.key,
    required this.animation,
    required this.beadHeight,
    required this.visibleBeads,
    this.compact = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRect(
      child: Center(
        child: SizedBox(
          height: beadHeight * visibleBeads,
          width: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Custom Image Watermark
              Positioned.fill(
                child: Opacity(
                  opacity: 0.30,
                  child: IgnorePointer(
                    child: Image.asset(
                      'resources/images/naamjap/Om.png',
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                    ),
                  ),
                ),
              ),
              // Animated Beads Area
              SizedBox(
                height: beadHeight * visibleBeads,
                width: 100,
                child: AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: List.generate(visibleBeads + 1, (index) {
                        final topOffset = (index - 1) * beadHeight - animation.value;

                        final centerPoint = (beadHeight * visibleBeads) / 2;
                        final distanceFromCenter =
                            (topOffset + beadHeight / 2 - centerPoint).abs();
                        final maxDistance = (beadHeight * visibleBeads) / 2;
                        final opacity =
                            (1 - (distanceFromCenter / maxDistance)).clamp(0.0, 1.0);

                        return Positioned(
                          top: topOffset,
                          child: Opacity(
                            opacity: enabled ? opacity : opacity * 0.5,
                            child: SizedBox(
                              width: compact ? 56 : 64,
                              height: beadHeight,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Positioned(
                                    top: 0,
                                    bottom: 0,
                                    left: compact ? 25 : 29,
                                    right: compact ? 25 : 29,
                                    child: CustomPaint(
                                      painter: MalaThreadPainter(
                                        primaryColor: theme.appColors.primarySwatch.shade800,
                                        secondaryColor: theme.appColors.primarySwatch.shade400,
                                        borderAlphaColor:
                                            theme.appColors.secondaryText.withValues(alpha: 0.3),
                                      ),
                                    ),
                                  ),
                                  Image.asset(
                                    'resources/images/naamjap/Rudraksha.png',
                                    height: compact ? 64 : 72,
                                    width: compact ? 64 : 72,
                                    fit: BoxFit.contain,
                                    color: enabled ? null : Colors.grey,
                                    colorBlendMode: enabled ? null : BlendMode.saturation,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: compact ? 40 : 48,
                                        height: compact ? 40 : 48,
                                        decoration: BoxDecoration(
                                          color: theme.appColors.primarySwatch.shade800,
                                          shape: BoxShape.circle,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MalaThreadPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final Color borderAlphaColor;

  MalaThreadPainter({
    required this.primaryColor,
    required this.secondaryColor,
    required this.borderAlphaColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [primaryColor, secondaryColor, primaryColor],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path()
      ..addRect(Rect.fromLTWH(size.width / 4, 0, size.width / 2, size.height));

    canvas.drawPath(path, paint);

    final borderPaint = Paint()
      ..color = borderAlphaColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(size.width / 4, 0),
      Offset(size.width / 4, size.height),
      borderPaint,
    );
    canvas.drawLine(
      Offset(3 * size.width / 4, 0),
      Offset(3 * size.width / 4, size.height),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

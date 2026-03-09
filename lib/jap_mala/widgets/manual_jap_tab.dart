import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';

class ManualJapTab extends StatefulWidget {
  const ManualJapTab({super.key});

  @override
  State<ManualJapTab> createState() => _ManualJapTabState();
}

class _ManualJapTabState extends State<ManualJapTab>
    with SingleTickerProviderStateMixin {
  int _currentCount = 0;
  int _completedMalas = 0;
  final int _countsPerMala = 108;
  late AnimationController _controller;
  late Animation<double> _animation;
  static const double _beadHeight = 90.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _animation = Tween<double>(
      begin: 0,
      end: _beadHeight,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    // Re-center when animation finishes
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reset();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onBeadPulled() {
    if (_controller.isAnimating) return;

    HapticFeedback.lightImpact();
    setState(() {
      _currentCount++;
      if (_currentCount >= _countsPerMala) {
        _completedMalas++;
        _currentCount = 0;
        HapticFeedback.heavyImpact();
      }
    });
    // Start sliding animation
    _controller.forward();
  }

  void _decreaseCount() {
    setState(() {
      if (_currentCount > 0) {
        _currentCount--;
      } else if (_completedMalas > 0) {
        _completedMalas--;
        _currentCount = _countsPerMala - 1;
      }
    });
  }

  void _resetCount() {
    setState(() {
      _currentCount = 0;
      _completedMalas = 0;
    });
  }

  String _formatNumber(BuildContext context, int number, {bool pad = true}) {
    String numStr = pad ? number.toString().padLeft(2, '0') : number.toString();
    final isMarathi = Localizations.localeOf(context).languageCode == 'mr';
    if (!isMarathi) return numStr;

    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const marathi = ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'];
    for (int i = 0; i < english.length; i++) {
      numStr = numStr.replaceAll(english[i], marathi[i]);
    }
    return numStr;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Container(
      color: theme.scaffoldBackgroundColor, // Use theme background
      child: Column(
        children: [
          // Progress Indicators (Cards)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 24.0,
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color ?? theme.cardColor,
                        border: Border.all(color: Colors.orange, width: 2),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            localizations.mala,
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _formatNumber(context, _completedMalas),
                              style: const TextStyle(
                                color: Colors.orange,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color ?? theme.cardColor,
                        border: Border.all(color: Colors.orange, width: 2),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            localizations.jap,
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '${_formatNumber(context, _currentCount)} / ${_formatNumber(context, _countsPerMala, pad: false)}',
                              style: const TextStyle(
                                color: Colors.orange,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: ClipRect(
              child: Center(
                // The Interactive Mala with Mandala Watermark
                child: SizedBox(
                  height: _beadHeight * 5,
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
                        height: _beadHeight * 5,
                        width: 100,
                        child: AnimatedBuilder(
                          animation: _animation,
                          builder: (context, child) {
                            return Stack(
                              alignment: Alignment.center,
                              children: List.generate(6, (index) {
                                final topOffset =
                                    (index - 1) * _beadHeight -
                                    _animation.value;

                                final centerPoint = (_beadHeight * 5) / 2;
                                final distanceFromCenter =
                                    (topOffset + _beadHeight / 2 - centerPoint)
                                        .abs();
                                final maxDistance = (_beadHeight * 5) / 2;
                                final opacity =
                                    (1 - (distanceFromCenter / maxDistance))
                                        .clamp(0.0, 1.0);

                                return Positioned(
                                  top: topOffset,
                                  child: Opacity(
                                    opacity: opacity as double,
                                    child: SizedBox(
                                      width: 64,
                                      height: 95,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          // Thread runs full height through centre
                                          Positioned(
                                            top: 0,
                                            bottom: 0,
                                            left: 29,
                                            right: 29,
                                            child: CustomPaint(
                                              painter: MalaThreadPainter(
                                                primaryColor:
                                                    Colors.orange.shade800,
                                                secondaryColor:
                                                    Colors.orange.shade400,
                                              ),
                                            ),
                                          ),
                                          // Bead overlaid — thread shows through
                                          // transparent PNG edges, hiding the gap
                                          Image.asset(
                                            'resources/images/naamjap/Rudraksha.png',
                                            height: 72,
                                            width: 72,
                                            fit: BoxFit.contain,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Container(
                                                    width: 48,
                                                    height: 48,
                                                    decoration:
                                                        const BoxDecoration(
                                                          color: Colors.brown,
                                                          shape:
                                                              BoxShape.circle,
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
            ),
          ),

          // Interaction Controls
          Padding(
            padding: const EdgeInsets.only(bottom: 40.0),
            child: Column(
              children: [
                // Central Tap Button
                ElevatedButton(
                  onPressed: _onBeadPulled,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 16,
                    ),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text(
                    '+',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ),

                const SizedBox(height: 24),

                // Secondary Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSecondaryButton(Icons.remove, _decreaseCount, theme),
                    const SizedBox(width: 60),
                    _buildSecondaryButton(Icons.refresh, _resetCount, theme),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryButton(
    IconData icon,
    VoidCallback onTap,
    ThemeData theme,
  ) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        fixedSize: const Size(56, 56),
        shape: const CircleBorder(
          side: BorderSide(color: Colors.orange, width: 2),
        ),
        backgroundColor: theme.cardTheme.color ?? theme.cardColor,
        foregroundColor: Colors.orange,
        padding: EdgeInsets.zero,
        elevation: 4, // Matches the '+' button style
      ),
      child: Icon(icon, color: Colors.orange, size: 28),
    );
  }
}

class MalaThreadPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;

  MalaThreadPainter({required this.primaryColor, required this.secondaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    // Fill background
    final bgPaint = Paint()..color = primaryColor;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(2),
    );
    canvas.drawRRect(rrect, bgPaint);

    // Draw diagonal lines to simulate a twisted cord
    final dashPaint = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final double spacing = 4.0;
    canvas.save();
    canvas.clipRRect(rrect);
    for (double y = -size.width; y < size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y + size.width),
        dashPaint,
      );
    }
    canvas.restore();

    // Add a slight dark border to give it depth
    final borderPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawRRect(rrect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

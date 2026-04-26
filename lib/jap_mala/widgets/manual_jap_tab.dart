import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/providers/jap_mala_provider.dart';
import 'package:gajanan_maharaj_sevekari/utils/marathi_utils.dart';
import 'package:provider/provider.dart';

import 'jap_control_buttons.dart';
import 'mala_count_card.dart';
import 'rudraksha_animation.dart';

class ManualJapTab extends StatefulWidget {
  final bool compact;
  final bool enabled;
  const ManualJapTab({super.key, this.compact = false, this.enabled = true});

  @override
  State<ManualJapTab> createState() => _ManualJapTabState();
}

class _ManualJapTabState extends State<ManualJapTab>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double get _beadHeight => widget.compact ? 80.0 : 95.0;
  int get _visibleBeads => widget.compact ? 5 : 5;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = Tween<double>(
      begin: 0,
      end: _beadHeight,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(ManualJapTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.compact != widget.compact) {
      _animation = Tween<double>(
        begin: 0,
        end: _beadHeight,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startAnimation() {
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isScrollable = constraints.maxHeight == double.infinity;
        return Consumer<JapMalaProvider>(
          builder: (context, provider, child) {
            final locale = Localizations.localeOf(context).languageCode;
            return Container(
              color: theme.scaffoldBackgroundColor,
              child: Column(
                mainAxisSize: isScrollable ? MainAxisSize.min : MainAxisSize.max,
                children: [
                  // Progress Indicators (Cards) - Hidden in compact mode
                  if (!widget.compact)
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
                              child: MalaCountCard(
                                label: localizations.mala,
                                value: formatNumberLocalized(provider.completedMalas, locale),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: MalaCountCard(
                                label: localizations.jap,
                                value:
                                    '${formatNumberLocalized(provider.currentCount, locale)} / १०८',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (widget.compact)
                    _buildCompactLayout(context, provider)
                  else
                    Expanded(child: _buildBeadsArea()),

                  // Control Buttons (Hidden in compact because they are in compact layout)
                  if (!widget.compact)
                    JapControlButtons(
                      compact: widget.compact,
                      enabled: widget.enabled,
                      onIncrement: () {
                        HapticFeedback.lightImpact();
                        context.read<JapMalaProvider>().increment();
                        _startAnimation();
                      },
                      onDecrement: () {
                        HapticFeedback.lightImpact();
                        context.read<JapMalaProvider>().decrement();
                      },
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCompactLayout(BuildContext context, JapMalaProvider provider) {
    final isEnabled = widget.enabled;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Row(
        children: [
          // Left Side: Minus button
          JapControlButtons.buildSecondaryButton(
            context: context,
            icon: Icons.remove,
            isEnabled: isEnabled,
            compact: true,
            onTap: () {
              HapticFeedback.lightImpact();
              provider.decrement();
            },
          ),
          // Spacing before animation
          const SizedBox(width: 12),
          // Center: Animation
          Expanded(
            child: _buildBeadsArea(),
          ),
          // Spacing after animation
          const SizedBox(width: 12),
          // Right Side: Large + button
          JapControlButtons.buildIncrementButton(
            context: context,
            isEnabled: isEnabled,
            compact: true,
            onTap: () {
              HapticFeedback.lightImpact();
              provider.increment();
              _startAnimation();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBeadsArea() {
    return RudrakshaAnimation(
      animation: _animation,
      beadHeight: _beadHeight,
      visibleBeads: _visibleBeads,
      compact: widget.compact,
      enabled: widget.enabled,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';

class JapControlButtons extends StatelessWidget {
  final bool compact;
  final bool enabled;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  const JapControlButtons({
    super.key,
    required this.compact,
    required this.enabled,
    this.onIncrement,
    this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = enabled;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 16.0 : 24.0),
      child: Column(
        children: [
          // Large circular + button
          buildIncrementButton(
            context: context,
            isEnabled: isEnabled,
            compact: compact,
            onTap: onIncrement,
          ),
          SizedBox(height: compact ? 20 : 32),
          // Secondary control row (just minus button)
          buildSecondaryButton(
            context: context,
            icon: Icons.remove,
            isEnabled: isEnabled,
            compact: compact,
            onTap: onDecrement,
          ),
        ],
      ),
    );
  }

  static Widget buildIncrementButton({
    required BuildContext context,
    required bool isEnabled,
    required bool compact,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        width: compact ? 72 : 80,
        height: compact ? 44 : 50,
        decoration: BoxDecoration(
          color: isEnabled
              ? theme.appColors.primarySwatch
              : theme.appColors.disabledBackground,
          borderRadius: BorderRadius.circular(25),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: theme.appColors.primarySwatch.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Icon(
          Icons.add,
          color: isEnabled ? Colors.white : theme.appColors.disabledText,
          size: compact ? 28 : 32,
        ),
      ),
    );
  }

  static Widget buildSecondaryButton({
    required BuildContext context,
    required IconData icon,
    required bool isEnabled,
    required bool compact,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final size = compact ? 40.0 : 48.0;
    return InkWell(
      onTap: isEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(size / 2),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isEnabled
              ? null
              : theme.appColors.disabledBackground.withValues(alpha: 0.1),
          border: Border.all(
            color: isEnabled
                ? theme.appColors.primarySwatch.withValues(alpha: 0.3)
                : theme.appColors.disabledText.withValues(alpha: 0.2),
            width: 2,
          ),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isEnabled
              ? theme.appColors.primarySwatch
              : theme.appColors.disabledText,
          size: compact ? 20 : 24,
        ),
      ),
    );
  }
}

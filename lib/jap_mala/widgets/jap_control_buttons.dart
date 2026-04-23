import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';

class JapControlButtons extends StatelessWidget {
  final bool compact;
  final bool enabled;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final VoidCallback? onReset;

  const JapControlButtons({
    super.key,
    required this.compact,
    required this.enabled,
    this.onIncrement,
    this.onDecrement,
    this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = enabled;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 16.0 : 24.0),
      child: Column(
        children: [
          // Large circular + button
          GestureDetector(
            onTap: isEnabled ? onIncrement : null,
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
          ),
          SizedBox(height: compact ? 20 : 32),
          // Secondary control row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Minus button
              _buildSecondaryButton(
                theme,
                Icons.remove,
                isEnabled ? onDecrement : null,
                compact,
              ),
              SizedBox(width: compact ? 40 : 48),
              // Reset button
              _buildSecondaryButton(
                theme,
                Icons.refresh,
                isEnabled ? onReset : null,
                compact,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryButton(
    ThemeData theme,
    IconData icon,
    VoidCallback? onPressed,
    bool compact,
  ) {
    final isEnabled = onPressed != null;
    final size = compact ? 40.0 : 48.0;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(size / 2),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isEnabled ? null : theme.appColors.disabledBackground.withValues(alpha: 0.1),
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
          color: isEnabled ? theme.appColors.primarySwatch : theme.appColors.disabledText,
          size: compact ? 20 : 24,
        ),
      ),
    );
  }
}

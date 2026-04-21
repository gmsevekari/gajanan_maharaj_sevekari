import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  const StatCard({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 1.2,
                color: theme.appColors.secondaryText,
              ),
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProgressStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtext;
  final double progress;

  const ProgressStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.subtext,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 1.2,
                color: theme.appColors.secondaryText,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 54,
                    width: 54,
                    child: CircularProgressIndicator(
                      value: progress,
                      backgroundColor: theme.colorScheme.onSurface.withValues(
                        alpha: 0.1,
                      ),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                      strokeWidth: 4,
                    ),
                  ),
                  Text(
                    value,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';

/// A sign-up sheet's title, description, and group chip, shown at the top
/// of [AdminSignupDetailScreen].
class SignupOverviewCard extends StatelessWidget {
  final String title;
  final String description;
  final String groupName;

  const SignupOverviewCard({
    super.key,
    required this.title,
    required this.description,
    required this.groupName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (groupName.isNotEmpty)
                  Chip(
                    label: Text(groupName),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.appColors.secondaryText,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

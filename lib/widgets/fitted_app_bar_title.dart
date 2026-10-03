import 'package:flutter/material.dart';

/// An app-bar title that shrinks to fit the available width rather than
/// being cut off with an ellipsis - the same treatment the Vaari, Parayan
/// and Group Namjap screens apply to their (often long, admin-entered)
/// titles.
class FittedAppBarTitle extends StatelessWidget {
  final String title;

  const FittedAppBarTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          color: theme.colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

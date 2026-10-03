import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:gajanan_maharaj_sevekari/widgets/fitted_app_bar_title.dart';
import 'package:gajanan_maharaj_sevekari/widgets/themed_icon.dart';

/// The admin sign-up sub-screens' shared frame: a title, home and settings
/// buttons, and Upcoming / Past tabs that can't be swiped between (the tab
/// bar is the only way to switch).
class AdminSignupTabbedScaffold extends StatelessWidget {
  final String title;
  final TabController controller;
  final Widget upcoming;
  final Widget past;

  const AdminSignupTabbedScaffold({
    super.key,
    required this.title,
    required this.controller,
    required this.upcoming,
    required this.past,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: FittedAppBarTitle(title),
        bottom: TabBar(
          controller: controller,
          // The default label colour is the theme's primary, which is the
          // app bar's own colour, so the selected tab would be invisible.
          labelColor: theme.colorScheme.onPrimary,
          unselectedLabelColor: theme.colorScheme.onPrimary.withValues(
            alpha: 0.7,
          ),
          indicatorColor: theme.colorScheme.onPrimary,
          tabs: [
            Tab(text: l10n.signupUpcomingTab),
            Tab(text: l10n.signupPastTab),
          ],
        ),
        actions: [
          IconButton(
            icon: const ThemedIcon(LogicalIcon.home),
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
          ),
          IconButton(
            icon: const ThemedIcon(LogicalIcon.settings),
            onPressed: () => Navigator.pushNamed(context, Routes.settings),
          ),
        ],
      ),
      body: TabBarView(
        physics: const NeverScrollableScrollPhysics(),
        controller: controller,
        children: [upcoming, past],
      ),
    );
  }
}

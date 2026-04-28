import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/providers/app_config_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/group_selection_provider.dart';
import 'package:gajanan_maharaj_sevekari/shared/gajanan_maharaj_group_screen.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:gajanan_maharaj_sevekari/widgets/themed_icon.dart';
import 'package:provider/provider.dart';

class NamjapScreen extends StatelessWidget {
  const NamjapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.namjapTitle),
        centerTitle: true,
        backgroundColor: theme.appColors.primarySwatch,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const ThemedIcon(LogicalIcon.home),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              Routes.home,
              (route) => false,
            ),
          ),
          IconButton(
            icon: const ThemedIcon(LogicalIcon.settings),
            onPressed: () => Navigator.pushNamed(context, Routes.settings),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSelectionCard(
            context: context,
            title: localizations.individualNamjapLabel,
            description: localizations.individualNamjapDescription,
            icon: LogicalIcon.person,
            fallbackIcon: Icons.person,
            route: Routes.individualNamjap,
          ),
          const SizedBox(height: 16.0),
          _buildSelectionCard(
            context: context,
            title: localizations.groupNamjapLabel,
            description: localizations.groupNamjapDescription,
            icon: LogicalIcon.groups,
            fallbackIcon: Icons.groups,
            onTap: () {
              final selectedGroupIds =
                  context.read<GroupSelectionProvider>().selectedGroupIds;

              if (selectedGroupIds.length == 1) {
                final groupId = selectedGroupIds.first;
                final configProvider = context.read<AppConfigProvider>();
                final group = configProvider.appConfig?.gajananMaharajGroups
                    .firstWhere((g) => g.id == groupId);
                final locale = Localizations.localeOf(context).languageCode;
                final groupName =
                    locale == 'mr' ? group?.nameMr : group?.nameEn;

                Navigator.pushNamed(
                  context,
                  Routes.groupNamjap,
                  arguments: {'groupId': groupId, 'groupName': groupName},
                );
              } else {
                Navigator.pushNamed(
                  context,
                  Routes.gajananMaharajGroups,
                  arguments: GroupScreenConfig(
                    title: localizations.groupNamjapLabel,
                    emptyMessage: selectedGroupIds.isEmpty
                        ? localizations.noNamjapGroupsSelectedMessage
                        : localizations.groupNamjapNoOngoing,
                    targetRoute: Routes.groupNamjap,
                    filteredGroupIds: selectedGroupIds,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionCard({
    required BuildContext context,
    required String title,
    required String description,
    required LogicalIcon icon,
    required IconData fallbackIcon,
    String? route,
    VoidCallback? onTap,
    Object? arguments,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: theme.cardTheme.elevation,
      color: theme.cardTheme.color,
      shape: theme.cardTheme.shape,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: theme.appColors.primarySwatch[100],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: ThemedIcon(
              icon,
              size: 32,
              color: theme.colorScheme.primary,
              fallbackIcon: fallbackIcon,
            ),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 18.0,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            description,
            style: TextStyle(
              color: theme.appColors.secondaryText,
              fontSize: 14.0,
            ),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: theme.colorScheme.primary,
          size: 16.0,
        ),
        onTap:
            onTap ??
            () => Navigator.pushNamed(context, route!, arguments: arguments),
      ),
    );
  }
}

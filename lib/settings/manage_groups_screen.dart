import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/app_config.dart';
import 'package:gajanan_maharaj_sevekari/providers/app_config_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/group_selection_provider.dart';
import 'package:provider/provider.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:gajanan_maharaj_sevekari/widgets/themed_icon.dart';

class ManageGroupsScreen extends StatelessWidget {
  const ManageGroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.manageGroups),
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
            onPressed: () {
              Navigator.popUntil(
                context,
                (route) =>
                    route.settings.name == Routes.settings || route.isFirst,
              );
            },
          ),
        ],
      ),
      body: Consumer2<AppConfigProvider, GroupSelectionProvider>(
        builder: (context, configProvider, groupProvider, child) {
          final allGroups =
              configProvider.appConfig?.gajananMaharajGroups ?? [];
          final activeIds = groupProvider.selectedGroupIds;

          // Create a lookup map for O(1) resolution
          final allGroupsMap = {for (final g in allGroups) g.id: g};

          // Resolve active groups in their exact order
          final activeGroups = activeIds
              .map((id) => allGroupsMap[id])
              .whereType<GajananMaharajGroup>()
              .toList();

          // Resolve available groups (not in active list)
          final availableGroups = allGroups
              .where((g) => !activeIds.contains(g.id))
              .toList();

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations.activeGroups,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (activeGroups.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            localizations.dragToReorder,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (activeGroups.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(localizations.noActiveGroups),
                  ),
                )
              else
                SliverReorderableList(
                  itemCount: activeGroups.length,
                  itemBuilder: (context, index) {
                    final group = activeGroups[index];
                    final name = locale == 'mr' ? group.nameMr : group.nameEn;
                    return _buildActiveGroupItem(
                      key: ValueKey(group.id),
                      context: context,
                      group: group,
                      name: name,
                      index: index,
                      onRemove: () {
                        groupProvider.removeGroup(group.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(localizations.groupRemoved)),
                        );
                      },
                    );
                  },
                  onReorder: (oldIndex, newIndex) {
                    groupProvider.reorderGroups(oldIndex, newIndex);
                  },
                ),
              if (availableGroups.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(),
                        const SizedBox(height: 8),
                        Text(
                          localizations.availableGroups,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (availableGroups.isNotEmpty)
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final group = availableGroups[index];
                    final name = locale == 'mr' ? group.nameMr : group.nameEn;
                    return Card(
                      key: ValueKey('available_${group.id}'),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 6.0,
                      ),
                      elevation: theme.cardTheme.elevation ?? 2.0,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 4.0,
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            Icons.add_circle,
                            color: theme.colorScheme.primary,
                          ),
                          onPressed: () {
                            groupProvider.addGroup(group.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(localizations.groupAdded)),
                            );
                          },
                        ),
                      ),
                    );
                  }, childCount: availableGroups.length),
                ),
              // Bottom padding
              const SliverToBoxAdapter(child: SizedBox(height: 32.0)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActiveGroupItem({
    required Key key,
    required BuildContext context,
    required GajananMaharajGroup group,
    required String name,
    required int index,
    required VoidCallback onRemove,
  }) {
    final theme = Theme.of(context);

    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Material(
        color: Colors.transparent,
        child: Card(
          margin: EdgeInsets.zero,
          elevation: theme.cardTheme.elevation ?? 2.0,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 4.0,
            ),
            title: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            leading: ReorderableDragStartListener(
              index: index,
              child: Icon(Icons.drag_indicator, color: theme.hintColor),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.remove_circle, color: Colors.red),
              onPressed: onRemove,
            ),
          ),
        ),
      ),
    );
  }
}

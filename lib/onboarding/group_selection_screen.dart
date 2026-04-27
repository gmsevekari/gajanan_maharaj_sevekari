import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/providers/app_config_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/group_selection_provider.dart';
import 'package:provider/provider.dart';
import 'package:gajanan_maharaj_sevekari/models/app_config.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:gajanan_maharaj_sevekari/utils/deeplink_manager.dart';

class GroupSelectionScreen extends StatefulWidget {
  const GroupSelectionScreen({super.key});

  @override
  State<GroupSelectionScreen> createState() => _GroupSelectionScreenState();
}

class _GroupSelectionScreenState extends State<GroupSelectionScreen> {
  List<String>? _orderedIds;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);

    return Scaffold(
      body: Consumer2<AppConfigProvider, GroupSelectionProvider>(
        builder: (context, configProvider, groupProvider, child) {
          final allGroups =
              configProvider.appConfig?.gajananMaharajGroups ?? [];

          // Initialize ordered IDs if not already done
          if (_orderedIds == null && allGroups.isNotEmpty) {
            _orderedIds = allGroups.map((g) => g.id).toList();
          }

          final selectedIds = groupProvider.selectedGroupIds;

          // Create a map for quick lookup
          final groupsMap = {for (final g in allGroups) g.id: g};
          final displayGroups =
              (_orderedIds ?? [])
                  .map((id) => groupsMap[id])
                  .whereType<GajananMaharajGroup>()
                  .toList();

          return SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer
                                      .withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Image.asset(
                                  'resources/images/logo/App_Logo.png',
                                  height: 80,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                localizations.onboardingWelcome,
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                localizations.onboardingDescription,
                                style: theme.textTheme.bodyLarge,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 32),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  localizations.availableGroups,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverReorderableList(
                        itemCount: displayGroups.length,
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (oldIndex < newIndex) {
                              newIndex -= 1;
                            }
                            final item = _orderedIds!.removeAt(oldIndex);
                            _orderedIds!.insert(newIndex, item);
                          });
                        },
                        itemBuilder: (context, index) {
                          final group = displayGroups[index];
                          final isSelected = selectedIds.contains(group.id);
                          final name =
                              locale == 'mr' ? group.nameMr : group.nameEn;

                          return Padding(
                            key: ValueKey(group.id),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            child: Card(
                              margin: EdgeInsets.zero,
                              shape: isSelected
                                  ? (theme.cardTheme.shape
                                          as RoundedRectangleBorder?)
                                      ?.copyWith(
                                        side: BorderSide(
                                          color: theme.colorScheme.primary,
                                          width: 2,
                                        ),
                                      )
                                  : theme.cardTheme.shape,
                              child: CheckboxListTile(
                                value: isSelected,
                                onChanged: (value) {
                                  if (value == true) {
                                    groupProvider.addGroup(group.id);
                                  } else {
                                    groupProvider.removeGroup(group.id);
                                  }
                                },
                                title: Text(
                                  name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                secondary: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ReorderableDragStartListener(
                                      index: index,
                                      child: Icon(
                                        Icons.drag_indicator,
                                        color: theme.hintColor,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    CircleAvatar(
                                      backgroundColor: isSelected
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.surfaceContainerHighest,
                                      backgroundImage:
                                          group.icon != null &&
                                                  group.icon!.isNotEmpty
                                              ? AssetImage(group.icon!)
                                              : null,
                                      child: group.icon == null ||
                                              group.icon!.isEmpty
                                          ? Icon(
                                              Icons.location_on_outlined,
                                              color: isSelected
                                                  ? theme.colorScheme.onPrimary
                                                  : theme.colorScheme
                                                      .onSurfaceVariant,
                                            )
                                          : null,
                                    ),
                                  ],
                                ),
                                checkboxShape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _finishOnboarding(context),
                      child: Text(localizations.finishOnboarding),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _finishOnboarding(BuildContext context) async {
    final groupProvider =
        Provider.of<GroupSelectionProvider>(context, listen: false);

    // 1. Ensure selected groups follow the order on screen
    if (_orderedIds != null) {
      final selectedIds = groupProvider.selectedGroupIds;
      final orderedSelected =
          _orderedIds!
              .where((id) => selectedIds.contains(id))
              .toList();
      await groupProvider.setSelectedGroups(orderedSelected);
    }

    // 2. Mark onboarding as done
    await groupProvider.completeOnboarding();

    if (!context.mounted) return;

    // 3. Navigate to Home
    Navigator.of(context).pushReplacementNamed(Routes.home);

    if (!context.mounted) return;

    // 4. Check for pending deep link
    final pendingDeepLink = DeepLinkManager.consumePendingRoute();
    if (pendingDeepLink != null) {
      Navigator.of(context).pushNamed(
        pendingDeepLink['route'],
        arguments: pendingDeepLink['arguments'],
      );
    }
  }
}

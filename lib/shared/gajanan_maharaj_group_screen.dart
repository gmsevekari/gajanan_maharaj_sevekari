import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/providers/app_config_provider.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:provider/provider.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';

class GroupScreenConfig {
  final String title;
  final String emptyMessage;
  final String targetRoute;
  final List<String>? filteredGroupIds;

  GroupScreenConfig({
    required this.title,
    required this.emptyMessage,
    required this.targetRoute,
    this.filteredGroupIds,
  });
}

class GajananMaharajGroupScreen extends StatelessWidget {
  const GajananMaharajGroupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final configProvider = Provider.of<AppConfigProvider>(context);
    final allGroups = configProvider.appConfig?.gajananMaharajGroups ?? [];

    // Parse the config from arguments or fallback to defaults
    final args = ModalRoute.of(context)?.settings.arguments;
    final config =
        args is GroupScreenConfig
            ? args
            : GroupScreenConfig(
              title: localizations.parayanTitle,
              emptyMessage: localizations.noActiveParayans,
              targetRoute: Routes.parayanList,
            );

    final groups =
        config.filteredGroupIds != null
            ? allGroups
                .where((g) => config.filteredGroupIds!.contains(g.id))
                .toList()
            : allGroups;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          config.title,
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.appColors.primarySwatch,
        iconTheme: IconThemeData(color: theme.colorScheme.onPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              Routes.home,
              (route) => false,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, Routes.settings),
          ),
        ],
      ),
      body: groups.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Text(
                  config.emptyMessage,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 100.0),
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                final groupName = locale == 'mr' ? group.nameMr : group.nameEn;

                return Card(
                  elevation: theme.cardTheme.elevation,
                  color: theme.cardTheme.color,
                  shape: theme.cardTheme.shape,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          theme.colorScheme.primary.withValues(alpha: 0.1),
                      child: group.icon != null && group.icon!.isNotEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Image.asset(
                                group.icon!,
                                color: theme.colorScheme.primary,
                              ),
                            )
                          : Icon(
                              Icons.location_city,
                              color: theme.colorScheme.primary,
                            ),
                    ),
                    title: Text(
                      groupName,
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18.0,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      color: theme.colorScheme.primary,
                      size: 16.0,
                    ),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        config.targetRoute,
                        arguments: {'groupId': group.id, 'groupName': groupName},
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}


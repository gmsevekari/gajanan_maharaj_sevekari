import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/admin_user.dart';
import 'package:gajanan_maharaj_sevekari/providers/app_config_provider.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:provider/provider.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';

class AdminParayanGroupScreen extends StatelessWidget {
  final AdminUser adminUser;

  const AdminParayanGroupScreen({super.key, required this.adminUser});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final configProvider = Provider.of<AppConfigProvider>(context);
    final groups = configProvider.appConfig?.gajananMaharajGroups ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.adminParayanGroupTitle),
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: groups.isEmpty
                ? Center(child: Text(localizations.noActiveParayans))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 100.0),
                    itemCount: groups.length,
                    itemBuilder: (context, index) {
                      final group = groups[index];
                      final groupName =
                          locale == 'mr' ? group.nameMr : group.nameEn;

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
                            final selectedAdmin = AdminUser(
                              email: adminUser.email,
                              roles: adminUser.roles,
                              parayanGroupId: group.id,
                              typoNotificationsEnabled:
                                  adminUser.typoNotificationsEnabled,
                            );

                            Navigator.pushNamed(
                              context,
                              Routes.adminParayanCoordination,
                              arguments: selectedAdmin,
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

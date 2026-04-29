import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/admin/admin_management_service.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/admin_user.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';

import 'package:gajanan_maharaj_sevekari/widgets/themed_icon.dart';

class ManageGroupAdminsScreen extends StatefulWidget {
  final AdminUser currentAdmin;
  final AdminManagementService? managementService;

  const ManageGroupAdminsScreen({
    super.key,
    required this.currentAdmin,
    this.managementService,
  });

  @override
  State<ManageGroupAdminsScreen> createState() =>
      _ManageGroupAdminsScreenState();
}

class _ManageGroupAdminsScreenState extends State<ManageGroupAdminsScreen> {
  late final AdminManagementService _managementService;

  @override
  void initState() {
    super.initState();
    _managementService = widget.managementService ?? AdminManagementService();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;
    final isSuperAdmin = widget.currentAdmin.roles.contains('super_admin');

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.manageGroupAdminsTitle),
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isSuperAdmin && widget.currentAdmin.groupId != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: theme.cardTheme.elevation,
                color: theme.cardTheme.color,
                shape: theme.cardTheme.shape,
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Icon(
                          Icons.groups,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${localizations.adminGroupLabel}:',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.appColors.secondaryText,
                              ),
                            ),
                            Text(
                              widget.currentAdmin.groupId!,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.appColors.primarySwatch[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: StreamBuilder<List<AdminUser>>(
              stream: isSuperAdmin
                  ? _managementService.getAllAdmins()
                  : _managementService.getAdminsForGroup(
                      widget.currentAdmin.groupId!,
                    ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        '${localizations.errorLabel}: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  );
                }
                final admins = snapshot.data ?? [];
                if (admins.isEmpty) {
                  return Center(
                    child: Text(
                      localizations.noAdminsFound,
                      style: TextStyle(color: theme.appColors.secondaryText),
                    ),
                  );
                }

                final groupedItems = _groupAdmins(
                  admins,
                  localizations,
                  isSuperAdmin,
                );

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: groupedItems.length,
                  itemBuilder: (context, index) {
                    final item = groupedItems[index];
                    if (item is String) {
                      return _buildSectionHeader(context, item);
                    } else {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildAdminCard(
                          context,
                          item as AdminUser,
                          isSuperAdmin,
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(
            context,
            Routes.adminAddGroupAdmin,
            arguments: widget.currentAdmin,
          );
        },
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        icon: const Icon(Icons.person_add),
        label: Text(
          localizations.addAdminButton.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildAdminCard(
    BuildContext context,
    AdminUser admin,
    bool isSuperAdmin,
  ) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: theme.cardTheme.elevation,
      shape: theme.cardTheme.shape,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.secondaryContainer,
              child: Text(
                admin.email[0].toUpperCase(),
                style: TextStyle(
                  color: theme.colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    admin.email,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: admin.roles.map((role) {
                      String localizedRole;
                      switch (role) {
                        case 'super_admin':
                          localizedRole = localizations.roleSuperAdmin;
                          break;
                        case 'group_admin':
                          localizedRole = localizations.roleGroupAdmin;
                          break;
                        case 'parayan_coordinator':
                          localizedRole = localizations.roleParayanCoordinator;
                          break;
                        case 'namjap_coordinator':
                          localizedRole = localizations.roleNamjapCoordinator;
                          break;
                        default:
                          localizedRole = role.replaceAll('_', ' ').toUpperCase();
                      }
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getRoleColor(
                            theme,
                            role,
                          ).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: _getRoleColor(
                              theme,
                              role,
                            ).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          localizedRole.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: _getRoleColor(theme, role),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  if (isSuperAdmin && admin.groupId != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${localizations.adminGroupLabel}: ${admin.groupId}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.appColors.secondaryText,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                admin.email == widget.currentAdmin.email
                    ? Icons.person_outline
                    : Icons.edit_outlined,
                color: admin.email == widget.currentAdmin.email
                    ? theme.appColors.secondaryText
                    : theme.colorScheme.primary,
              ),
              onPressed: admin.email == widget.currentAdmin.email
                  ? null
                  : () => Navigator.pushNamed(
                        context,
                        Routes.adminAddGroupAdmin,
                        arguments: {
                          'currentAdmin': widget.currentAdmin,
                          'adminToEdit': admin,
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  List<dynamic> _groupAdmins(
    List<AdminUser> admins,
    AppLocalizations localizations,
    bool isSuperAdmin,
  ) {
    if (!isSuperAdmin) return admins;

    final Map<String, List<AdminUser>> groups = {};
    for (var admin in admins) {
      final groupId = admin.groupId ?? 'super_admins';
      groups.putIfAbsent(groupId, () => []).add(admin);
    }

    final List<dynamic> result = [];
    final sortedGroupIds = groups.keys.toList()
      ..sort((a, b) {
        if (a == 'super_admins') return -1;
        if (b == 'super_admins') return 1;
        return a.compareTo(b);
      });

    for (var groupId in sortedGroupIds) {
      String title = groupId == 'super_admins'
          ? localizations.roleSuperAdmin
          : '${localizations.adminGroupLabel}: $groupId';
      result.add(title);
      result.addAll(groups[groupId]!);
    }

    return result;
  }

  Color _getRoleColor(ThemeData theme, String role) {
    if (role == 'super_admin') return Colors.purple;
    if (role == 'group_admin') return theme.colorScheme.primary;
    return theme.appColors.secondaryText;
  }

}

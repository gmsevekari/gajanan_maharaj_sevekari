import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/admin/admin_session_service.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/models/admin_user.dart';
import 'package:gajanan_maharaj_sevekari/providers/typo_report_service.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:gajanan_maharaj_sevekari/widgets/themed_icon.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final Stream<DocumentSnapshot> _adminStream;

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    _adminStream = FirebaseFirestore.instance
        .collection('admin_allowlist')
        .doc(user?.email)
        .snapshots();
  }

  Future<void> _logout() async {
    AdminSessionService.clearSession();
    await _auth.signOut();
    await GoogleSignIn.instance.signOut();
    if (!mounted) return;
    // Pop back to the settings screen where they came from
    Navigator.of(context).pop();
  }

  Future<void> _toggleTypoNotifications(bool enabled) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('admin_allowlist')
          .doc(user.email)
          .update({'typoNotificationsEnabled': enabled});

      await TypoReportService.setNotificationsEnabled(enabled);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating settings: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = _auth.currentUser;
    final theme = Theme.of(context);

    final localizations = AppLocalizations.of(context)!;

    // Wrap the entire scaffold in a Listener to capture any touch events and reset the timer
    return Listener(
      onPointerDown: (_) => AdminSessionService.registerInteraction(),
      onPointerMove: (_) => AdminSessionService.registerInteraction(),
      onPointerUp: (_) => AdminSessionService.registerInteraction(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(localizations.adminDashboardTitle),
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
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: localizations.logoutLabel,
              onPressed: _logout,
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
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
                          Icons.person,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              localizations.loggedInAs,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.appColors.secondaryText,
                              ),
                            ),
                            Text(
                              user?.email ?? localizations.unknownAdmin,
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
              const SizedBox(height: 24),
              Text(
                localizations.adminModules,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.appColors.primarySwatch[600],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<DocumentSnapshot>(
                  stream: _adminStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return Center(
                        child: Text(
                          localizations.accessDeniedNotAuthorized,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      );
                    }

                    final adminUser = AdminUser.fromFirestore(
                      snapshot.data!.data() as Map<String, dynamic>,
                      user?.email ?? '',
                    );

                    return ListView(
                      children: [
                        if (adminUser.hasRole('temple_admin'))
                          _buildModuleCard(
                            context: context,
                            title: localizations.templeNotificationsModuleTitle,
                            subtitle:
                                localizations.templeNotificationsModuleSubtitle,
                            icon: Icons.notifications_active,
                            color: theme.colorScheme.primary,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                Routes.adminTempleNotifications,
                              );
                            },
                          ),
                        if (adminUser.hasRole('parayan_coordinator'))
                          _buildModuleCard(
                            context: context,
                            title: localizations.parayanCoordinationModuleTitle,
                            subtitle:
                                localizations.parayanCoordinationModuleSubtitle,
                            icon: Icons.event_note,
                            color: theme.appColors.primarySwatch[600]!,
                            onTap: () {
                              if (adminUser.parayanGroupId != null) {
                                Navigator.pushNamed(
                                  context,
                                  Routes.adminParayanCoordination,
                                  arguments: adminUser,
                                );
                              } else {
                                Navigator.pushNamed(
                                  context,
                                  Routes.adminParayanGroups,
                                  arguments: adminUser,
                                );
                              }
                            },
                          ),
                        if (adminUser.hasRole('app_developer'))
                          _buildModuleCard(
                            context: context,
                            title: localizations.adminTypoReportsModuleTitle,
                            subtitle:
                                localizations.adminTypoReportsModuleSubtitle,
                            icon: Icons.edit_note,
                            color: theme.appColors.primarySwatch[600]!,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                Routes.adminTypoReports,
                              );
                            },
                          ),
                        if (adminUser.hasRole('app_developer')) ...[
                          const SizedBox(height: 24),
                          Text(
                            localizations.settings,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.appColors.primarySwatch[600],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Card(
                            elevation: theme.cardTheme.elevation,
                            color: theme.cardTheme.color,
                            shape: theme.cardTheme.shape,
                            child: SwitchListTile(
                              title: Text(
                                localizations.typoNotificationToggleLabel,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.appColors.primarySwatch[600],
                                ),
                              ),
                              value: adminUser.typoNotificationsEnabled,
                              activeColor: theme.colorScheme.primary,
                              onChanged: _toggleTypoNotifications,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModuleCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: theme.cardTheme.elevation,
      color: theme.cardTheme.color,
      shape: theme.cardTheme.shape,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.appColors.primarySwatch[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.appColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

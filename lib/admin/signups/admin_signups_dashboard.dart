import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/admin_user.dart';
import 'package:gajanan_maharaj_sevekari/models/signup.dart';
import 'package:gajanan_maharaj_sevekari/providers/signup_service.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:gajanan_maharaj_sevekari/widgets/themed_icon.dart';
import 'package:gajanan_maharaj_sevekari/widgets/english_only.dart';

class AdminSignupsDashboard extends StatefulWidget {
  final AdminUser adminUser;

  /// Injected for testing; defaults to [FirebaseFirestore.instance].
  @visibleForTesting
  final FirebaseFirestore? firestore;

  /// Injected for testing.
  @visibleForTesting
  final SignupService? signupService;

  const AdminSignupsDashboard({
    super.key,
    required this.adminUser,
    this.firestore,
    this.signupService,
  });

  @override
  State<AdminSignupsDashboard> createState() => _AdminSignupsDashboardState();
}

class _AdminSignupsDashboardState extends State<AdminSignupsDashboard> {
  late final SignupService _service;
  late Stream<List<Signup>> _signupsStream;
  SignupStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _service =
        widget.signupService ?? SignupService(firestore: widget.firestore);
    _initializeStream();
  }

  void _initializeStream() {
    final groupId = widget.adminUser.groupId;
    if (groupId != null && groupId.isNotEmpty) {
      _signupsStream = _service.getAllSignups(groupId);
    } else {
      _signupsStream = Stream.value(const []);
    }
  }

  @override
  void didUpdateWidget(covariant AdminSignupsDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.adminUser.groupId != oldWidget.adminUser.groupId) {
      setState(_initializeStream);
    }
  }

  @override
  Widget build(BuildContext context) => EnglishOnly(builder: _buildScreen);

  Widget _buildScreen(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.adminSignupsDashboardTitle),
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
      floatingActionButton: FloatingActionButton(
        tooltip: localizations.signupCreateTooltip,
        onPressed: () => Navigator.pushNamed(
          context,
          Routes.adminCreateSignup,
          arguments: widget.adminUser,
        ),
        child: const Icon(Icons.add),
      ),
      body:
          widget.adminUser.groupId == null || widget.adminUser.groupId!.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  localizations.signupNoGroupAssigned,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.appColors.secondaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : StreamBuilder<List<Signup>>(
              stream: _signupsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            localizations.adminSignupsError,
                            style: theme.textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final allSignups = snapshot.data ?? const [];
                final filteredSignups = _selectedStatus == null
                    ? allSignups
                    : allSignups
                          .where((signup) => signup.status == _selectedStatus)
                          .toList();

                return Column(
                  children: [
                    _buildFilterChips(localizations, theme),
                    Expanded(
                      child: filteredSignups.isEmpty
                          ? Center(
                              child: Text(
                                localizations.signupNoSignupsFound,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.appColors.secondaryText,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              itemCount: filteredSignups.length,
                              itemBuilder: (context, index) {
                                return _buildSignupCard(
                                  context,
                                  filteredSignups[index],
                                  localizations,
                                  theme,
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildFilterChips(AppLocalizations localizations, ThemeData theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          ChoiceChip(
            label: Text(localizations.signupStatusAll),
            selected: _selectedStatus == null,
            onSelected: (selected) {
              if (selected) setState(() => _selectedStatus = null);
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: Text(localizations.signupStatusDraft),
            selected: _selectedStatus == SignupStatus.draft,
            onSelected: (selected) {
              if (selected) {
                setState(() => _selectedStatus = SignupStatus.draft);
              }
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: Text(localizations.signupStatusPublished),
            selected: _selectedStatus == SignupStatus.published,
            onSelected: (selected) {
              if (selected) {
                setState(() => _selectedStatus = SignupStatus.published);
              }
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: Text(localizations.signupStatusClosed),
            selected: _selectedStatus == SignupStatus.closed,
            onSelected: (selected) {
              if (selected) {
                setState(() => _selectedStatus = SignupStatus.closed);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSignupCard(
    BuildContext context,
    Signup signup,
    AppLocalizations localizations,
    ThemeData theme,
  ) {
    final isMarathi = contentIsMarathi(context);
    final title = isMarathi
        ? (signup.titleMr.isNotEmpty ? signup.titleMr : signup.titleEn)
        : (signup.titleEn.isNotEmpty ? signup.titleEn : signup.titleMr);
    final description = isMarathi
        ? (signup.descriptionMr.isNotEmpty
              ? signup.descriptionMr
              : signup.descriptionEn)
        : (signup.descriptionEn.isNotEmpty
              ? signup.descriptionEn
              : signup.descriptionMr);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.pushNamed(
          context,
          Routes.adminSignupDetail,
          arguments: {'signupId': signup.id, 'adminUser': widget.adminUser},
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusBadge(signup.status, localizations, theme),
                ],
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.appColors.secondaryText,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (signup.requiresJoinCode && signup.joinCode != null) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.key_outlined,
                      size: 16,
                      color: theme.appColors.brandAccent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${localizations.signupJoinCodePrefix}${signup.joinCode}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.appColors.brandAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(
    SignupStatus status,
    AppLocalizations localizations,
    ThemeData theme,
  ) {
    final (String label, Color color) = switch (status) {
      SignupStatus.draft => (
        localizations.signupStatusDraft,
        theme.appColors.warning,
      ),
      SignupStatus.published => (
        localizations.signupStatusPublished,
        theme.appColors.success,
      ),
      SignupStatus.closed => (
        localizations.signupStatusClosed,
        theme.appColors.secondaryText,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/admin_user.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_sheet.dart';
import 'package:gajanan_maharaj_sevekari/providers/signup_service.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:gajanan_maharaj_sevekari/widgets/themed_icon.dart';

class AdminSignupSheetsDashboard extends StatefulWidget {
  final AdminUser adminUser;

  /// Injected for testing; defaults to [FirebaseFirestore.instance].
  @visibleForTesting
  final FirebaseFirestore? firestore;

  /// Injected for testing.
  @visibleForTesting
  final SignupService? signupService;

  const AdminSignupSheetsDashboard({
    super.key,
    required this.adminUser,
    this.firestore,
    this.signupService,
  });

  @override
  State<AdminSignupSheetsDashboard> createState() =>
      _AdminSignupSheetsDashboardState();
}

class _AdminSignupSheetsDashboardState
    extends State<AdminSignupSheetsDashboard> {
  late final SignupService _service;
  late Stream<List<SignupSheet>> _sheetsStream;
  SignupSheetStatus? _selectedStatus;

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
      _sheetsStream = _service.getAllSheets(groupId);
    } else {
      _sheetsStream = Stream.value(const []);
    }
  }

  @override
  void didUpdateWidget(covariant AdminSignupSheetsDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.adminUser.groupId != oldWidget.adminUser.groupId) {
      setState(_initializeStream);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          Routes.adminCreateSignupSheet,
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
          : StreamBuilder<List<SignupSheet>>(
              stream: _sheetsStream,
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

                final allSheets = snapshot.data ?? const [];
                final filteredSheets = _selectedStatus == null
                    ? allSheets
                    : allSheets
                          .where((sheet) => sheet.status == _selectedStatus)
                          .toList();

                return Column(
                  children: [
                    _buildFilterChips(localizations, theme),
                    Expanded(
                      child: filteredSheets.isEmpty
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
                              itemCount: filteredSheets.length,
                              itemBuilder: (context, index) {
                                return _buildSheetCard(
                                  context,
                                  filteredSheets[index],
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
            selected: _selectedStatus == SignupSheetStatus.draft,
            onSelected: (selected) {
              if (selected) {
                setState(() => _selectedStatus = SignupSheetStatus.draft);
              }
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: Text(localizations.signupStatusPublished),
            selected: _selectedStatus == SignupSheetStatus.published,
            onSelected: (selected) {
              if (selected) {
                setState(() => _selectedStatus = SignupSheetStatus.published);
              }
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: Text(localizations.signupStatusClosed),
            selected: _selectedStatus == SignupSheetStatus.closed,
            onSelected: (selected) {
              if (selected) {
                setState(() => _selectedStatus = SignupSheetStatus.closed);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSheetCard(
    BuildContext context,
    SignupSheet sheet,
    AppLocalizations localizations,
    ThemeData theme,
  ) {
    final isMarathi = Localizations.localeOf(context).languageCode == 'mr';
    final title = isMarathi
        ? (sheet.titleMr.isNotEmpty ? sheet.titleMr : sheet.titleEn)
        : (sheet.titleEn.isNotEmpty ? sheet.titleEn : sheet.titleMr);
    final description = isMarathi
        ? (sheet.descriptionMr.isNotEmpty
              ? sheet.descriptionMr
              : sheet.descriptionEn)
        : (sheet.descriptionEn.isNotEmpty
              ? sheet.descriptionEn
              : sheet.descriptionMr);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.pushNamed(
          context,
          Routes.adminSignupSheetDetail,
          arguments: {'sheetId': sheet.id, 'adminUser': widget.adminUser},
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
                  _buildStatusBadge(sheet.status, localizations, theme),
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
              if (sheet.requiresJoinCode && sheet.joinCode != null) ...[
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
                      '${localizations.signupJoinCodePrefix}${sheet.joinCode}',
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
    SignupSheetStatus status,
    AppLocalizations localizations,
    ThemeData theme,
  ) {
    final (String label, Color color) = switch (status) {
      SignupSheetStatus.draft => (
        localizations.signupStatusDraft,
        theme.appColors.warning,
      ),
      SignupSheetStatus.published => (
        localizations.signupStatusPublished,
        theme.appColors.success,
      ),
      SignupSheetStatus.closed => (
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

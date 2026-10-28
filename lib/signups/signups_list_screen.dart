import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/widgets/fitted_app_bar_title.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup.dart';
import 'package:gajanan_maharaj_sevekari/providers/signup_service.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:gajanan_maharaj_sevekari/widgets/themed_icon.dart';
import 'package:gajanan_maharaj_sevekari/widgets/english_only.dart';

/// Published sign-up signups for a single group. Reached via the
/// group-selection indirection described in the design doc - by the time
/// this screen is shown, a group has already been chosen.
class SignupsListScreen extends StatefulWidget {
  final String? groupId;
  final String? groupName;

  /// Injected for testing; defaults to [FirebaseFirestore.instance].
  @visibleForTesting
  final FirebaseFirestore? firestore;

  /// Injected for testing.
  @visibleForTesting
  final SignupService? signupService;

  const SignupsListScreen({
    super.key,
    this.groupId,
    this.groupName,
    this.firestore,
    this.signupService,
  });

  @override
  State<SignupsListScreen> createState() => _SignupsListScreenState();
}

class _SignupsListScreenState extends State<SignupsListScreen>
    with SingleTickerProviderStateMixin {
  late final SignupService _service;
  late final TabController _tabController;
  Stream<List<Signup>>? _upcomingStream;
  Stream<List<Signup>>? _pastStream;

  @override
  void initState() {
    super.initState();
    _service =
        widget.signupService ?? SignupService(firestore: widget.firestore);
    _tabController = TabController(length: 2, vsync: this);
    final groupId = widget.groupId;
    if (groupId != null && groupId.isNotEmpty) {
      _upcomingStream = _service.getActiveSignups(groupId);
      _pastStream = _service.getPastSignups(groupId);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => EnglishOnly(builder: _buildScreen);

  Widget _buildScreen(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final hasValidGroup = _upcomingStream != null && _pastStream != null;

    return Scaffold(
      appBar: AppBar(
        title: FittedAppBarTitle(widget.groupName ?? l10n.signupsListTitle),
        bottom: hasValidGroup
            ? TabBar(
                controller: _tabController,
                labelColor: theme.colorScheme.onPrimary,
                unselectedLabelColor: theme.colorScheme.onPrimary.withValues(
                  alpha: 0.7,
                ),
                indicatorColor: theme.colorScheme.onPrimary,
                tabs: [
                  Tab(text: l10n.signupUpcomingTab),
                  Tab(text: l10n.signupPastTab),
                ],
              )
            : null,
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
      body: !hasValidGroup
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  l10n.signupInvalidGroupError,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.appColors.secondaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildSignupsList(
                  stream: _upcomingStream!,
                  emptyMessage: l10n.signupNoActiveSignups,
                  theme: theme,
                ),
                _buildSignupsList(
                  stream: _pastStream!,
                  emptyMessage: l10n.signupNoPastSignups,
                  theme: theme,
                ),
              ],
            ),
    );
  }

  Widget _buildSignupsList({
    required Stream<List<Signup>> stream,
    required String emptyMessage,
    required ThemeData theme,
  }) {
    return StreamBuilder<List<Signup>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final signups = snapshot.data ?? const [];
        if (signups.isEmpty) {
          return Center(
            child: Text(
              emptyMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.appColors.secondaryText,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: signups.length,
          itemBuilder: (context, index) => _SignupCard(signup: signups[index]),
        );
      },
    );
  }
}

class _SignupCard extends StatelessWidget {
  final Signup signup;

  const _SignupCard({required this.signup});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isMarathi = contentIsMarathi(context);
    final title = isMarathi
        ? (signup.titleMr.isNotEmpty ? signup.titleMr : signup.titleEn)
        : (signup.titleEn.isNotEmpty ? signup.titleEn : signup.titleMr);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.pushNamed(
          context,
          Routes.signupDetail,
          arguments: {'signupId': signup.id},
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (signup.requiresJoinCode) ...[
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
                      l10n.signupRequiresJoinCodeBadge,
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
}

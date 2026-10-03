import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/widgets/fitted_app_bar_title.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup.dart';
import 'package:gajanan_maharaj_sevekari/providers/signup_service.dart';
import 'package:gajanan_maharaj_sevekari/signups/my_signups_screen.dart';
import 'package:gajanan_maharaj_sevekari/signups/signup_entries_screen.dart';
import 'package:gajanan_maharaj_sevekari/signups/signup_slots_screen.dart';
import 'package:gajanan_maharaj_sevekari/signups/widgets/signup_nav_card.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:gajanan_maharaj_sevekari/utils/unique_id_service.dart';
import 'package:gajanan_maharaj_sevekari/widgets/themed_icon.dart';
import 'package:gajanan_maharaj_sevekari/widgets/english_only.dart';

class SignupDetailScreen extends StatefulWidget {
  final String? signupId;

  /// Injected for testing; defaults to fetching the real device ID.
  @visibleForTesting
  final String? deviceId;

  /// Injected for testing; defaults to [FirebaseFirestore.instance].
  @visibleForTesting
  final FirebaseFirestore? firestore;

  /// Injected for testing.
  @visibleForTesting
  final SignupService? signupService;

  const SignupDetailScreen({
    super.key,
    this.signupId,
    this.deviceId,
    this.firestore,
    this.signupService,
  });

  @override
  State<SignupDetailScreen> createState() => _SignupDetailScreenState();
}

class _SignupDetailScreenState extends State<SignupDetailScreen> {
  late final SignupService _service;
  String? _deviceId;
  String _signupId = '';
  Stream<Signup?>? _signupStream;

  @override
  void initState() {
    super.initState();
    _service =
        widget.signupService ?? SignupService(firestore: widget.firestore);
    _deviceId = widget.deviceId;
    if (_deviceId == null) {
      _getDeviceId();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newId = _getEffectiveSignupId(context);
    if (newId != _signupId) {
      _signupId = newId;
      _signupStream = _service.getSignupById(_signupId);
    }
  }

  Future<void> _getDeviceId() async {
    final id = await UniqueIdService.getUniqueId();
    if (mounted) {
      setState(() => _deviceId = id);
    }
  }

  String _getEffectiveSignupId(BuildContext context) {
    if (widget.signupId != null && widget.signupId!.isNotEmpty) {
      return widget.signupId!;
    }
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    return args?['signupId'] as String? ?? '';
  }

  List<Widget> _buildAppBarActions(BuildContext context) => [
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
  ];

  void _openMySignups() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MySignupsScreen(
          signupId: _signupId,
          deviceId: _deviceId!,
          firestore: widget.firestore,
          signupService: _service,
        ),
      ),
    );
  }

  void _openSlots(Signup signup) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SignupSlotsScreen(
          signupId: _signupId,
          signup: signup,
          deviceId: _deviceId,
          firestore: widget.firestore,
          signupService: _service,
        ),
      ),
    );
  }

  void _openEntries() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SignupEntriesScreen(
          signupId: _signupId,
          firestore: widget.firestore,
          signupService: _service,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => EnglishOnly(builder: _buildScreen);

  Widget _buildScreen(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isMarathi = contentIsMarathi(context);

    return StreamBuilder<Signup?>(
      stream: _signupStream,
      builder: (context, signupSnapshot) {
        if (_deviceId == null ||
            signupSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: FittedAppBarTitle(l10n.signupsListTitle),
              actions: _buildAppBarActions(context),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final signup = signupSnapshot.data;
        if (signup == null) {
          return Scaffold(
            appBar: AppBar(
              title: FittedAppBarTitle(l10n.signupsListTitle),
              actions: _buildAppBarActions(context),
            ),
            body: Center(
              child: Text(
                l10n.signupNotFound,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.appColors.secondaryText,
                ),
              ),
            ),
          );
        }

        final title = isMarathi
            ? (signup.titleMr.isNotEmpty ? signup.titleMr : signup.titleEn)
            : (signup.titleEn.isNotEmpty ? signup.titleEn : signup.titleMr);
        final desc = isMarathi
            ? (signup.descriptionMr.isNotEmpty
                  ? signup.descriptionMr
                  : signup.descriptionEn)
            : (signup.descriptionEn.isNotEmpty
                  ? signup.descriptionEn
                  : signup.descriptionMr);

        return Scaffold(
          appBar: AppBar(
            title: FittedAppBarTitle(title),
            actions: _buildAppBarActions(context),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (signup.headerImageUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ConstrainedBox(
                    // No fixed height: the image lays out at its
                    // own resolution (width-matched, aspect-ratio
                    // preserved) so nothing is cropped, with this
                    // minimum only as a floor for small images and
                    // a stable placeholder while loading.
                    constraints: const BoxConstraints(minHeight: 180),
                    child: Image.network(
                      signup.headerImageUrl!,
                      width: double.infinity,
                      fit: BoxFit.fitWidth,
                      semanticLabel: l10n.signupHeaderImageLabel,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          constraints: const BoxConstraints(minHeight: 180),
                          width: double.infinity,
                          alignment: Alignment.center,
                          child: const CircularProgressIndicator(),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        constraints: const BoxConstraints(minHeight: 180),
                        width: double.infinity,
                        color: theme.appColors.secondaryText.withValues(
                          alpha: 0.1,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: theme.appColors.secondaryText,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (desc.isNotEmpty) ...[
                Text(
                  desc,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.appColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              SignupNavCard(
                icon: Icons.assignment_ind_outlined,
                label: l10n.signupMySignupsHeading,
                onTap: _openMySignups,
              ),
              const SizedBox(height: 12),
              SignupNavCard(
                icon: Icons.event_seat_outlined,
                label: l10n.signupSlotsHeading,
                onTap: () => _openSlots(signup),
              ),
              const SizedBox(height: 12),
              SignupNavCard(
                icon: Icons.table_rows_outlined,
                label: l10n.signupEntriesHeading,
                onTap: _openEntries,
              ),
            ],
          ),
        );
      },
    );
  }
}

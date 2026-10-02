import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_sheet.dart';
import 'package:gajanan_maharaj_sevekari/providers/signup_service.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';

/// Published sign-up sheets for a single group. Reached via the
/// group-selection indirection described in the design doc - by the time
/// this screen is shown, a group has already been chosen.
class SignupSheetsListScreen extends StatefulWidget {
  final String? groupId;
  final String? groupName;

  /// Injected for testing; defaults to [FirebaseFirestore.instance].
  @visibleForTesting
  final FirebaseFirestore? firestore;

  /// Injected for testing.
  @visibleForTesting
  final SignupService? signupService;

  const SignupSheetsListScreen({
    super.key,
    this.groupId,
    this.groupName,
    this.firestore,
    this.signupService,
  });

  @override
  State<SignupSheetsListScreen> createState() => _SignupSheetsListScreenState();
}

class _SignupSheetsListScreenState extends State<SignupSheetsListScreen> {
  late final SignupService _service;
  Stream<List<SignupSheet>>? _sheetsStream;

  @override
  void initState() {
    super.initState();
    _service =
        widget.signupService ?? SignupService(firestore: widget.firestore);
    final groupId = widget.groupId;
    if (groupId != null && groupId.isNotEmpty) {
      _sheetsStream = _service.getActiveSheets(groupId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName ?? l10n.signupSheetsListTitle),
      ),
      body: _sheetsStream == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  l10n.signupSheetInvalidGroupError,
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

                final sheets = snapshot.data ?? const [];
                if (sheets.isEmpty) {
                  return Center(
                    child: Text(
                      l10n.signupSheetNoActiveSheets,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.appColors.secondaryText,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sheets.length,
                  itemBuilder: (context, index) =>
                      _SheetCard(sheet: sheets[index]),
                );
              },
            ),
    );
  }
}

class _SheetCard extends StatelessWidget {
  final SignupSheet sheet;

  const _SheetCard({required this.sheet});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
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
          Routes.signupSheetDetail,
          arguments: {'sheetId': sheet.id},
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
              if (sheet.requiresJoinCode) ...[
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
                      l10n.signupSheetRequiresJoinCodeBadge,
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

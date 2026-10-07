import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_entry.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';
import 'package:gajanan_maharaj_sevekari/signups/widgets/signup_entries_table.dart';
import 'package:gajanan_maharaj_sevekari/widgets/english_only.dart';

/// The picture an admin shares of who has signed up: the sign-up's title and
/// group over the same Date / Title / Name table devotees see. Contact
/// details, pledges and notes are not part of it, so it is safe to post.
///
/// Meant to be rendered off screen into an image. Wrap it with [scoped] first,
/// because an off-screen tree has none of the app's theme or localizations.
class SignupEntriesExportCard extends StatelessWidget {
  /// Fixed width of the image in logical pixels.
  static const double cardWidth = 420;

  final String title;
  final String groupName;
  final List<SignupEntry> entries;

  /// The slots [entries] belong to; also the ones the table draws dates from.
  final List<SignupSlot> slots;

  /// Which image this is, when a long export is split over several
  /// ([totalParts] > 1); a single image is not numbered.
  final int part;
  final int totalParts;

  const SignupEntriesExportCard({
    super.key,
    required this.title,
    required this.groupName,
    required this.entries,
    required this.slots,
    this.part = 1,
    this.totalParts = 1,
  });

  /// [card] with the theme, the (English) localizations and the content
  /// language of [context], and text at its natural size however large the
  /// admin's own text setting is: the image is measured once and then drawn,
  /// so a size that changed between the two would cut it off.
  static Widget scoped(BuildContext context, Widget card) {
    final theme = Theme.of(context);
    final contentLanguage =
        AppContentLocale.maybeOf(context) ??
        Localizations.localeOf(context).languageCode;
    final mediaQuery = MediaQuery.maybeOf(context) ?? const MediaQueryData();
    return Localizations.override(
      context: context,
      locale: const Locale('en'),
      child: AppContentLocale(
        languageCode: contentLanguage,
        child: MediaQuery(
          data: mediaQuery.copyWith(textScaler: TextScaler.noScaling),
          child: Theme(data: theme, child: card),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: Container(
        width: cardWidth,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.appColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(theme, l10n),
            const SizedBox(height: 14),
            SignupEntriesTable(entries: entries, slots: slots),
            const SizedBox(height: 16),
            Text(
              l10n.signupExportTagline,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.appColors.secondaryText,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, AppLocalizations l10n) => Row(
    children: [
      CircleAvatar(
        radius: 20,
        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
        child: Icon(
          Icons.table_rows_outlined,
          color: theme.colorScheme.primary,
          size: 22,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            if (groupName.isNotEmpty)
              Text(
                groupName,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.appColors.secondaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            Text(
              totalParts > 1
                  ? '${l10n.signupEntriesHeading} - ${l10n.signupExportPart('$part', '$totalParts')}'
                  : l10n.signupEntriesHeading,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.appColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

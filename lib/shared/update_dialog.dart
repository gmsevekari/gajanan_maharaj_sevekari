import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/utils/update_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:gajanan_maharaj_sevekari/utils/marathi_utils.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';

class UpdateDialog extends StatelessWidget {
  final UpdateResult updateResult;

  const UpdateDialog({super.key, required this.updateResult});

  Future<void> _launchStore() async {
    final url = Uri.parse(updateResult.storeUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isForced = updateResult.type == UpdateType.forced;

    return PopScope(
      canPop: !isForced,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && isForced) {
          SystemNavigator.pop();
        }
      },
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.system_update, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Text(
              l10n.updateAvailableTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isForced
                  ? l10n.forcedUpdateMessage
                  : l10n.recommendedUpdateMessage,
              style: theme.textTheme.bodyMedium,
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${l10n.currentVersionLabel}: ${Localizations.localeOf(context).languageCode == 'mr' ? toMarathiNumerals(updateResult.currentVersion) : updateResult.currentVersion}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.appColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${l10n.latestVersionLabel}: ${Localizations.localeOf(context).languageCode == 'mr' ? toMarathiNumerals(updateResult.latestVersion) : updateResult.latestVersion}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (!isForced)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                l10n.updateLater,
                style: TextStyle(color: theme.appColors.secondaryText),
              ),
            ),
          ElevatedButton(
            onPressed: _launchStore,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              elevation: 0,
            ),
            child: Text(l10n.updateNow),
          ),
        ],
      ),
    );
  }

  static Future<void> show(BuildContext context, UpdateResult result) async {
    return showDialog(
      context: context,
      barrierDismissible: result.type != UpdateType.forced,
      builder: (context) => UpdateDialog(updateResult: result),
    );
  }
}

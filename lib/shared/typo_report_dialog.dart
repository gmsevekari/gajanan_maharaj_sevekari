import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/typo_report.dart';
import 'package:gajanan_maharaj_sevekari/providers/typo_report_service.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';

class TypoReportDialog extends StatefulWidget {
  final String initialTypoText;
  final String contentPath;
  final String contentTitle;
  final String contentType;
  final String deityId;
  final String deviceId;

  const TypoReportDialog({
    super.key,
    required this.initialTypoText,
    required this.contentPath,
    required this.contentTitle,
    required this.contentType,
    required this.deityId,
    required this.deviceId,
  });

  @override
  State<TypoReportDialog> createState() => _TypoReportDialogState();
}

class _TypoReportDialogState extends State<TypoReportDialog> {
  late final TextEditingController _typoController;
  late final TextEditingController _correctionController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _typoController = TextEditingController(text: widget.initialTypoText);
    _correctionController = TextEditingController();
  }

  @override
  void dispose() {
    _typoController.dispose();
    _correctionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_typoController.text.trim().isEmpty) return;

    setState(() => _isSubmitting = true);

    final timestamp = DateTime.now();
    final reportId = "${timestamp.millisecondsSinceEpoch}_${widget.deviceId.length > 8 ? widget.deviceId.substring(0, 8) : widget.deviceId}";

    final report = TypoReport(
      id: reportId,
      contentPath: widget.contentPath,
      contentTitle: widget.contentTitle,
      contentType: widget.contentType,
      deityId: widget.deityId,
      typoText: _typoController.text.trim(),
      suggestedCorrection: _correctionController.text.trim(),
      deviceId: widget.deviceId,
      timestamp: timestamp,
    );

    try {
      await TypoReportService().submitReport(report);
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.reportTypoSuccess),
            backgroundColor: Theme.of(context).appColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.reportTypoError),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.edit_note, color: theme.colorScheme.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    localizations.reportTypoTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _typoController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: localizations.reportTypoLabel,
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _correctionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: localizations.suggestedCorrectionLabel,
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                  child: Text(localizations.cancel),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(localizations.submitLabel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

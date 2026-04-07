import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/typo_report.dart';
import 'package:gajanan_maharaj_sevekari/providers/typo_report_service.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';

class AdminTypoReportsScreen extends StatefulWidget {
  const AdminTypoReportsScreen({super.key});

  @override
  State<AdminTypoReportsScreen> createState() => _AdminTypoReportsScreenState();
}

class _AdminTypoReportsScreenState extends State<AdminTypoReportsScreen> {
  late final Stream<List<TypoReport>> _reportsStream;

  @override
  void initState() {
    super.initState();
    _reportsStream = TypoReportService().getPendingReports();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.adminTypoReportsModuleTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              Routes.home,
              (route) => false,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, Routes.settings),
          ),
        ],
      ),
      body: StreamBuilder<List<TypoReport>>(
        stream: _reportsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final reports = snapshot.data ?? [];

          if (reports.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: theme.appColors.success.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    localizations.typoReportNoPendingReports,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.appColors.secondaryText,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              return _TypoReportCard(report: reports[index]);
            },
          );
        },
      ),
    );
  }
}

class _TypoReportCard extends StatelessWidget {
  final TypoReport report;

  const _TypoReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;
    final dateStr = DateFormat('MMM d, yyyy • h:mm a').format(report.timestamp);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    report.contentType.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    report.contentTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  dateStr,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.appColors.secondaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            _buildSection(
              context: context,
              label: localizations.typoReportIncorrectTextLabel,
              content: report.typoText,
              color: theme.colorScheme.error,
              icon: Icons.error_outline,
            ),
            const SizedBox(height: 16),
            _buildSection(
              context: context,
              label: localizations.typoReportSuggestedCorrectionLabel,
              content: report.suggestedCorrection.isEmpty
                  ? localizations.typoReportNoSuggestion
                  : report.suggestedCorrection,
              color: theme.appColors.success,
              icon: Icons.check_circle_outline,
            ),
            const SizedBox(height: 12),
            Text(
              localizations.typoReportPathLabel(report.contentPath),
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.appColors.secondaryText,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _confirmFix(context),
                  icon: const Icon(Icons.done_all, size: 18),
                  label: Text(localizations.markAsFixed),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.appColors.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String label,
    required String content,
    required Color color,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.appColors.secondaryText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: SelectableText(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: content.contains('(No suggestion')
                  ? theme.appColors.secondaryText
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmFix(BuildContext context) async {
    final localizations = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.markAsFixed),
        content: Text(localizations.typoReportConfirmDeleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(localizations.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(localizations.typoReportDeleteButton),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await TypoReportService().deleteReport(report.id);
    }
  }
}

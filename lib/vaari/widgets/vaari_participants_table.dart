import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/vaari_participant.dart';
import 'package:gajanan_maharaj_sevekari/providers/vaari_service.dart';
import 'package:gajanan_maharaj_sevekari/utils/locale_extensions.dart';
import 'package:gajanan_maharaj_sevekari/utils/marathi_utils.dart';
import 'package:provider/provider.dart';

/// A read-only table of every participant's steps and distance for a Vaari
/// event, styled to match AdhyaysAllocationTab's participant table.
class VaariParticipantsTable extends StatefulWidget {
  final String eventId;
  final String distanceUnitLabel;

  const VaariParticipantsTable({
    super.key,
    required this.eventId,
    required this.distanceUnitLabel,
  });

  @override
  State<VaariParticipantsTable> createState() => _VaariParticipantsTableState();
}

class _VaariParticipantsTableState extends State<VaariParticipantsTable> {
  late final Stream<List<VaariParticipant>> _participantsStream;

  @override
  void initState() {
    super.initState();
    _participantsStream = context.read<VaariService>().getAllParticipants(
      widget.eventId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    return StreamBuilder<List<VaariParticipant>>(
      stream: _participantsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final participants = snapshot.data ?? [];

        return Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color:
                    theme.cardTheme.color?.withValues(alpha: 0.8) ??
                    theme.colorScheme.surfaceContainer.withValues(alpha: 0.8),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(2),
                  1: FlexColumnWidth(1),
                  2: FlexColumnWidth(1),
                },
                children: [
                  TableRow(
                    children: [
                      _buildHeaderCell(localizations.name, theme),
                      _buildHeaderCell(localizations.stepsLabel, theme),
                      _buildHeaderCell(
                        '${localizations.distanceLabel} (${widget.distanceUnitLabel})',
                        theme,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color:
                    theme.cardTheme.color?.withValues(alpha: 0.3) ??
                    theme.colorScheme.surfaceContainer.withValues(alpha: 0.3),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: participants.isEmpty
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        localizations.noSignupsFound,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.hintColor,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : Table(
                      columnWidths: const {
                        0: FlexColumnWidth(2),
                        1: FlexColumnWidth(1),
                        2: FlexColumnWidth(1),
                      },
                      defaultVerticalAlignment:
                          TableCellVerticalAlignment.middle,
                      children: participants.asMap().entries.map((entry) {
                        final index = entry.key;
                        final participant = entry.value;
                        final rowDecoration = BoxDecoration(
                          color: index.isEven
                              ? Colors.transparent
                              : theme.appColors.secondaryText.withValues(
                                  alpha: 0.03,
                                ),
                        );

                        return TableRow(
                          decoration: rowDecoration,
                          children: [
                            _buildCell(participant.memberName, theme),
                            _buildCell(
                              formatNumberLocalized(
                                participant.totalSteps,
                                locale,
                                pad: false,
                              ),
                              theme,
                              alignCenter: true,
                            ),
                            _buildCell(
                              formatDistanceLocalized(
                                participant.totalDistance,
                                locale,
                              ),
                              theme,
                              alignCenter: true,
                            ),
                          ],
                        );
                      }).toList(),
                    ),
            ),
          ],
        );
      },
    );
  }


  Widget _buildHeaderCell(String label, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.secondary,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildCell(String value, ThemeData theme, {bool alignCenter = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Text(
        value,
        textAlign: alignCenter ? TextAlign.center : TextAlign.start,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
        ),
      ),
    );
  }
}

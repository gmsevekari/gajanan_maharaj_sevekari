import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_entry.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_sheet.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';
import 'package:gajanan_maharaj_sevekari/providers/signup_service.dart';
import 'package:gajanan_maharaj_sevekari/signups/my_signups_screen.dart';
import 'package:gajanan_maharaj_sevekari/signups/signup_slots_screen.dart';
import 'package:gajanan_maharaj_sevekari/utils/date_time_utils.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:gajanan_maharaj_sevekari/utils/unique_id_service.dart';
import 'package:gajanan_maharaj_sevekari/widgets/themed_icon.dart';

class SignupSheetDetailScreen extends StatefulWidget {
  final String? sheetId;

  /// Injected for testing; defaults to fetching the real device ID.
  @visibleForTesting
  final String? deviceId;

  /// Injected for testing; defaults to [FirebaseFirestore.instance].
  @visibleForTesting
  final FirebaseFirestore? firestore;

  /// Injected for testing.
  @visibleForTesting
  final SignupService? signupService;

  const SignupSheetDetailScreen({
    super.key,
    this.sheetId,
    this.deviceId,
    this.firestore,
    this.signupService,
  });

  @override
  State<SignupSheetDetailScreen> createState() =>
      _SignupSheetDetailScreenState();
}

class _SignupSheetDetailScreenState extends State<SignupSheetDetailScreen> {
  late final SignupService _service;
  String? _deviceId;
  String _sheetId = '';
  Stream<SignupSheet?>? _sheetStream;
  Stream<List<SignupSlot>>? _slotsStream;
  Stream<List<SignupEntry>>? _entriesStream;

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
    final newId = _getEffectiveSheetId(context);
    if (newId != _sheetId) {
      _sheetId = newId;
      _sheetStream = _service.getSheetById(_sheetId);
      _slotsStream = _service.getSlots(_sheetId);
      // The Entries table below needs every devotee's entry, not just this
      // device's own.
      _entriesStream = _service.getAllEntries(_sheetId);
    }
  }

  Future<void> _getDeviceId() async {
    final id = await UniqueIdService.getUniqueId();
    if (mounted) {
      setState(() => _deviceId = id);
    }
  }

  String _getEffectiveSheetId(BuildContext context) {
    if (widget.sheetId != null && widget.sheetId!.isNotEmpty) {
      return widget.sheetId!;
    }
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    return args?['sheetId'] as String? ?? '';
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
          sheetId: _sheetId,
          deviceId: _deviceId!,
          firestore: widget.firestore,
          signupService: _service,
        ),
      ),
    );
  }

  void _openSlots(SignupSheet sheet) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SignupSlotsScreen(
          sheetId: _sheetId,
          sheet: sheet,
          deviceId: _deviceId,
          firestore: widget.firestore,
          signupService: _service,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isMarathi = Localizations.localeOf(context).languageCode == 'mr';

    return StreamBuilder<SignupSheet?>(
      stream: _sheetStream,
      builder: (context, sheetSnapshot) {
        if (_deviceId == null ||
            sheetSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: Text(l10n.signupsListTitle),
              actions: _buildAppBarActions(context),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final sheet = sheetSnapshot.data;
        if (sheet == null) {
          return Scaffold(
            appBar: AppBar(
              title: Text(l10n.signupsListTitle),
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
            ? (sheet.titleMr.isNotEmpty ? sheet.titleMr : sheet.titleEn)
            : (sheet.titleEn.isNotEmpty ? sheet.titleEn : sheet.titleMr);
        final desc = isMarathi
            ? (sheet.descriptionMr.isNotEmpty
                  ? sheet.descriptionMr
                  : sheet.descriptionEn)
            : (sheet.descriptionEn.isNotEmpty
                  ? sheet.descriptionEn
                  : sheet.descriptionMr);

        return Scaffold(
          appBar: AppBar(
            title: Text(title),
            actions: _buildAppBarActions(context),
          ),
          body: StreamBuilder<List<SignupSlot>>(
            stream: _slotsStream,
            builder: (context, slotsSnapshot) {
              final slots = slotsSnapshot.data ?? const [];

              return StreamBuilder<List<SignupEntry>>(
                stream: _entriesStream,
                builder: (context, entriesSnapshot) {
                  final allEntries = entriesSnapshot.data ?? const [];

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (sheet.headerImageUrl != null) ...[
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
                              sheet.headerImageUrl!,
                              width: double.infinity,
                              fit: BoxFit.fitWidth,
                              semanticLabel: l10n.signupHeaderImageLabel,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return Container(
                                  constraints: const BoxConstraints(
                                    minHeight: 180,
                                  ),
                                  width: double.infinity,
                                  alignment: Alignment.center,
                                  child: const CircularProgressIndicator(),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    constraints: const BoxConstraints(
                                      minHeight: 180,
                                    ),
                                    width: double.infinity,
                                    color: theme.appColors.secondaryText
                                        .withValues(alpha: 0.1),
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
                      _NavCard(
                        icon: Icons.assignment_ind_outlined,
                        label: l10n.signupMySignupsHeading,
                        onTap: _openMySignups,
                      ),
                      const SizedBox(height: 12),
                      _NavCard(
                        icon: Icons.event_seat_outlined,
                        label: l10n.signupSlotsHeading,
                        onTap: () => _openSlots(sheet),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l10n.signupEntriesHeading,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _EntriesTable(
                        entries: allEntries,
                        slots: slots,
                        isMarathi: isMarathi,
                        l10n: l10n,
                        theme: theme,
                      ),
                    ],
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _NavCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _EntriesTable extends StatelessWidget {
  final List<SignupEntry> entries;
  final List<SignupSlot> slots;
  final bool isMarathi;
  final AppLocalizations l10n;
  final ThemeData theme;

  const _EntriesTable({
    required this.entries,
    required this.slots,
    required this.isMarathi,
    required this.l10n,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          l10n.signupEntriesEmptyMessage,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.appColors.secondaryText,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    final slotsById = {for (final slot in slots) slot.id: slot};
    final langCode = isMarathi ? 'mr' : 'en';

    final rows = entries.toList()
      ..sort((a, b) {
        final slotA = slotsById[a.slotId];
        final slotB = slotsById[b.slotId];
        final dateA = slotA?.date;
        final dateB = slotB?.date;
        if (dateA == null && dateB != null) return 1;
        if (dateA != null && dateB == null) return -1;
        if (dateA != null && dateB != null) {
          final cmp = dateA.compareTo(dateB);
          if (cmp != 0) return cmp;
        }
        return a.name.compareTo(b.name);
      });

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text(l10n.date)),
          DataColumn(label: Text(l10n.signupEntriesTitleColumn)),
          DataColumn(label: Text(l10n.name)),
          DataColumn(label: Text(l10n.signupEntriesAvailableSlotsColumn)),
        ],
        rows: [
          for (final entry in rows)
            DataRow(
              cells: [
                DataCell(
                  Text(
                    slotsById[entry.slotId]?.date != null
                        ? formatDateShort(
                            slotsById[entry.slotId]!.date!,
                            langCode,
                          )
                        : '-',
                  ),
                ),
                DataCell(Text(_slotLabel(slotsById[entry.slotId]))),
                DataCell(Text(entry.name)),
                DataCell(Text(_availableSlots(slotsById[entry.slotId]))),
              ],
            ),
        ],
      ),
    );
  }

  String _slotLabel(SignupSlot? slot) {
    if (slot == null) return '';
    return isMarathi
        ? (slot.labelMr.isNotEmpty ? slot.labelMr : slot.labelEn)
        : (slot.labelEn.isNotEmpty ? slot.labelEn : slot.labelMr);
  }

  String _availableSlots(SignupSlot? slot) {
    if (slot == null) return '-';
    return (slot.capacity - slot.claimedCount)
        .clamp(0, slot.capacity)
        .toString();
  }
}

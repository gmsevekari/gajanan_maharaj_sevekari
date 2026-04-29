import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/group_namjap_event.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:gajanan_maharaj_sevekari/widgets/themed_icon.dart';
import 'package:gajanan_maharaj_sevekari/utils/marathi_utils.dart';
import 'package:gajanan_maharaj_sevekari/utils/date_time_utils.dart';

import 'package:gajanan_maharaj_sevekari/models/admin_user.dart';

class AdminGroupNamjapListScreen extends StatefulWidget {
  final String status;
  final AdminUser adminUser;
  final FirebaseFirestore? firestore;

  const AdminGroupNamjapListScreen({
    super.key,
    required this.status,
    required this.adminUser,
    this.firestore,
  });

  @override
  State<AdminGroupNamjapListScreen> createState() =>
      _AdminGroupNamjapListScreenState();
}

class _AdminGroupNamjapListScreenState
    extends State<AdminGroupNamjapListScreen> {
  late final FirebaseFirestore _firestore;
  late Stream<QuerySnapshot> _eventsStream;

  @override
  void initState() {
    super.initState();
    _firestore = widget.firestore ?? FirebaseFirestore.instance;
    Query query = _firestore.collection('group_namjap_events');

    if (widget.status == 'upcoming') {
      query = query.where('status', whereIn: ['upcoming', 'enrolling']);
    } else {
      query = query.where('status', isEqualTo: widget.status);
    }

    if (widget.adminUser.groupId != null) {
      query = query.where('groupId', isEqualTo: widget.adminUser.groupId);
    }

    _eventsStream = query.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    String titleStr = widget.status == 'ongoing'
        ? localizations.groupNamjapOngoing
        : widget.status == 'upcoming'
        ? localizations.groupNamjapUpcoming
        : localizations.groupNamjapCompleted;

    return Scaffold(
      appBar: AppBar(
        title: Text(titleStr),
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
      body: StreamBuilder<QuerySnapshot>(
        stream: _eventsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            String emptyMessage = widget.status == 'completed'
                ? localizations.groupNamjapNoCompleted
                : widget.status == 'upcoming'
                ? localizations.groupNamjapNoUpcoming
                : localizations.groupNamjapNoOngoing;

            return Center(
              child: Text(
                emptyMessage,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.appColors.secondaryText,
                ),
              ),
            );
          }

          final events = snapshot.data!.docs
              .map(
                (doc) => GroupNamjapEvent.fromMap(
                  doc.id,
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList();
          events.sort((a, b) => a.startDate.compareTo(b.startDate));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final isEnglish =
                  Localizations.localeOf(context).languageCode == 'en';
              final eventName = isEnglish ? event.nameEn : event.nameMr;

              final langCode = Localizations.localeOf(context).languageCode;

              return Card(
                elevation: theme.cardTheme.elevation,
                shape: theme.cardTheme.shape,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(
                    eventName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        "${formatDateShort(event.startDate, langCode)} - ${formatDateShort(event.endDate, langCode)}",
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${localizations.groupNamjapTargetPrefix}${formatNumberLocalized(event.targetCount, langCode, pad: false)}",
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      Routes.adminGroupNamjapDetail,
                      arguments: {
                        'eventId': event.id,
                        'adminUser': widget.adminUser,
                      },
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/notifications/notification_manager.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class UserNotificationsScreen extends StatefulWidget {
  const UserNotificationsScreen({super.key});

  @override
  State<UserNotificationsScreen> createState() =>
      _UserNotificationsScreenState();
}

class _UserNotificationsScreenState extends State<UserNotificationsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<String> _hiddenNotificationIds = [];
  List<String> _readNotificationIds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAndMarkRead();
  }

  Future<void> _loadAndMarkRead() async {
    // Clear all status bar notifications when viewing the notifications screen
    NotificationManager.cancelAllNotifications();

    final prefs = await SharedPreferences.getInstance();

    // Load hidden and read notifications
    setState(() {
      _hiddenNotificationIds =
          prefs.getStringList('hidden_notifications') ?? [];
      _readNotificationIds = prefs.getStringList('read_notifications') ?? [];
      _isLoading = false;
    });

    // Mark current time as the last read timestamp
    await prefs.setString(
      'last_read_notification_timestamp',
      DateTime.now().toIso8601String(),
    );
  }

  Future<void> _hideNotification(String id) async {
    final prefs = await SharedPreferences.getInstance();
    if (!_hiddenNotificationIds.contains(id)) {
      _hiddenNotificationIds.add(id);
      await prefs.setStringList('hidden_notifications', _hiddenNotificationIds);
      setState(() {});
    }
  }

  // Renders notification body text with tappable URL links
  Widget _buildBodyWithLinks(String body, TextStyle baseStyle) {
    final urlRegex = RegExp(r'https?://[^\s]+', caseSensitive: false);
    final matches = urlRegex.allMatches(body);

    if (matches.isEmpty) {
      return Text(body, style: baseStyle);
    }

    final spans = <TextSpan>[];
    int lastEnd = 0;

    for (final match in matches) {
      if (match.start > lastEnd) {
        spans.add(
          TextSpan(
            text: body.substring(lastEnd, match.start),
            style: baseStyle,
          ),
        );
      }
      final url = body.substring(match.start, match.end);
      spans.add(
        TextSpan(
          text: url,
          style: baseStyle.copyWith(
            color: Theme.of(context).colorScheme.primary,
            decoration: TextDecoration.underline,
            decorationColor: Theme.of(context).colorScheme.primary,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () async {
              final uri = Uri.tryParse(url);
              if (uri != null && await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
        ),
      );
      lastEnd = match.end;
    }

    if (lastEnd < body.length) {
      spans.add(TextSpan(text: body.substring(lastEnd), style: baseStyle));
    }

    return RichText(
      text: TextSpan(style: baseStyle, children: spans),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final localizations = AppLocalizations.of(context)!;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(localizations.allNotifications)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.allNotifications),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil(Routes.home, (route) => false);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, Routes.settings),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('notifications')
            .where(
              'timestamp',
              isGreaterThanOrEqualTo: DateTime.now()
                  .subtract(const Duration(days: 30))
                  .toIso8601String(),
            )
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(localizations.noResultsFound));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          final visibleDocs = docs
              .where((doc) => !_hiddenNotificationIds.contains(doc.id))
              .toList();

          if (visibleDocs.isEmpty) {
            return _buildEmptyState(theme, localizations);
          }

          final sections = _groupNotifications(visibleDocs, localizations);

          return Column(
            children: [
              _buildInfoBanner(context, theme),
              Expanded(
                child: ListView.builder(
                  itemCount: sections.length,
                  padding: const EdgeInsets.only(bottom: 16),
                  itemBuilder: (context, index) {
                    final section = sections[index];
                    if (section is String) {
                      return _buildSectionHeader(section, theme);
                    } else {
                      return _buildNotificationCard(
                        section as QueryDocumentSnapshot,
                        theme,
                        localizations,
                      );
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatNumber(BuildContext context, int number, {bool pad = true}) {
    String numStr = pad ? number.toString().padLeft(2, '0') : number.toString();
    final isMarathi = Localizations.localeOf(context).languageCode == 'mr';
    if (!isMarathi) return numStr;

    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const marathi = ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'];
    for (int i = 0; i < english.length; i++) {
      numStr = numStr.replaceAll(english[i], marathi[i]);
    }
    return numStr;
  }

  Widget _buildInfoBanner(BuildContext context, ThemeData theme) {
    final localizations = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              localizations.notificationRetentionMessage(
                _formatNumber(context, 30, pad: false),
              ),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, AppLocalizations localizations) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 80,
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
            ),
            const SizedBox(height: 24),
            Text(
              localizations.noNewNotifications,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            _buildInfoBanner(context, theme),
          ],
        ),
      ),
    );
  }

  List<dynamic> _groupNotifications(
    List<QueryDocumentSnapshot> docs,
    AppLocalizations localizations,
  ) {
    final List<dynamic> result = [];
    String? lastGroup;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final twoDaysAgo = today.subtract(const Duration(days: 2));

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final timestampStr = data['timestamp'] as String?;
      if (timestampStr == null) continue;

      final date = DateTime.parse(timestampStr);
      final notificationDate = DateTime(date.year, date.month, date.day);

      final locale = Localizations.localeOf(context).toString();
      String groupTitle;
      final difference = today.difference(notificationDate).inDays;

      if (notificationDate == today) {
        groupTitle = localizations.today;
      } else if (notificationDate == yesterday) {
        groupTitle = localizations.yesterday;
      } else if (notificationDate == twoDaysAgo) {
        groupTitle = DateFormat(
          'EEEE',
          locale,
        ).format(date); // Localized Day name
      } else if (difference <= 7) {
        groupTitle = localizations.lastWeek;
      } else if (difference <= 14) {
        groupTitle = localizations.twoWeeksBack(
          _formatNumber(context, 2, pad: false),
        );
      } else if (difference <= 21) {
        groupTitle = localizations.threeWeeksBack(
          _formatNumber(context, 3, pad: false),
        );
      } else {
        groupTitle = localizations.older;
      }

      if (groupTitle != lastGroup) {
        result.add(groupTitle);
        lastGroup = groupTitle;
      }
      result.add(doc);
    }

    return result;
  }

  Widget _buildNotificationCard(
    QueryDocumentSnapshot doc,
    ThemeData theme,
    AppLocalizations localizations,
  ) {
    final data = doc.data() as Map<String, dynamic>;
    final title =
        data['title'] as String? ?? localizations.notificationDefaultTitle;
    final body = data['body'] as String? ?? '';
    final timestampStr = data['timestamp'] as String?;
    final isRead = _readNotificationIds.contains(doc.id);

    String timeStr = '';
    if (timestampStr != null) {
      try {
        final timestamp = DateTime.parse(timestampStr);
        timeStr = DateFormat.jm().format(timestamp);
      } catch (e) {
        timeStr = '';
      }
    }

    return Dismissible(
      key: Key(doc.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _hideNotification(doc.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        color: theme.colorScheme.error,
        child: Icon(Icons.delete, color: theme.colorScheme.onError),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        elevation: theme.cardTheme.elevation,
        color:
            isRead
                ? theme.cardTheme.color?.withValues(alpha: 0.6)
                : theme.cardTheme.color,
        shape: theme.cardTheme.shape,
        child: Opacity(
          opacity: isRead ? 0.7 : 1.0,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight:
                                  isRead ? FontWeight.w500 : FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildBodyWithLinks(
                            body,
                            theme.textTheme.bodyMedium!.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          timeStr,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 8),
                        IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.4,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _hideNotification(doc.id),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

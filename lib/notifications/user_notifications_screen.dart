import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
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
      text: TextSpan(
        style: baseStyle,
        children: spans,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final localizations = AppLocalizations.of(context)!;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(localizations.templeNotifications)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(localizations.templeNotifications)),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('notifications')
            .where(
              'timestamp',
              isGreaterThanOrEqualTo: DateTime.now()
                  .subtract(const Duration(days: 14))
                  .toIso8601String(),
            )
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(localizations.noResultsFound),
            ); // Using existing key for generic failure
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          final visibleDocs = docs
              .where((doc) => !_hiddenNotificationIds.contains(doc.id))
              .toList();

          if (visibleDocs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    localizations.noNewNotifications,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: visibleDocs.length,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemBuilder: (context, index) {
              final doc = visibleDocs[index];
              final data = doc.data() as Map<String, dynamic>;

              final title =
                  data['title'] as String? ??
                  localizations.notificationDefaultTitle;
              final body = data['body'] as String? ?? '';
              final timestampStr = data['timestamp'] as String?;
              final isRead = _readNotificationIds.contains(doc.id);

              String timeAgo = '';
              if (timestampStr != null) {
                try {
                  final timestamp = DateTime.parse(timestampStr);
                  timeAgo = DateFormat.yMMMd().add_jm().format(timestamp);
                } catch (e) {
                  timeAgo = localizations.notificationRecently;
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
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 6.0,
                  ),
                  elevation: isRead ? 0 : 2,
                  color: isRead
                      ? theme.cardTheme.color?.withValues(alpha: 0.6)
                      : theme.cardTheme.color,
                  shape:
                      theme.cardTheme.shape ??
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                  child: Opacity(
                    opacity: isRead ? 0.6 : 1.0,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer
                                      .withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.campaign,
                                  color: theme.colorScheme.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  title,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 20,
                                ),
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.4,
                                ),
                                tooltip:
                                    localizations.notificationDeleteTooltip,
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(),
                                onPressed: () => _hideNotification(doc.id),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildBodyWithLinks(
                            body,
                            theme.textTheme.bodyMedium!.copyWith(height: 1.4),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            timeAgo,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

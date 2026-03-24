import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/admin/admin_audit_service.dart';
import 'package:gajanan_maharaj_sevekari/admin/admin_session_service.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';

class AdminTempleNotificationsScreen extends StatefulWidget {
  const AdminTempleNotificationsScreen({super.key});

  @override
  State<AdminTempleNotificationsScreen> createState() =>
      _AdminTempleNotificationsScreenState();
}

class _AdminTempleNotificationsScreenState
    extends State<AdminTempleNotificationsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isSending = false;

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;

    final user = _auth.currentUser;
    final localizations = AppLocalizations.of(context)!;
    if (user == null || user.email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.notAuthenticatedError)),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final title = _titleController.text.trim();
      final body = _bodyController.text.trim();
      final now = DateTime.now();

      // 1. Write to the User Notifications collection
      await _firestore.collection('notifications').add({
        'title': title,
        'body': body,
        'timestamp': now.toIso8601String(),
        'expires_at': Timestamp.fromDate(now.add(const Duration(days: 30))),
        'type': 'TEMPLE_NOTIFICATION',
      });

      // 2. Write to the Audit Logs
      await AdminAuditService.logAction(
        action: 'SEND_TEMPLE_NOTIFICATION',
        details: {'title': title, 'body': body},
      );

      // 3. Backend Triggered FCM
      // The push notification is now handled securely by Firebase Cloud Functions.
      // The backend listens for the 'TEMPLE_NOTIFICATION' document creation we just
      // performed above, and sends the payload to the FCM topic automatically.

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.notificationSentSuccess)),
      );

      _titleController.clear();
      _bodyController.clear();
    } catch (e) {
      debugPrint('Error sending notification: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.notificationSendError(e.toString())),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    return Listener(
      onPointerDown: (_) => AdminSessionService.registerInteraction(),
      onPointerMove: (_) => AdminSessionService.registerInteraction(),
      onPointerUp: (_) => AdminSessionService.registerInteraction(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            AppLocalizations.of(context)!.templeNotificationsModuleTitle,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                Routes.home,
                (route) => false,
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: theme.cardTheme.elevation ?? 2,
            color: theme.cardTheme.color,
            shape:
                theme.cardTheme.shape ??
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              localizations.broadcastNotificationInstruction,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: localizations.notificationTitleLabel,
                        hintText: localizations.notificationTitleHint,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.title),
                      ),
                      maxLength: 65,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return localizations.notificationTitleRequired;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _bodyController,
                      decoration: InputDecoration(
                        labelText: localizations.notificationMessageLabel,
                        hintText: localizations.notificationMessageHint,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.message),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 4,
                      maxLength: 240,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return localizations.notificationMessageRequired;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    if (_isSending)
                      const Center(child: CircularProgressIndicator())
                    else
                      ElevatedButton.icon(
                        onPressed: _sendNotification,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        icon: const Icon(Icons.send),
                        label: Text(localizations.broadcastButtonLabel),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

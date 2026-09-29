import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

/// Two icon buttons — "Text" (native SMS composer) and "WhatsApp" — that
/// launch a chat with [phone] on tap. Silently does nothing if the device
/// can't handle the corresponding link (matches the pre-existing WhatsApp
/// button's behavior).
class ParticipantContactActions extends StatelessWidget {
  final String phone;
  final String textTooltip;
  final String whatsAppTooltip;

  const ParticipantContactActions({
    super.key,
    required this.phone,
    this.textTooltip = 'Text',
    this.whatsAppTooltip = 'WhatsApp',
  });

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final digitsWithPlus = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final digitsOnly = phone.replaceAll(RegExp(r'\D'), '');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.sms_outlined, color: theme.colorScheme.primary),
          tooltip: textTooltip,
          onPressed: () => _launch('sms:$digitsWithPlus'),
        ),
        IconButton(
          icon: Icon(Icons.message, color: theme.appColors.success),
          tooltip: whatsAppTooltip,
          onPressed: () => _launch('https://wa.me/$digitsOnly'),
        ),
      ],
    );
  }
}

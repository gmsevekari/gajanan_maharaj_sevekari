import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

/// Two icon buttons — "Text" (native SMS composer) and "WhatsApp" — that
/// launch a chat with [phone] on tap. Silently does nothing if the device
/// can't handle the corresponding link (matches the pre-existing WhatsApp
/// button's behavior).
class ParticipantContactActions extends StatelessWidget {
  static final RegExp _nonDigitOrPlus = RegExp(r'[^\d+]');
  static final RegExp _nonDigit = RegExp(r'\D');

  final String phone;
  final String textTooltip;
  final String whatsAppTooltip;

  const ParticipantContactActions({
    super.key,
    required this.phone,
    this.textTooltip = 'Text',
    this.whatsAppTooltip = 'WhatsApp',
  });

  /// Digits only, with a single leading `+` preserved if present — safe for
  /// the `sms:` scheme even if [phone] contains a stray `+` mid-string.
  String get _digitsWithLeadingPlus {
    final stripped = phone.replaceAll(_nonDigitOrPlus, '');
    final digits = stripped.replaceAll('+', '');
    return stripped.startsWith('+') ? '+$digits' : digits;
  }

  String get _digitsOnly => phone.replaceAll(_nonDigit, '');

  static Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final digitsWithPlus = _digitsWithLeadingPlus;
    final digitsOnly = _digitsOnly;

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

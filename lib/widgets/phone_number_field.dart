import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/models/app_config.dart';
import 'package:gajanan_maharaj_sevekari/providers/app_config_provider.dart';
import 'package:gajanan_maharaj_sevekari/utils/group_utils.dart';
import 'package:gajanan_maharaj_sevekari/utils/phone_utils.dart';
import 'package:provider/provider.dart';

/// A country code box beside a phone number box, like the Parayan sign-up's.
///
/// Both fields belong to the enclosing [Form]: the code must be a `+` and
/// one to four digits, and the number needs [minPhoneDigits] digits for that
/// code (spaces and dashes don't count). When [required] is false a blank
/// number is accepted, but one that is entered is still checked.
class PhoneNumberField extends StatelessWidget {
  static const double _codeFieldWidth = 80;
  static const int _maxNumberLength = 30;
  static const int _maxCodeLength = 5;

  final TextEditingController codeController;
  final TextEditingController numberController;
  final String label;
  final bool required;
  final String requiredMessage;
  final String invalidMessage;
  final Key? codeKey;
  final Key? numberKey;

  const PhoneNumberField({
    super.key,
    required this.codeController,
    required this.numberController,
    required this.label,
    required this.requiredMessage,
    required this.invalidMessage,
    this.required = true,
    this.codeKey,
    this.numberKey,
  });

  String? _validateCode(String? value) =>
      isValidCountryCode(value) ? null : '!';

  String? _validateNumber(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return required ? requiredMessage : null;
    final digits = text.replaceAll(RegExp(r'\D'), '').length;
    return digits < minPhoneDigits(codeController.text) ? invalidMessage : null;
  }

  InputDecoration _decoration(String labelText, {String? hint}) =>
      InputDecoration(
        labelText: labelText,
        hintText: hint,
        isDense: true,
        counterText: '',
        border: const OutlineInputBorder(),
      );

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: _codeFieldWidth,
          child: TextFormField(
            key: codeKey,
            controller: codeController,
            keyboardType: TextInputType.phone,
            maxLength: _maxCodeLength,
            decoration: _decoration('Code', hint: '+1'),
            validator: _validateCode,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            key: numberKey,
            controller: numberController,
            keyboardType: TextInputType.phone,
            maxLength: _maxNumberLength,
            decoration: _decoration(label),
            validator: _validateNumber,
          ),
        ),
      ],
    );
  }
}

/// The default country code for [groupId], from the app config when one is
/// provided above [context], else the app-wide default. Tolerates a missing
/// provider so widgets using it can be built without the app shell.
String defaultCountryCodeFor(BuildContext context, String? groupId) {
  try {
    final AppConfig? config = context.read<AppConfigProvider>().appConfig;
    return config?.getDefaultCountryCode(groupId) ??
        GroupConstants.defaultCountryCode;
  } on ProviderNotFoundException {
    return GroupConstants.defaultCountryCode;
  }
}

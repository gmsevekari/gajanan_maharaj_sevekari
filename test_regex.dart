import 'dart:core';

void main() {
  String text = '''
स. १०:३०: अभिषेक
स. ११:३०: वस्त्रालंकार
दु. १२:००: साईबाबा मध्यान आरती
दु. १२:३०: गजानन महाराज मध्यान आरती
दु. ०१:००: प्रसाद
''';

  final regex = RegExp(r'(?:(स\.|दु\.|सं\.|रा\.|am|pm|AM|PM)\s+)?([०-९0-9]{1,2}):([०-९0-9]{2})(?:\s+(am|pm|AM|PM))?');
  
  for (final match in regex.allMatches(text)) {
    print('Match: ${match.group(0)}');
    print('Prefix: ${match.group(1)}');
    print('Hour: ${match.group(2)}');
    print('Min: ${match.group(3)}');
    print('Suffix: ${match.group(4)}');
    print('---');
  }
}

import 'dart:core';

void main() {
  String text = '''
10:30 am: Abhishek
11:30 am: Vastralankar
12:00 pm: Sai baba Arti
12:30 pm: Gajanan Maharaj Arti
01:00 pm: Prasad
''';

  final regex = RegExp(r'((?:स\.|दु\.|सं\.|रा\.|am|pm|AM|PM)\s+)?([०-९0-9]{1,2}):([०-९0-9]{2})(?:\s+(am|pm|AM|PM))?');
  
  for (final match in regex.allMatches(text)) {
    print('Match: ${match.group(0)}');
    print('Prefix: ${match.group(1)}');
    print('Hour: ${match.group(2)}');
    print('Min: ${match.group(3)}');
    print('Suffix: ${match.group(4)}');
    
    int h = int.parse(match.group(2)!);
    final period = (match.group(1) ?? match.group(4) ?? '').toLowerCase().trim();
    print('Period: "$period"');
    if (period == 'दु.' || period == 'सं.' || period == 'रा.' || period == 'pm') {
      if (h < 12) h += 12;
    } else if (period == 'स.' || period == 'am') {
      if (h == 12) h = 0;
    }
    print('Parsed Hour (24h): $h');
    print('---');
  }
}

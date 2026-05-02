import 'package:intl/intl.dart';

void main() {
  int offsetMinutes = 750; // +12.5 hours

  void testTime(String textName, int origH, int origM) {
    int totalMinutes = origH * 60 + origM + offsetMinutes;
    totalMinutes = (totalMinutes % (24 * 60) + (24 * 60)) % (24 * 60);

    int newHour = totalMinutes ~/ 60;
    int newMin = totalMinutes % 60;

    final dummyDate = DateTime(2000, 1, 1, newHour, newMin);

    String enFormat = DateFormat('h:mm a', 'en').format(dummyDate).toLowerCase();
    
    String mrPeriod;
    if (newHour >= 5 && newHour < 12) {
      mrPeriod = "स.";
    } else if (newHour >= 12 && newHour < 17) {
      mrPeriod = "दु.";
    } else if (newHour >= 17 && newHour < 20) {
      mrPeriod = "सं.";
    } else {
      mrPeriod = "रा.";
    }
    String mrFormat = '$mrPeriod ${DateFormat('h:mm').format(dummyDate)}';

    print('$textName ($origH:$origM + $offsetMinutes min) -> en: $enFormat, mr: $mrFormat');
  }

  testTime('Abhishek (10:30 AM)', 10, 30);
  testTime('Vastralankar (11:30 AM)', 11, 30);
  testTime('Sai Baba Aarti (12:00 PM)', 12, 0);
  testTime('Gajanan Aarti (12:30 PM)', 12, 30);
  testTime('Prasad (1:00 PM)', 13, 0);
}

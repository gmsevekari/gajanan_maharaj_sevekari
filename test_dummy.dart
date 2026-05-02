import 'package:intl/intl.dart';

void main() {
  var d1 = DateTime(2000, 1, 1, 0, 30);
  print('0:30 -> ' + DateFormat('h:mm a', 'en').format(d1));
  
  var d2 = DateTime(2000, 1, 1, 1, 0);
  print('1:00 -> ' + DateFormat('h:mm a', 'en').format(d2));
}

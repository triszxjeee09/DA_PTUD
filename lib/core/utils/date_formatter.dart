import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final DateFormat _date = DateFormat('dd/MM/yyyy');
  static final DateFormat _dateTime = DateFormat('dd/MM/yyyy HH:mm');

  static String formatDate(DateTime value) {
    return _date.format(value);
  }

  static String formatDateTime(DateTime value) {
    return _dateTime.format(value);
  }
}

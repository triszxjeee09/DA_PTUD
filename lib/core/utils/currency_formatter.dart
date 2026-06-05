import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _vietnameseCurrency = NumberFormat.decimalPattern(
    'vi_VN',
  );

  static String format(num value) {
    return '${_vietnameseCurrency.format(value)}đ';
  }
}

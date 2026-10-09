import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _numberFormat = NumberFormat('#,###', 'vi_VN');

  static String formatVND(double amount) {
    // Standard Vietnamese format: 150.000 đ
    final formattedNumber = _numberFormat.format(amount).replaceAll(',', '.');
    return '$formattedNumber đ';
  }

  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  static String formatDayOfWeek(DateTime date) {
    const days = ['Th 2', 'Th 3', 'Th 4', 'Th 5', 'Th 6', 'Th 7', 'CN'];
    return days[date.weekday - 1];
  }

  static String formatDayGroup(DateTime date, {DateTime? today}) {
    final now = today ?? DateTime.now();
    final day = DateTime(date.year, date.month, date.day);
    final start = DateTime(now.year, now.month, now.day);
    final diff = start.difference(day).inDays;
    if (diff == 0) return 'Hôm nay';
    if (diff == 1) return 'Hôm qua';
    return '${formatDayOfWeek(date)}, ${formatDate(date)}';
  }
}

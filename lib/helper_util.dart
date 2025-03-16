import 'package:intl/intl.dart';

class HelperUtil {
  static bool isTodayWithinDateRange(String startDate, String endDate) {
    DateTime start = DateTime.parse(startDate);
    DateTime end = DateTime.parse(endDate);
    DateTime today = DateTime.now();
    return today.isAfter(start) && today.isBefore(end) ||
        today.isAtSameMomentAs(start) ||
        today.isAtSameMomentAs(end);
  }

  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }
}

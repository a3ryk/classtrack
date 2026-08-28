import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final _dateOnlyFormat = DateFormat('yyyy-MM-dd');
  static final _displayDateFormat = DateFormat('EEE, d MMM');
  static final _fullDateFormat = DateFormat('EEEE, d MMMM yyyy');
  static final _monthYearFormat = DateFormat('MMMM yyyy');
  static final _headerDateFormat = DateFormat('EEEE, d MMM');
  static final _indianDateFormat = DateFormat('dd/MM/yyyy');
  static final _indianDisplayFormat = DateFormat('d MMM yyyy');

  /// Format date to "Tuesday, 25 Aug" (Indian day-first standard)
  static String formatHeaderDate(DateTime date) {
    return _headerDateFormat.format(date);
  }

  /// Format date to "25/08/2026" (DD/MM/YYYY Indian standard)
  static String formatDateIndian(DateTime date) {
    return _indianDateFormat.format(date);
  }

  /// Format date to "25 Aug 2026"
  static String formatIndianDisplay(DateTime date) {
    return _indianDisplayFormat.format(date);
  }

  /// Converts ISO date string (YYYY-MM-DD) to Indian format "25/08/2026"
  static String formatIsoToIndian(String isoDate) {
    try {
      final dt = parseIsoDate(isoDate);
      return _indianDateFormat.format(dt);
    } catch (_) {
      return isoDate;
    }
  }

  /// Converts ISO date string (YYYY-MM-DD) to display format "25 Aug 2026"
  static String formatIsoToDisplay(String isoDate) {
    try {
      final dt = parseIsoDate(isoDate);
      return _indianDisplayFormat.format(dt);
    } catch (_) {
      return isoDate;
    }
  }

  /// Format DateTime to YYYY-MM-DD string
  static String toIsoDate(DateTime date) {
    return _dateOnlyFormat.format(date);
  }

  /// Parse YYYY-MM-DD string to DateTime
  static DateTime parseIsoDate(String dateString) {
    return _dateOnlyFormat.parse(dateString);
  }

  /// Format date to "Mon, 19 Aug"
  static String formatShortDisplay(DateTime date) {
    return _displayDateFormat.format(date);
  }

  /// Format date to "Monday, 19 August 2026"
  static String formatFullDisplay(DateTime date) {
    return _fullDateFormat.format(date);
  }

  /// Format to "August 2026"
  static String formatMonthYear(DateTime date) {
    return _monthYearFormat.format(date);
  }

  /// Format 24h string "09:00" to 12h display "9:00 AM"
  static String formatTime12h(String time24) {
    try {
      final parts = time24.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final dt = DateTime(2026, 1, 1, hour, minute);
      return DateFormat('h:mm a').format(dt);
    } catch (_) {
      return time24;
    }
  }

  /// Calculates day of week index: 1 = Monday, 7 = Sunday
  static int getDayOfWeek(DateTime date) {
    return date.weekday;
  }
}

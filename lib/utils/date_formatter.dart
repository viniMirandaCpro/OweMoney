import 'package:intl/intl.dart';

/// Utility class for formatting dates in Brazilian format
/// 
/// Provides consistent date formatting and relative date strings
/// throughout the app (e.g., "hoje", "ontem", "15/10/2025")
class DateFormatter {
  // Private constructor to prevent instantiation
  DateFormatter._();

  // Brazilian date formatter (dd/MM/yyyy)
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  
  // Short date formatter (dd/MM)
  static final DateFormat _shortDateFormat = DateFormat('dd/MM');

  /// Formats a DateTime as dd/MM/yyyy
  /// 
  /// Example: DateTime(2025, 10, 16) -> "16/10/2025"
  static String format(DateTime date) {
    return _dateFormat.format(date);
  }

  /// Formats a DateTime as dd/MM (without year)
  /// 
  /// Useful for recent dates where year is obvious
  static String formatShort(DateTime date) {
    return _shortDateFormat.format(date);
  }

  /// Returns a relative date string when possible, otherwise formatted date
  /// 
  /// Examples:
  /// - Today -> "hoje"
  /// - Yesterday -> "ontem"
  /// - This year -> "15/10"
  /// - Previous years -> "15/10/2024"
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    // Check if it's today
    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else if (date.year == now.year) {
      return formatShort(date);
    } else {
      return format(date);
    }


  }

  /// Parses a date string in dd/MM/yyyy format
  /// 
  /// Returns null if parsing fails
  static DateTime? parse(String dateString) {
    try {
      return _dateFormat.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// Returns the current date with time set to midnight
  /// 
  /// Useful for date comparisons and default values
  static DateTime today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
}



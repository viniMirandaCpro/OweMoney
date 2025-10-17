import 'package:intl/intl.dart';

/// Utility class for formatting currency values in Brazilian Real (R$)
/// 
/// This provides consistent currency formatting throughout the app,
/// ensuring all monetary values are displayed with proper locale formatting
class CurrencyFormatter {
  // Private constructor to prevent instantiation
  CurrencyFormatter._();

  // Brazilian Real formatter with locale settings
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );

  /// Formats a double value as Brazilian Real currency
  /// 
  /// Example: 1234.56 -> "R$ 1.234,56"
  /// Example: -500.00 -> "-R$ 500,00"
  static String format(double value) {
    return _formatter.format(value);
  }

  /// Formats a double value with color context
  /// 
  /// Returns the formatted value without sign prefixes for display
  /// Useful when the sign is already indicated by color
  static String formatAbsolute(double value) {
    return _formatter.format(value.abs());
  }

  /// Parses a currency string to double
  /// 
  /// Handles both "R$ 1.234,56" and "1234,56" formats
  /// Returns null if parsing fails
  static double? parse(String value) {
    try {
      // Remove currency symbol and spaces
      String cleaned = value
          .replaceAll('R\$', '')
          .replaceAll(' ', '')
          .trim();
      
      // Replace comma with dot for decimal parsing
      cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
      
      return double.parse(cleaned);
    } catch (e) {
      return null;
    }
  }

  /// Formats input text for currency TextField
  /// 
  /// Converts user input to proper currency format as they type
  static String formatInput(String value) {
    if (value.isEmpty) return '';
    
    // Remove all non-digit characters
    String digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
    
    if (digitsOnly.isEmpty) return '';
    
    // Convert to cents and then to double
    double amount = double.parse(digitsOnly) / 100;
    
    return format(amount);
  }
}



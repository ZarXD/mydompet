import 'package:intl/intl.dart';

class Formatters {
  static final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  
  static final _dateFormat = DateFormat('dd MMM yyyy', 'id_ID');
  static final _dateTimeFormat = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
  static final _shortDateFormat = DateFormat('dd/MM/yy');
  
  /// Format amount to Indonesian Rupiah
  static String formatCurrency(double amount) {
    return _currencyFormat.format(amount);
  }
  
  /// Format amount with compact notation (e.g., 1.5jt)
  static String formatCompactCurrency(double amount) {
    if (amount >= 1000000000) {
      final value = amount / 1000000000;
      return 'Rp ${_formatNumber(value)}M';
    } else if (amount >= 1000000) {
      final value = amount / 1000000;
      return 'Rp ${_formatNumber(value)}jt';
    } else if (amount >= 1000) {
      final value = amount / 1000;
      return 'Rp ${_formatNumber(value)}rb';
    }
    return formatCurrency(amount);
  }
  
  /// Format number without trailing .0
  static String _formatNumber(double value) {
    if (value == value.toInt()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }
  
  /// Format date in Indonesian format
  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }
  
  /// Format date with time
  static String formatDateTime(DateTime date) {
    return _dateTimeFormat.format(date);
  }
  
  /// Format date for display in transaction list
  static String formatTransactionDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final transactionDate = DateTime(date.year, date.month, date.day);
    
    if (transactionDate == today) {
      return 'Hari ini';
    } else if (transactionDate == yesterday) {
      return 'Kemarin';
    } else if (now.difference(date).inDays < 7) {
      return DateFormat('EEEE', 'id_ID').format(date);
    }
    return _shortDateFormat.format(date);
  }
  
  /// Format date for home screen with both day label and date
  static String formatHomeTransactionDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final transactionDate = DateTime(date.year, date.month, date.day);
    final dateStr = _shortDateFormat.format(date);
    
    if (transactionDate == today) {
      return 'Hari ini - $dateStr';
    } else if (transactionDate == yesterday) {
      return 'Kemarin - $dateStr';
    } else if (now.difference(date).inDays < 7) {
      final dayName = DateFormat('EEEE', 'id_ID').format(date);
      return '$dayName - $dateStr';
    }
    return dateStr;
  }
  
  /// Format percentage
  static String formatPercentage(double value) {
    return '${(value * 100).toStringAsFixed(1)}%';
  }
}

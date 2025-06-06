import 'package:intl/intl.dart'; // Using the intl package for robust number formatting

class NumberFormatter {
  // Formats a count into a more readable string (e.g., 1.2K, 5M)
  static String formatCount(int count) {
    if (count < 1000) {
      return count.toString();
    } else if (count < 1000000) {
      // Format as K for thousands (e.g., 1.2K, 120K)
      double thousands = count / 1000.0;
      // Use NumberFormat for consistent decimal places and locale-awareness if needed
      return '${NumberFormat('0.#', 'en_US').format(thousands)}K';
    } else if (count < 1000000000) {
      // Format as M for millions (e.g., 1.2M, 120M)
      double millions = count / 1000000.0;
      return '${NumberFormat('0.#', 'en_US').format(millions)}M';
    } else {
      // Format as B for billions (e.g., 1.2B)
      double billions = count / 1000000000.0;
      return '${NumberFormat('0.#', 'en_US').format(billions)}B';
    }
  }

  // You can add other formatting methods here if needed
  // For example, formatting currency, percentages, etc.
}
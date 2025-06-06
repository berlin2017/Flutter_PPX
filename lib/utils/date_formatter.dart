class DateFormatter {
  // Renamed from formatTimestamp to formatRelativeTime
  static String formatRelativeTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}年前';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}月前';
    } else if (difference.inDays > 7) { // Optional: Add weeks
      return '${(difference.inDays / 7).floor()}周前';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }

// You can add other date formatting methods here if needed, e.g.:
// static String formatDate(DateTime date, {String format = 'yyyy-MM-dd'}) {
//   return DateFormat(format).format(date);
// }
//
// static String formatDateTime(DateTime dateTime, {String format = 'yyyy-MM-dd HH:mm'}) {
//   return DateFormat(format).format(dateTime);
// }
}
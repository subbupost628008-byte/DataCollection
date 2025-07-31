import 'package:intl/intl.dart';


String formatTimestamp(dynamic timestamp) {
  if (timestamp == null) return 'N/A';

  try {
    DateTime dt;

    if (timestamp is int || timestamp is double) {
      // Handle Unix epoch milliseconds
      dt = DateTime.fromMillisecondsSinceEpoch(timestamp.toInt());
    } else if (timestamp is String && RegExp(r'^\d+$').hasMatch(timestamp)) {
      // String number (still epoch time)
      dt = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
    } else {
      // Assume ISO8601 format
      dt = DateTime.parse(timestamp.toString());
    }

    return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
  } catch (_) {
    return 'Invalid Date';
  }
}

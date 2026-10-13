import '../../ride/shared/utils/date_formatter.dart';

/// A notification's age for the inbox: "Just now", "N min ago", "N h ago",
/// "Yesterday", then the `dd/MM/yyyy` date (no `intl` dependency in the
/// project). Unparseable input → `""`. [now] is for tests.
String formatNotificationTime(String iso, {DateTime? now}) {
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) return '';
  final created = parsed.toLocal();
  final current = now ?? DateTime.now();

  final elapsed = current.difference(created);
  // A server clock slightly ahead of the phone's lands here too.
  if (elapsed.inMinutes < 1) return 'Just now';
  if (elapsed.inHours < 1) return '${elapsed.inMinutes} min ago';
  if (elapsed.inHours < 24) return '${elapsed.inHours} h ago';

  // Built from the calendar, so month ends and DST changes can't skew it.
  final yesterday = DateTime(current.year, current.month, current.day - 1);
  if (created.year == yesterday.year &&
      created.month == yesterday.month &&
      created.day == yesterday.day) {
    return 'Yesterday';
  }
  // The local date, to agree with "Yesterday": formatRideDate on the server's
  // UTC string would print the UTC date.
  return formatRideDate(created.toIso8601String());
}

const weekdayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

// Monday of the week that d is in
DateTime startOfWeek(DateTime d) =>
    DateTime(d.year, d.month, d.day - (d.weekday - 1));

// ISO week number (weeks start on monday, week 1 has the first thursday)
int weekNumber(DateTime d) {
  final date = DateTime.utc(d.year, d.month, d.day);
  final thursday = date.add(Duration(days: 4 - date.weekday));
  final firstOfYear = DateTime.utc(thursday.year, 1, 1);
  return thursday.difference(firstOfYear).inDays ~/ 7 + 1;
}

String twoDigits(int n) => n.toString().padLeft(2, '0');

String formatTime(DateTime d) => '${twoDigits(d.hour)}:${twoDigits(d.minute)}';

DateTime addDays(DateTime d, int days) =>
    DateTime(d.year, d.month, d.day + days);

// whole days from a to b (done in utc so summer time doesn't mess it up)
int daysBetween(DateTime a, DateTime b) => DateTime.utc(b.year, b.month, b.day)
    .difference(DateTime.utc(a.year, a.month, a.day))
    .inDays;

// e.g. "Sep 14 - 20"
String weekRange(DateTime d) {
  final monday = startOfWeek(d);
  final sunday = addDays(monday, 6);
  final start = '${monthNames[monday.month - 1]} ${monday.day}';
  final end = monday.month == sunday.month
      ? '${sunday.day}'
      : '${monthNames[sunday.month - 1]} ${sunday.day}';
  return '$start - $end';
}

// e.g. "WEEK 38 · SEP 14 - 20"
String weekLabel(DateTime d) =>
    'WEEK ${weekNumber(d)} · ${weekRange(d)}'.toUpperCase();

// A block in the calendar. Fixed events can't be moved by the rescheduler,
// flexible ones can.
class CalendarEvent {
  final String title;
  final DateTime start;
  final DateTime end;
  final bool fixed;

  const CalendarEvent({
    required this.title,
    required this.start,
    required this.end,
    this.fixed = false,
  });
}

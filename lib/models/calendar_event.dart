import 'task_draft.dart';

// A block in the calendar. Fixed events can't be moved by the rescheduler,
// flexible ones can.
class CalendarEvent {
  final String title;
  final DateTime start;
  final DateTime end;
  final bool fixed;
  final String? label;
  final Priority priority;
  // the window a flexible event has to stay in (earliest start and deadline)
  final DateTime? windowStart;
  final DateTime? windowEnd;

  const CalendarEvent({
    required this.title,
    required this.start,
    required this.end,
    this.fixed = false,
    this.label,
    this.priority = Priority.normal,
    this.windowStart,
    this.windowEnd,
  });
}

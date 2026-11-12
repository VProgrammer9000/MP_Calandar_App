import '../utils/dates.dart';
import 'calendar_event.dart';

enum ChangeType { add, move, delete }

// One change the assistant wants to make to the calendar. Nothing is changed
// until the user accepts it.
class CalendarChange {
  final ChangeType type;
  // the event that is moved or deleted, null when adding
  final CalendarEvent? event;
  // the new event when adding, the new time when moving
  final String title;
  final DateTime? start;
  final DateTime? end;

  const CalendarChange({
    required this.type,
    required this.title,
    this.event,
    this.start,
    this.end,
  });

  // made from the JSON the LLM answers with. The LLM points to an event by its
  // number in the list we sent it, so the same list has to be passed in here
  factory CalendarChange.fromJson(
    Map<String, dynamic> json,
    List<CalendarEvent> events,
  ) {
    final type = _readType(json['type']);

    if (type == ChangeType.add) {
      final title = json['title'];
      if (title is! String || title.trim().isEmpty) {
        throw const FormatException('The new event has no title');
      }
      final (start, end) = _readTimes(json, 'start', 'end');
      return CalendarChange(
        type: type,
        title: title.trim(),
        start: start,
        end: end,
      );
    }

    final index = json['event'];
    if (index is! int || index < 0 || index >= events.length) {
      throw const FormatException('The change points to an unknown event');
    }
    final event = events[index];

    if (type == ChangeType.delete) {
      return CalendarChange(type: type, title: event.title, event: event);
    }

    if (event.fixed) {
      throw const FormatException('Fixed events can not be moved');
    }
    // other names than for an add, so the LLM doesn't copy the old times
    final (start, end) = _readTimes(json, 'new_start', 'new_end');
    // the LLM sometimes says it moved something but gives the same time
    if (start == event.start && end == event.end) {
      throw const FormatException('The event is moved to where it already is');
    }
    return CalendarChange(
      type: type,
      title: event.title,
      event: event,
      start: start,
      end: end,
    );
  }

  // One line for the chat history, so the LLM knows what it proposed before.
  // e.g. 'move "Gym" from Wed 11 Nov 18:00-19:00 to Wed 11 Nov 19:00-20:00'
  String describe() {
    switch (type) {
      case ChangeType.add:
        return 'add "$title" ${_range(start!, end!)}';
      case ChangeType.move:
        return 'move "$title" from ${_range(event!.start, event!.end)} '
            'to ${_range(start!, end!)}';
      case ChangeType.delete:
        return 'delete "$title" ${_range(event!.start, event!.end)}';
    }
  }

  static String _range(DateTime start, DateTime end) =>
      '${formatShortDate(start)} ${formatTime(start)}-${formatTime(end)}';

  static ChangeType _readType(dynamic value) {
    for (final type in ChangeType.values) {
      if (type.name == value) return type;
    }
    throw const FormatException('Unknown type of change');
  }

  static (DateTime, DateTime) _readTimes(
    Map<String, dynamic> json,
    String startKey,
    String endKey,
  ) {
    final start = _readDate(json[startKey]);
    final end = _readDate(json[endKey]);
    if (start == null || end == null || !end.isAfter(start)) {
      throw const FormatException('The change has no valid time');
    }
    return (start, end);
  }

  static DateTime? _readDate(dynamic value) {
    if (value is! String) return null;
    return DateTime.tryParse(value)?.toLocal();
  }
}

// Makes the changes in the list of events. A change is skipped if its event
// is not in the list anymore, e.g. when it was deleted in the calendar after
// the assistant answered.
void applyChanges(List<CalendarChange> changes, List<CalendarEvent> events) {
  for (final change in changes) {
    switch (change.type) {
      case ChangeType.add:
        events.add(CalendarEvent(
          title: change.title,
          start: change.start!,
          end: change.end!,
        ));
      case ChangeType.move:
        final old = change.event!;
        final index = events.indexOf(old);
        if (index == -1) continue;
        events[index] = CalendarEvent(
          title: old.title,
          start: change.start!,
          end: change.end!,
          fixed: old.fixed,
          label: old.label,
          priority: old.priority,
          windowStart: old.windowStart,
          windowEnd: old.windowEnd,
        );
      case ChangeType.delete:
        events.remove(change.event);
    }
  }
}

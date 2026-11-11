import 'task_draft.dart';

// A block in the calendar. Fixed events can't be moved by the rescheduler,
// flexible ones can.
class CalendarEvent {
  final String id;
  final String? taskId;
  final String title;
  final String description;
  final String? location;
  final DateTime start;
  final DateTime end;
  final bool fixed;
  final String? label;
  final Priority priority;
  // the window a flexible event has to stay in (earliest start and deadline)
  final DateTime? windowStart;
  final DateTime? windowEnd;

  CalendarEvent({
    String? id,
    this.taskId,
    required this.title,
    this.description = '',
    this.location,
    required this.start,
    required this.end,
    this.fixed = false,
    this.label,
    this.priority = Priority.normal,
    this.windowStart,
    this.windowEnd,
  }) : id = id ?? newModelId('event');

  bool get isMovable => !fixed;

  Map<String, dynamic> toJson() => {
        'id': id,
        'task_id': taskId,
        'title': title,
        'description': description,
        'location': location,
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
        'label': label,
        'priority': priority.name,
        'fixed': fixed,
        'window_start': windowStart?.toIso8601String(),
        'window_end': windowEnd?.toIso8601String(),
      };

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    final title = json['title'];
    final start = _readDate(json['start']);
    final end = _readDate(json['end']);
    if (title is! String || start == null || end == null) {
      throw const FormatException('Invalid calendar event');
    }
    return CalendarEvent(
      id: json['id'] is String ? json['id'] : null,
      taskId: json['task_id'] is String ? json['task_id'] : null,
      title: title,
      description: json['description'] is String ? json['description'] : '',
      location: json['location'] is String ? json['location'] : null,
      start: start,
      end: end,
      label: json['label'] is String ? json['label'] : null,
      priority: _readPriority(json['priority']),
      fixed: json['fixed'] == true,
      windowStart: _readDate(json['window_start']),
      windowEnd: _readDate(json['window_end']),
    );
  }

  static DateTime? _readDate(dynamic value) =>
      value is String ? DateTime.tryParse(value)?.toLocal() : null;

  static Priority _readPriority(dynamic value) => Priority.values.firstWhere(
        (priority) => priority.name == value,
        orElse: () => Priority.normal,
      );
}

import 'task_draft.dart';

// A task in the task list. done can change, the rest is set when it is made.
class Task {
  final String id;
  final String title;
  final String description;
  final String? location;
  final String? label;
  final bool fixed;
  final int minutes;
  final DateTime? deadline;
  final DateTime? earliestStart;
  final Duration? splitInto;
  final Priority priority;
  bool done;

  Task({
    String? id,
    required this.title,
    this.description = '',
    this.location,
    this.label,
    this.fixed = false,
    this.minutes = 60,
    this.deadline,
    this.earliestStart,
    this.splitInto,
    this.priority = Priority.normal,
    this.done = false,
  }) : id = id ?? newModelId('task');

  bool get isMovable => !fixed;

  // made from what the user filled in on the add form
  factory Task.fromDraft(TaskDraft draft) {
    return Task(
      id: draft.id,
      title: draft.title,
      description: draft.description,
      location: draft.location,
      label: draft.label,
      fixed: draft.fixed,
      // one hour if no length was given
      minutes: draft.length?.inMinutes ?? 60,
      deadline: draft.deadline,
      earliestStart: draft.earliestStart,
      splitInto: draft.splitInto,
      priority: draft.priority,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'location': location,
        'label': label,
        'fixed': fixed,
        'minutes': minutes,
        'deadline': deadline?.toIso8601String(),
        'earliest_start': earliestStart?.toIso8601String(),
        'split_minutes': splitInto?.inMinutes,
        'priority': priority.name,
        'done': done,
      };

  factory Task.fromJson(Map<String, dynamic> json) {
    final title = json['title'];
    if (title is! String || title.trim().isEmpty) {
      throw const FormatException('The task has no title');
    }
    return Task(
      id: json['id'] is String ? json['id'] : null,
      title: title,
      description: json['description'] is String ? json['description'] : '',
      location: json['location'] is String ? json['location'] : null,
      label: json['label'] is String ? json['label'] : null,
      fixed: json['fixed'] == true,
      minutes: json['minutes'] is num ? (json['minutes'] as num).round() : 60,
      deadline: _readDate(json['deadline']),
      earliestStart: _readDate(json['earliest_start']),
      splitInto: _readDuration(json['split_minutes']),
      priority: _readPriority(json['priority']),
      done: json['done'] == true,
    );
  }

  static DateTime? _readDate(dynamic value) =>
      value is String ? DateTime.tryParse(value)?.toLocal() : null;

  static Duration? _readDuration(dynamic value) =>
      value is num && value > 0 ? Duration(minutes: value.round()) : null;

  static Priority _readPriority(dynamic value) => Priority.values.firstWhere(
        (priority) => priority.name == value,
        orElse: () => Priority.normal,
      );
}

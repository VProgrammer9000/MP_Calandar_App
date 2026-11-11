import 'task_label.dart';

enum Priority { high, normal, low }

int _nextId = 0;

String newModelId(String prefix) {
  _nextId++;
  return '$prefix-${DateTime.now().microsecondsSinceEpoch}-$_nextId';
}

// A task before it is placed in the calendar, filled in by the form or read
// from the text prompt
class TaskDraft {
  final String? id;
  final String title;
  final String description;
  final String? location;
  final DateTime? earliestStart;
  final DateTime? deadline;
  final Duration? length;
  // split the task into blocks of this length, null means one block
  final Duration? splitInto;
  final String? label;
  final bool fixed;
  final Priority priority;

  const TaskDraft({
    this.id,
    required this.title,
    this.description = '',
    this.location,
    this.earliestStart,
    this.deadline,
    this.length,
    this.splitInto,
    this.label,
    this.fixed = false,
    this.priority = Priority.normal,
  });

  TaskDraft withId(String id) => TaskDraft(
        id: id,
        title: title,
        description: description,
        location: location,
        earliestStart: earliestStart,
        deadline: deadline,
        length: length,
        splitInto: splitInto,
        label: label,
        fixed: fixed,
        priority: priority,
      );

  // made from the JSON the LLM answers with. It can give back anything, so
  // values that don't make sense are ignored
  factory TaskDraft.fromJson(Map<String, dynamic> json) {
    final title = json['title'];
    if (title is! String || title.trim().isEmpty) {
      throw const FormatException('The task has no title');
    }

    return TaskDraft(
      id: json['id'] is String ? json['id'] : null,
      title: title.trim(),
      description: json['description'] is String ? json['description'] : '',
      location: json['location'] is String ? json['location'] : null,
      earliestStart: _readDate(json['earliest_start']),
      deadline: _readDate(json['deadline']),
      length: _readMinutes(json['length_minutes']),
      splitInto: _readMinutes(json['split_minutes']),
      label: _readLabel(json['label']),
      fixed: json['fixed'] == true,
      priority: _readPriority(json['priority']),
    );
  }

  static DateTime? _readDate(dynamic value) {
    if (value is! String) return null;
    return DateTime.tryParse(value)?.toLocal();
  }

  static Duration? _readMinutes(dynamic value) {
    if (value is! num || value <= 0) return null;
    return Duration(minutes: value.round());
  }

  static String? _readLabel(dynamic value) {
    for (final label in defaultLabels) {
      if (label.name == value) return label.name;
    }
    return null;
  }

  static Priority _readPriority(dynamic value) {
    for (final priority in Priority.values) {
      if (priority.name == value) return priority;
    }
    return Priority.normal;
  }
}

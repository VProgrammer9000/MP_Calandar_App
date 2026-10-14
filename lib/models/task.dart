import 'task_draft.dart';

// A task in the task list. done can change, the rest is set when it is made.
class Task {
  final String title;
  final String description;
  final String? label;
  final bool fixed;
  final int minutes;
  final DateTime? deadline;
  final Priority priority;
  bool done;

  Task({
    required this.title,
    this.description = '',
    this.label,
    this.fixed = false,
    this.minutes = 60,
    this.deadline,
    this.priority = Priority.normal,
    this.done = false,
  });

  // made from what the user filled in on the add form
  factory Task.fromDraft(TaskDraft draft) {
    return Task(
      title: draft.title,
      label: draft.label,
      fixed: draft.fixed,
      // one hour if no length was given
      minutes: draft.length?.inMinutes ?? 60,
      deadline: draft.deadline,
      priority: draft.priority,
    );
  }
}

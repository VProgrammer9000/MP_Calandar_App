enum Priority { high, normal, low }

// A task before it is placed in the calendar, filled in by the form or read
// from the text prompt
class TaskDraft {
  final String title;
  final DateTime? earliestStart;
  final DateTime? deadline;
  final Duration? length;
  // split the task into blocks of this length, null means one block
  final Duration? splitInto;
  final String? label;
  final bool fixed;
  final Priority priority;

  const TaskDraft({
    required this.title,
    this.earliestStart,
    this.deadline,
    this.length,
    this.splitInto,
    this.label,
    this.fixed = false,
    this.priority = Priority.normal,
  });
}

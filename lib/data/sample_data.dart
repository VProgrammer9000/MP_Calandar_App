import '../models/calendar_event.dart';
import '../models/task.dart';
import '../models/task_draft.dart';
import '../utils/dates.dart';

// Sample data so the app has something to show before we save real data.
// TODO: load and save the user's tasks and events

// The task list is kept here so it stays the same when you switch tabs
final List<Task> myTasks = sampleTasks();

List<Task> sampleTasks() {
  final today = dateOnly(DateTime.now());

  return [
    Task(
      title: 'Finish Mobile Programming report',
      description: 'Write the summary and add screenshots',
      label: 'University',
      minutes: 180,
      deadline: addDays(today, 3),
      priority: Priority.high,
    ),
    Task(
      title: 'Read chapter 5 for Algorithms',
      description: 'Dynamic programming',
      label: 'University',
      minutes: 120,
      deadline: addDays(today, 5),
    ),
    Task(
      title: 'Shift at the cafe',
      description: 'Saturday morning',
      label: 'Work',
      fixed: true,
      minutes: 360,
    ),
    Task(
      title: 'Prepare slides for team meeting',
      label: 'Work',
      minutes: 90,
      deadline: addDays(today, 1),
      priority: Priority.high,
    ),
    Task(
      title: 'Gym 3x this week',
      description: 'Legs, push, pull',
      label: 'Health',
      minutes: 180,
      done: true,
    ),
    Task(
      title: 'Call the bank',
      description: 'Ask about the new card',
      label: 'Personal',
      minutes: 15,
      priority: Priority.low,
    ),
  ];
}

// Events around this week so every calendar view shows something
List<CalendarEvent> sampleEvents() {
  final today = dateOnly(DateTime.now());

  // day is days from today, start and end are hours (9.5 = 09:30),
  // window is how many days before and after the event it is allowed to move
  CalendarEvent event(String title, int day, double start, double end,
      {bool fixed = false,
      String? label,
      Priority priority = Priority.normal,
      int window = 2}) {
    final date = addDays(today, day);
    return CalendarEvent(
      title: title,
      start: date.add(Duration(minutes: (start * 60).round())),
      end: date.add(Duration(minutes: (end * 60).round())),
      fixed: fixed,
      label: label,
      priority: priority,
      windowStart: fixed ? null : addDays(date, -window),
      windowEnd: fixed ? null : addDays(date, window),
    );
  }

  return [
    event('Study for midterm', -1, 14, 16,
        label: 'University', priority: Priority.high, window: 1),
    event('Mobile Programming lecture', 0, 9, 10.5,
        fixed: true, label: 'University'),
    event('Work on Chrono app', 0, 13, 15, label: 'University'),
    event('Gym', 0, 18, 19, label: 'Health', priority: Priority.low),
    event('Algorithms class', 1, 10, 12, fixed: true, label: 'University'),
    event('Team meeting', 1, 15, 16, fixed: true, label: 'Work'),
    event('Morning run', 2, 8, 9, label: 'Health', priority: Priority.low),
    event('Read chapter 5', 2, 16, 18, label: 'University', window: 3),
    event('Dinner with friends', 3, 19, 21, fixed: true, label: 'Personal'),
    event('Grocery shopping', 5, 11, 12, label: 'Personal', window: 1),
    event('Shift at the cafe', 6, 8, 14, fixed: true, label: 'Work'),
    event('Project deadline', 9, 10, 11,
        fixed: true, label: 'University', priority: Priority.high),
    event('Dentist', 14, 15, 15.5, fixed: true, label: 'Health'),
  ];
}

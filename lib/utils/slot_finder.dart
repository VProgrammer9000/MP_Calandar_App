import '../models/calendar_event.dart';
import '../models/task_draft.dart';
import 'dates.dart';

// Blocks are only placed between these hours
const dayStartHour = 8;
const dayEndHour = 22;
// How far ahead we look if the task has no deadline
const searchDays = 7;
// A long flexible task without a block length is split into blocks of this
const defaultBlockMinutes = 120;

// The LLM only reads the task. Finding the free time is done here, so the
// slots can never overlap with something in the calendar by mistake.
// If there is not enough free time it gives back fewer blocks than needed.
List<CalendarEvent> findSlots(
  TaskDraft task,
  List<CalendarEvent> events,
  DateTime now,
) {
  final totalMinutes = task.length?.inMinutes ?? 60;

  // A fixed task with a time stays at that time
  if (task.fixed && task.earliestStart != null) {
    final start = task.earliestStart!;
    return [_makeBlock(task, start, totalMinutes)];
  }

  final blockMinutes =
      task.splitInto?.inMinutes ?? _defaultBlockLength(totalMinutes);
  final blocks = <int>[];
  var minutesLeft = totalMinutes;
  while (minutesLeft > 0) {
    final minutes = minutesLeft < blockMinutes ? minutesLeft : blockMinutes;
    blocks.add(minutes);
    minutesLeft -= minutes;
  }

  var searchStart = _nextQuarter(now);
  if (task.earliestStart != null && task.earliestStart!.isAfter(searchStart)) {
    searchStart = task.earliestStart!;
  }
  final searchEnd = task.deadline ?? addDays(dateOnly(searchStart), searchDays);

  final slots = <CalendarEvent>[];
  final usedDays = <DateTime>{};
  final busy = List<CalendarEvent>.of(events);

  // First try to spread the blocks out with one per day. If that is not enough
  // to fit them all, go through the days again and allow more on one day.
  for (final onePerDay in [true, false]) {
    var day = dateOnly(searchStart);
    while (day.isBefore(searchEnd) && slots.length < blocks.length) {
      if (!onePerDay || !usedDays.contains(day)) {
        final minutes = blocks[slots.length];
        final start = _findFreeTime(day, minutes, busy, searchStart, searchEnd);
        if (start != null) {
          final slot = _makeBlock(task, start, minutes);
          slots.add(slot);
          busy.add(slot);
          usedDays.add(day);
          // stay on this day if we are allowed to put more blocks here
          if (!onePerDay) continue;
        }
      }
      day = addDays(day, 1);
    }
  }

  slots.sort((a, b) => a.start.compareTo(b.start));
  return slots;
}

int _defaultBlockLength(int totalMinutes) {
  return totalMinutes > defaultBlockMinutes
      ? defaultBlockMinutes
      : totalMinutes;
}

// The first time on this day with room for the block, null if there is none
DateTime? _findFreeTime(
  DateTime day,
  int minutes,
  List<CalendarEvent> busy,
  DateTime searchStart,
  DateTime searchEnd,
) {
  final length = Duration(minutes: minutes);
  final dayStart = DateTime(day.year, day.month, day.day, dayStartHour);
  var dayEnd = DateTime(day.year, day.month, day.day, dayEndHour);
  if (searchEnd.isBefore(dayEnd)) dayEnd = searchEnd;

  var time = searchStart.isAfter(dayStart) ? searchStart : dayStart;

  final eventsToday = busy
      .where((e) => e.start.isBefore(dayEnd) && e.end.isAfter(dayStart))
      .toList();
  eventsToday.sort((a, b) => a.start.compareTo(b.start));

  for (final event in eventsToday) {
    if (!time.add(length).isAfter(event.start)) break;
    if (event.end.isAfter(time)) time = event.end;
  }

  return time.add(length).isAfter(dayEnd) ? null : time;
}

CalendarEvent _makeBlock(TaskDraft task, DateTime start, int minutes) {
  return CalendarEvent(
    title: task.title,
    start: start,
    end: start.add(Duration(minutes: minutes)),
    fixed: task.fixed,
    label: task.label,
    priority: task.priority,
    windowStart: task.fixed ? null : task.earliestStart,
    windowEnd: task.fixed ? null : task.deadline,
  );
}

// 14:07 -> 14:15, so blocks don't start at strange times
DateTime _nextQuarter(DateTime time) {
  final extra = (15 - time.minute % 15) % 15;
  return DateTime(
    time.year,
    time.month,
    time.day,
    time.hour,
    time.minute + extra,
  );
}

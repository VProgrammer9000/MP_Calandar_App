import 'package:chrono/models/calendar_event.dart';
import 'package:chrono/models/task_draft.dart';
import 'package:chrono/utils/slot_finder.dart';
import 'package:flutter_test/flutter_test.dart';

CalendarEvent busy(DateTime start, DateTime end) {
  return CalendarEvent(title: 'Busy', start: start, end: end, fixed: true);
}

void main() {
  // a Wednesday
  final now = DateTime(2026, 11, 4, 9, 7);

  test('starts at the next quarter when the day is free', () {
    final slots = findSlots(
      const TaskDraft(title: 'Call', length: Duration(minutes: 30)),
      [],
      now,
    );

    expect(slots.length, 1);
    expect(slots.first.title, 'Call');
    expect(slots.first.start, DateTime(2026, 11, 4, 9, 15));
    expect(slots.first.end, DateTime(2026, 11, 4, 9, 45));
  });

  test('one hour if no length is given', () {
    final slots = findSlots(const TaskDraft(title: 'Call'), [], now);
    expect(slots.first.end.difference(slots.first.start).inMinutes, 60);
  });

  test('never overlaps with what is in the calendar', () {
    final events = [
      busy(DateTime(2026, 11, 4, 9), DateTime(2026, 11, 4, 12)),
      busy(DateTime(2026, 11, 4, 12, 30), DateTime(2026, 11, 4, 14)),
    ];

    final slots = findSlots(
      const TaskDraft(title: 'Read', length: Duration(hours: 1)),
      events,
      now,
    );

    // 12:00-12:30 is too short
    expect(slots.first.start, DateTime(2026, 11, 4, 14));
  });

  test('stops at the end of the day and goes to the next', () {
    final late = DateTime(2026, 11, 4, 21, 30);
    final slots = findSlots(
      const TaskDraft(title: 'Read', length: Duration(hours: 1)),
      [],
      late,
    );
    expect(slots.first.start, DateTime(2026, 11, 5, 8));
  });

  test('spreads the blocks over the days', () {
    final slots = findSlots(
      const TaskDraft(
        title: 'Gym',
        length: Duration(hours: 3),
        splitInto: Duration(hours: 1),
      ),
      [],
      now,
    );

    expect(slots.length, 3);
    expect(slots[0].start.day, 4);
    expect(slots[1].start.day, 5);
    expect(slots[2].start.day, 6);
  });

  test('a long task without a block length is split into 2h blocks', () {
    final slots = findSlots(
      const TaskDraft(title: 'Study', length: Duration(hours: 5)),
      [],
      now,
    );

    final lengths = slots.map((s) => s.end.difference(s.start).inMinutes);
    expect(lengths, [120, 120, 60]);
  });

  test('blocks go on the same day when the deadline is close', () {
    final slots = findSlots(
      TaskDraft(
        title: 'Study',
        length: const Duration(hours: 6),
        deadline: DateTime(2026, 11, 5),
      ),
      [],
      now,
    );

    expect(slots.length, 3);
    for (final slot in slots) {
      expect(slot.start.day, 4);
    }
    // and they don't overlap each other
    expect(slots[1].start.isBefore(slots[0].end), false);
    expect(slots[2].start.isBefore(slots[1].end), false);
  });

  test('nothing is placed after the deadline', () {
    final deadline = DateTime(2026, 11, 4, 10);
    final slots = findSlots(
      TaskDraft(
        title: 'Study',
        length: const Duration(hours: 3),
        deadline: deadline,
      ),
      [],
      now,
    );
    expect(slots, isEmpty);
  });

  test('gives back fewer blocks when there is not enough time', () {
    final slots = findSlots(
      TaskDraft(
        title: 'Study',
        length: const Duration(hours: 4),
        deadline: DateTime(2026, 11, 4, 12),
      ),
      [],
      now,
    );

    expect(slots.length, 1);
    expect(slots.first.end.isAfter(DateTime(2026, 11, 4, 12)), false);
  });

  test('a deadline in the past gives no blocks', () {
    final slots = findSlots(
      TaskDraft(title: 'Old', deadline: DateTime(2026, 11, 1)),
      [],
      now,
    );
    expect(slots, isEmpty);
  });

  test('waits for the earliest start', () {
    final slots = findSlots(
      TaskDraft(title: 'Read', earliestStart: DateTime(2026, 11, 7, 10)),
      [],
      now,
    );
    expect(slots.first.start, DateTime(2026, 11, 7, 10));
  });

  test('a fixed task stays at its time even if something is there', () {
    final time = DateTime(2026, 11, 6, 15);
    final slots = findSlots(
      TaskDraft(
        title: 'Dentist',
        fixed: true,
        earliestStart: time,
        length: const Duration(minutes: 30),
      ),
      [busy(time, time.add(const Duration(hours: 1)))],
      now,
    );

    expect(slots.length, 1);
    expect(slots.first.start, time);
    expect(slots.first.fixed, true);
  });

  test('the blocks keep the details from the task', () {
    final deadline = DateTime(2026, 11, 8);
    final slots = findSlots(
      TaskDraft(
        title: 'Read',
        label: 'University',
        priority: Priority.high,
        deadline: deadline,
      ),
      [],
      now,
    );

    expect(slots.first.label, 'University');
    expect(slots.first.priority, Priority.high);
    expect(slots.first.windowEnd, deadline);
  });
}

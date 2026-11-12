import 'package:chrono/models/calendar_change.dart';
import 'package:chrono/models/calendar_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final events = [
    CalendarEvent(
      title: 'Gym',
      start: DateTime(2026, 11, 10, 18),
      end: DateTime(2026, 11, 10, 19),
    ),
    CalendarEvent(
      title: 'Algorithms class',
      start: DateTime(2026, 11, 11, 10),
      end: DateTime(2026, 11, 11, 12),
      fixed: true,
    ),
  ];

  test('reads a new event', () {
    final change = CalendarChange.fromJson({
      'type': 'add',
      'title': ' Study session ',
      'start': '2026-11-12T14:00',
      'end': '2026-11-12T15:00',
    }, events);

    expect(change.type, ChangeType.add);
    expect(change.title, 'Study session');
    expect(change.event, isNull);
    expect(change.start, DateTime(2026, 11, 12, 14));
    expect(change.end, DateTime(2026, 11, 12, 15));
  });

  test('reads a move and finds the event by its number', () {
    final change = CalendarChange.fromJson({
      'type': 'move',
      'event': 0,
      'new_start': '2026-11-10T19:00',
      'new_end': '2026-11-10T20:00',
    }, events);

    expect(change.type, ChangeType.move);
    expect(change.event, same(events[0]));
    expect(change.title, 'Gym');
    expect(change.start, DateTime(2026, 11, 10, 19));
  });

  test('reads a delete, also of a fixed event', () {
    final change =
        CalendarChange.fromJson({'type': 'delete', 'event': 1}, events);

    expect(change.type, ChangeType.delete);
    expect(change.event, same(events[1]));
    expect(change.title, 'Algorithms class');
  });

  test('a move to the same time is not a change', () {
    expect(
      () => CalendarChange.fromJson({
        'type': 'move',
        'event': 0,
        'new_start': '2026-11-10T18:00',
        'new_end': '2026-11-10T19:00',
      }, events),
      throwsFormatException,
    );
  });

  test('does not move fixed events', () {
    expect(
      () => CalendarChange.fromJson({
        'type': 'move',
        'event': 1,
        'new_start': '2026-11-11T13:00',
        'new_end': '2026-11-11T15:00',
      }, events),
      throwsFormatException,
    );
  });

  test('applies an add, a move and a delete', () {
    final list = [...events];
    final changes = [
      CalendarChange.fromJson({
        'type': 'add',
        'title': 'Study session',
        'start': '2026-11-12T14:00',
        'end': '2026-11-12T15:00',
      }, list),
      CalendarChange.fromJson({
        'type': 'move',
        'event': 0,
        'new_start': '2026-11-10T19:00',
        'new_end': '2026-11-10T20:00',
      }, list),
      CalendarChange.fromJson({'type': 'delete', 'event': 1}, list),
    ];

    applyChanges(changes, list);

    expect(list.map((e) => e.title), ['Gym', 'Study session']);
    expect(list[0].start, DateTime(2026, 11, 10, 19));
    expect(list[0].end, DateTime(2026, 11, 10, 20));
    expect(list[1].start, DateTime(2026, 11, 12, 14));
    // the list the test started with is not touched
    expect(events.length, 2);
  });

  test('skips changes to events that are gone', () {
    final list = [...events];
    final move = CalendarChange.fromJson({
      'type': 'move',
      'event': 0,
      'new_start': '2026-11-10T19:00',
      'new_end': '2026-11-10T20:00',
    }, list);
    list.removeAt(0);

    applyChanges([move], list);

    expect(list.map((e) => e.title), ['Algorithms class']);
  });

  test('describes itself in one line', () {
    final add = CalendarChange.fromJson({
      'type': 'add',
      'title': 'Meeting',
      'start': '2026-11-12T13:00',
      'end': '2026-11-12T14:00',
    }, events);
    final move = CalendarChange.fromJson({
      'type': 'move',
      'event': 0,
      'new_start': '2026-11-10T19:00',
      'new_end': '2026-11-10T20:00',
    }, events);
    final delete =
        CalendarChange.fromJson({'type': 'delete', 'event': 1}, events);

    expect(add.describe(), 'add "Meeting" Thu 12 Nov 13:00-14:00');
    expect(move.describe(),
        'move "Gym" from Tue 10 Nov 18:00-19:00 to Tue 10 Nov 19:00-20:00');
    expect(
        delete.describe(), 'delete "Algorithms class" Wed 11 Nov 10:00-12:00');
  });

  test('throws on answers that make no sense', () {
    final bad = <Map<String, dynamic>>[
      {'type': 'rename', 'event': 0},
      {'type': 'delete', 'event': 5},
      {'type': 'delete', 'event': '0'},
      {'type': 'add', 'start': '2026-11-12T14:00', 'end': '2026-11-12T15:00'},
      {'type': 'add', 'title': 'Study', 'start': '2026-11-12T14:00'},
      {
        'type': 'add',
        'title': 'Study',
        'start': '2026-11-12T15:00',
        'end': '2026-11-12T14:00',
      },
    ];

    for (final json in bad) {
      expect(() => CalendarChange.fromJson(json, events), throwsFormatException,
          reason: '$json');
    }
  });
}

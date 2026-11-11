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
      'start': '2026-11-10T19:00',
      'end': '2026-11-10T20:00',
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

  test('does not move fixed events', () {
    expect(
      () => CalendarChange.fromJson({
        'type': 'move',
        'event': 1,
        'start': '2026-11-11T13:00',
        'end': '2026-11-11T15:00',
      }, events),
      throwsFormatException,
    );
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

import 'dart:convert';

import 'package:chrono/models/calendar_change.dart';
import 'package:chrono/models/calendar_event.dart';
import 'package:chrono/services/chat_service.dart';
import 'package:chrono/services/llm_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// A fake API that always answers with this text
MockClient fakeLlm(String answer) {
  return MockClient((request) async {
    final body = jsonEncode({
      'choices': [
        {
          'message': {'content': answer},
        },
      ],
    });
    return http.Response.bytes(utf8.encode(body), 200);
  });
}

void main() {
  final now = DateTime(2026, 11, 9, 9, 15);
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

  test('reads the reply and the changes', () async {
    final answer = jsonEncode({
      'reply': 'I moved the gym and added a study session.',
      'changes': [
        {
          'type': 'add',
          'title': 'Study session',
          'start': '2026-11-12T14:00',
          'end': '2026-11-12T15:00',
        },
        {
          'type': 'move',
          'event': 0,
          'start': '2026-11-10T19:00',
          'end': '2026-11-10T20:00',
        },
      ],
    });

    final plan = await planChanges('Make room for studying', events,
        now: now, client: fakeLlm(answer));

    expect(plan.reply, 'I moved the gym and added a study session.');
    expect(plan.changes.map((c) => c.type), [ChangeType.add, ChangeType.move]);
    expect(plan.changes[1].event, same(events[0]));
    expect(plan.skipped, 0);
  });

  test('sends the date, the numbered events and the message', () async {
    late Map<String, dynamic> sent;
    final client = MockClient((request) async {
      sent = jsonDecode(request.body);
      return http.Response(
        jsonEncode({
          'choices': [
            {
              'message': {'content': '{"reply":"Ok","changes":[]}'},
            },
          ],
        }),
        200,
      );
    });

    await planChanges('Hi', events, now: now, client: client);

    final system = sent['messages'][0]['content'] as String;
    expect(sent['response_format'], {'type': 'json_object'});
    expect(system, contains('Monday 2026-11-09'));
    expect(
        system, contains('0: Gym, Tuesday 2026-11-10 18:00-19:00, flexible'));
    expect(
        system,
        contains(
            '1: Algorithms class, Wednesday 2026-11-11 10:00-12:00, fixed'));
    expect(sent['messages'][1]['content'], 'Hi');
  });

  test('a question gives a reply and no changes', () async {
    final plan = await planChanges('When is the gym?', events,
        now: now, client: fakeLlm('{"reply":"Tuesday at 18:00"}'));

    expect(plan.reply, 'Tuesday at 18:00');
    expect(plan.changes, isEmpty);
  });

  test('leaves out changes that make no sense and counts them', () async {
    final answer = jsonEncode({
      'reply': 'Done',
      'changes': [
        {'type': 'delete', 'event': 0},
        {'type': 'delete', 'event': 9},
        {
          'type': 'move',
          'event': 1,
          'start': '2026-11-11T13:00',
          'end': '2026-11-11T15:00'
        },
        'not a change',
      ],
    });

    final plan = await planChanges('Clean up', events,
        now: now, client: fakeLlm(answer));

    expect(plan.changes.length, 1);
    expect(plan.changes[0].type, ChangeType.delete);
    expect(plan.skipped, 3);
  });

  test('an answer without a reply or not JSON gives an error', () async {
    for (final answer in ['{"changes":[]}', '{"reply":" "}', 'Sure!', '[1]']) {
      expect(
        planChanges('x', events, now: now, client: fakeLlm(answer)),
        throwsA(isA<LlmException>()),
        reason: answer,
      );
    }
  });
}

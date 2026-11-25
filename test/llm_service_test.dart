import 'dart:async';
import 'dart:convert';

import 'package:chrono/models/task_draft.dart';
import 'package:chrono/services/llm_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// A fake API that always answers with this text
MockClient fakeLlm(String answer, {int status = 200}) {
  return MockClient((request) async {
    final body = jsonEncode({
      'choices': [
        {
          'message': {'content': answer},
        },
      ],
    });
    return http.Response.bytes(utf8.encode(body), status);
  });
}

void main() {
  final now = DateTime(2026, 11, 4, 14, 30);

  test('reads a task from the answer', () async {
    final answer = jsonEncode({
      'title': 'Study',
      'length_minutes': 360,
      'split_minutes': 120,
      'earliest_start': null,
      'deadline': '2026-11-06T00:00',
      'label': 'University',
      'fixed': false,
      'priority': 'high',
    });

    final task = await readTaskFromPrompt(
      'Study 6h before Friday',
      now: now,
      client: fakeLlm(answer),
    );

    expect(task.title, 'Study');
    expect(task.length, const Duration(hours: 6));
    expect(task.splitInto, const Duration(hours: 2));
    expect(task.earliestStart, isNull);
    expect(task.deadline, DateTime(2026, 11, 6));
    expect(task.label, 'University');
    expect(task.fixed, false);
    expect(task.priority, Priority.high);
  });

  test('sends the prompt, the date and asks for JSON', () async {
    late Map<String, dynamic> sent;
    final client = MockClient((request) async {
      sent = jsonDecode(request.body);
      return http.Response(
        jsonEncode({
          'choices': [
            {
              'message': {'content': '{"title":"Gym"}'},
            },
          ],
        }),
        200,
      );
    });

    await readTaskFromPrompt('Gym 3x', now: now, client: client);

    expect(sent['model'], llmModel);
    expect(sent['models'], [llmModel, ...llmFallbackModels]);
    expect(sent['response_format'], {'type': 'json_object'});
    expect(sent['messages'][0]['content'], contains('Wednesday 2026-11-04'));
    expect(sent['messages'][1]['content'], 'Gym 3x');
  });

  test('finds the JSON if the model writes text around it', () async {
    final task = await readTaskFromPrompt(
      'Gym',
      now: now,
      client: fakeLlm('Here it is:\n```json\n{"title":"Gym"}\n```'),
    );
    expect(task.title, 'Gym');
  });

  test('an empty answer gives a message for the user', () async {
    expect(
      askLlm([], client: fakeLlm('')),
      throwsA(
        isA<LlmException>().having(
          (e) => e.message,
          'message',
          contains('did not answer'),
        ),
      ),
    );
  });

  test('ignores values that make no sense', () async {
    final answer = jsonEncode({
      'title': 'Gym',
      'length_minutes': 'a lot',
      'split_minutes': -5,
      'deadline': 'next week',
      'label': 'Hobby',
      'fixed': 'yes',
      'priority': 'urgent',
    });

    final task = await readTaskFromPrompt(
      'Gym',
      now: now,
      client: fakeLlm(answer),
    );

    expect(task.length, isNull);
    expect(task.splitInto, isNull);
    expect(task.deadline, isNull);
    expect(task.label, isNull);
    expect(task.fixed, false);
    expect(task.priority, Priority.normal);
  });

  test('an answer without a title or not JSON gives an error', () async {
    for (final answer in ['{"title":""}', '{}', 'Sure, here you go!', '[1]']) {
      expect(
        readTaskFromPrompt('x', now: now, client: fakeLlm(answer)),
        throwsA(isA<LlmException>()),
      );
    }
  });

  test('errors from the API give a message for the user', () async {
    Future<String> errorFor(int status) async {
      try {
        await askLlm([], client: fakeLlm('', status: status));
      } on LlmException catch (e) {
        return e.message;
      }
      return 'no error';
    }

    expect(await errorFor(401), contains('API key'));
    expect(await errorFor(429), contains('used all its free requests'));
    expect(await errorFor(500), contains('500'));
  });

  test('no internet gives a message for the user', () async {
    final client = MockClient((request) async {
      throw http.ClientException('no internet');
    });

    expect(
      askLlm([], client: client),
      throwsA(
        isA<LlmException>().having(
          (e) => e.message,
          'message',
          contains('internet'),
        ),
      ),
    );
  });

  test('a timeout has its own message and does not blame the internet',
      () async {
    final client = MockClient((request) async {
      throw TimeoutException('too slow');
    });

    expect(
      askLlm([], client: client),
      throwsA(
        isA<LlmException>().having(
          (e) => e.message,
          'message',
          contains('took too long'),
        ),
      ),
    );
  });

  test('keeps letters like the danish ones and korean', () async {
    final answer = await askLlm([], client: fakeLlm('Møde 회의'));
    expect(answer, 'Møde 회의');
  });

  group('more than one key', () {
    // the keys that hit their limit are remembered between requests
    setUp(resetUsedUpKeys);

    // Answers with the status set for each key, and keeps which keys were used
    MockClient keyClient(
        Map<String, http.Response> responses, List<String> used) {
      return MockClient((request) async {
        final key = request.headers['Authorization']!.substring(7);
        used.add(key);
        return responses[key] ?? fakeResponse('ok');
      });
    }

    test('tries the next key when one has used up its requests', () async {
      final used = <String>[];
      final client = keyClient({'a': http.Response('{}', 429)}, used);

      expect(await askLlm([], client: client, keys: ['a', 'b']), 'ok');
      expect(used, ['a', 'b']);

      // the used up key is skipped for the rest of the day
      used.clear();
      await askLlm([], client: client, keys: ['a', 'b']);
      expect(used, ['b']);
    });

    test('a key that is not valid is skipped', () async {
      final used = <String>[];
      final client = keyClient({'a': http.Response('{}', 401)}, used);

      expect(await askLlm([], client: client, keys: ['a', 'b']), 'ok');
      expect(used, ['a', 'b']);
    });

    test('a busy model is not fixed by another key', () async {
      final used = <String>[];
      final busy = jsonEncode({
        'error': {
          'code': 429,
          'metadata': {'provider_name': 'Google AI Studio'},
        },
      });
      final client = keyClient({'a': http.Response(busy, 429)}, used);

      await expectLater(
        askLlm([], client: client, keys: ['a', 'b']),
        throwsA(isA<LlmException>()
            .having((e) => e.message, 'message', contains('busy'))),
      );
      expect(used, ['a']);
    });

    test('says so when all keys have used up their requests', () async {
      final used = <String>[];
      final client = keyClient({
        'a': http.Response('{}', 429),
        'b': http.Response('{}', 401),
      }, used);
      final limit = throwsA(isA<LlmException>().having(
          (e) => e.message, 'message', contains('used all its free requests')));

      await expectLater(askLlm([], client: client, keys: ['a', 'b']), limit);
      expect(used, ['a', 'b']);

      // no request is sent until tomorrow
      used.clear();
      await expectLater(askLlm([], client: client, keys: ['a', 'b']), limit);
      expect(used, isEmpty);
    });
  });
}

http.Response fakeResponse(String answer) {
  final body = jsonEncode({
    'choices': [
      {
        'message': {'content': answer},
      },
    ],
  });
  return http.Response.bytes(utf8.encode(body), 200);
}

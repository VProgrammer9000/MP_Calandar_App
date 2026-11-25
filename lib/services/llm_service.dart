import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/task_draft.dart';
import '../models/task_label.dart';
import '../utils/dates.dart';

// The keys come from the .env file when the app is built, see the README.
// Never write a key in the code because the repo is public.
// Each of us has a free account with 50 requests a day, so when one key has
// used them up the next one is tried. Keys that are not set are left out.
final openRouterApiKeys = const [
  String.fromEnvironment('OPENROUTER_API_KEY'),
  String.fromEnvironment('OPENROUTER_API_KEY_2'),
  String.fromEnvironment('OPENROUTER_API_KEY_3'),
  String.fromEnvironment('OPENROUTER_API_KEY_4'),
].where((key) => key.isNotEmpty).toList();

// Keys that hit their daily limit or are not valid, with the day (in UTC,
// when OpenRouter resets the limit) so they are tried again the next day
final _usedUpKeys = <String, DateTime>{};

DateTime _todayUtc() {
  final now = DateTime.now().toUtc();
  return DateTime.utc(now.year, now.month, now.day);
}

bool _isUsedUp(String key) => _usedUpKeys[key] == _todayUtc();

@visibleForTesting
void resetUsedUpKeys() => _usedUpKeys.clear();

const openRouterUrl = 'https://openrouter.ai/api/v1/chat/completions';
// A fast free model that can answer in JSON and doesn't think out loud first.
// openrouter/free picked a random one, and the slow ones often took over a
// minute.
const llmModel = 'google/gemma-4-26b-a4b-it:free';
// OpenRouter tries these in order if the one before is down or busy. The last
// one picks any free model, so it is never worse than before. OpenRouter takes
// at most 3 models in total, with llmModel counted.
const llmFallbackModels = [
  'google/gemma-4-31b-it:free',
  'openrouter/free',
];

// Has a message that is ok to show to the user
class LlmException implements Exception {
  final String message;

  LlmException(this.message);

  @override
  String toString() => message;
}

// A 429 can mean our key used up its requests for today, or that the free
// model is busy for everyone. Only the first one is fixed by another key.
// OpenRouter says it was the model when the error comes from the provider.
bool _isBusyUpstream(http.Response response) {
  try {
    final metadata = jsonDecode(response.body)['error']['metadata'];
    return metadata is Map &&
        (metadata['provider_name'] != null ||
            '${metadata['limit_source']}'.contains('upstream'));
  } catch (e) {
    return false;
  }
}

// Sends the messages to the LLM and gives back the text of its answer.
// A client and keys can be passed in so the tests don't call the real API.
Future<String> askLlm(
  List<Map<String, String>> messages, {
  bool wantJson = false,
  http.Client? client,
  List<String>? keys,
}) async {
  final allKeys = keys ?? openRouterApiKeys;
  if (client == null && allKeys.isEmpty) {
    throw LlmException('The API key is missing. See the README.');
  }
  // the tests run without any keys
  final keysToTry =
      allKeys.isEmpty ? [''] : allKeys.where((key) => !_isUsedUp(key)).toList();
  if (keysToTry.isEmpty) throw _allUsedUp();

  final body = <String, dynamic>{
    'model': llmModel,
    'models': [llmModel, ...llmFallbackModels],
    'messages': messages,
    'temperature': 0.2,
  };
  if (wantJson) {
    body['response_format'] = {'type': 'json_object'};
    // only use a free model that can do this
    body['provider'] = {'require_parameters': true};
  }

  final httpClient = client ?? http.Client();
  try {
    late http.Response response;
    // if no key worked, the user is told about the limit before a bad key
    var hitLimit = false;
    for (final key in keysToTry) {
      // free models can be slow, some answers took over a minute when we tried
      response = await httpClient
          .post(
            Uri.parse(openRouterUrl),
            headers: {
              'Authorization': 'Bearer $key',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 120));

      if (response.statusCode == 429 && _isBusyUpstream(response)) {
        throw LlmException(
            'The free AI models are busy right now. Try again in a minute.');
      }
      if (response.statusCode != 401 && response.statusCode != 429) break;
      // this key can't be used today, try the next one
      if (response.statusCode == 429) hitLimit = true;
      _usedUpKeys[key] = _todayUtc();
    }

    if (response.statusCode == 401 || response.statusCode == 429) {
      throw hitLimit ? _allUsedUp() : LlmException('The API key is not valid.');
    }
    if (response.statusCode != 200) {
      throw LlmException('The assistant had a problem '
          '(error ${response.statusCode}). Try again.');
    }

    // bodyBytes so letters like æ or Korean are read correctly
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    // free models sometimes fail with an empty answer
    final choices = data['choices'];
    final content = choices is List && choices.isNotEmpty
        ? choices[0]['message']['content']
        : null;
    if (content is! String || content.trim().isEmpty) {
      throw LlmException('The assistant did not answer. Try again.');
    }
    return content;
  } on LlmException {
    rethrow;
  } on TimeoutException {
    throw LlmException('The assistant took too long. Try again.');
  } catch (e) {
    throw LlmException('Could not reach the assistant. '
        'Check your internet connection.');
  } finally {
    if (client == null) {
      httpClient.close();
    }
  }
}

LlmException _allUsedUp() =>
    LlmException('The assistant has used all its free requests for today. '
        'Try again tomorrow.');

// Asks the LLM to pick out the task details from what the user wrote
Future<TaskDraft> readTaskFromPrompt(
  String prompt, {
  DateTime? now,
  http.Client? client,
}) async {
  final answer = await askLlm(
    [
      {'role': 'system', 'content': buildReadTaskPrompt(now ?? DateTime.now())},
      {'role': 'user', 'content': prompt},
    ],
    wantJson: true,
    client: client,
  );

  try {
    // some models put text around the JSON even if we ask them not to
    final json =
        answer.substring(answer.indexOf('{'), answer.lastIndexOf('}') + 1);
    return TaskDraft.fromJson(jsonDecode(json));
  } catch (e) {
    throw LlmException(
        'Could not understand that. Try writing it differently.');
  }
}

String buildReadTaskPrompt(DateTime now) {
  final weekday = weekdayNames[now.weekday - 1];
  final today = '${now.year}-${twoDigits(now.month)}-${twoDigits(now.day)}';
  final labels = defaultLabels.map((label) => label.name).join(', ');

  return '''
You read a task that a user wrote for their calendar app.
Today is $weekday $today and the time is ${formatTime(now)}.

Respond only with JSON with exactly these keys:
- "title": short name of the task, as a string
- "description": optional details, as a string or null
- "location": optional location, as a string or null
- "length_minutes": total time for the whole task as a number, null if not said
- "split_minutes": length of one block as a number, null if not said
- "earliest_start": when it can start at the earliest, null if not said
- "deadline": when it must be done, null if not said
- "label": one of $labels, null if none fits
- "fixed": true only if the user gave an exact time, otherwise false
- "priority": "high", "normal" or "low"

Write dates as local time like 2026-01-31T14:00, without a time zone.

Rules:
- "before Friday" means the deadline is the start of that Friday, at 00:00.
- "by Friday" means the deadline is the end of that Friday, at 23:59.
- "this week" means the deadline is the coming Sunday at 23:59.
- Repeated tasks like "Gym 3x" are 3 blocks. Use one hour per block if the time
  is not said, so split_minutes is 60 and length_minutes is 180.
- If the task is at an exact time, put that time in earliest_start.
- Missing optional fields must be null (or an empty string for description).
''';
}

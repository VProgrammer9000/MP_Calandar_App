import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/task_draft.dart';
import '../models/task_label.dart';
import '../utils/dates.dart';

// The key comes from the .env file when the app is started, see the README.
// Never write the key in the code because the repo is public.
const openRouterApiKey = String.fromEnvironment('OPENROUTER_API_KEY');
const openRouterUrl = 'https://openrouter.ai/api/v1/chat/completions';
// This picks one of the free models for us, so we pay nothing and it keeps
// working when a free model gets removed
const llmModel = 'openrouter/free';

// Has a message that is ok to show to the user
class LlmException implements Exception {
  final String message;

  LlmException(this.message);

  @override
  String toString() => message;
}

// Sends the messages to the LLM and gives back the text of its answer.
// A client can be passed in so the tests don't call the real API.
Future<String> askLlm(
  List<Map<String, String>> messages, {
  bool wantJson = false,
  http.Client? client,
}) async {
  if (client == null && openRouterApiKey.isEmpty) {
    throw LlmException('The API key is missing. See the README.');
  }

  final body = <String, dynamic>{
    'model': llmModel,
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
    // free models can be slow, some answers took over 20 seconds when we tried
    final response = await httpClient
        .post(
          Uri.parse(openRouterUrl),
          headers: {
            'Authorization': 'Bearer $openRouterApiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode == 401) {
      throw LlmException('The API key is not valid.');
    }
    if (response.statusCode == 429) {
      throw LlmException('Too many requests. Try again later.');
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

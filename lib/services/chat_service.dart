import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/calendar_change.dart';
import '../models/calendar_event.dart';
import '../utils/dates.dart';
import 'llm_service.dart';

// What the assistant answered in the chat
class ChatPlan {
  final String reply;
  final List<CalendarChange> changes;
  // changes from the LLM that made no sense and were left out
  final int skipped;

  const ChatPlan({
    required this.reply,
    this.changes = const [],
    this.skipped = 0,
  });
}

// Only this many earlier messages are sent, so the request doesn't get huge
const maxHistory = 10;

// Asks the LLM what to change in the calendar for the user's message.
// The events are numbered in the prompt, and the changes point back to them.
// The history is the chat so far, so the LLM knows what "it" or "that" means.
Future<ChatPlan> planChanges(
  String message,
  List<CalendarEvent> events, {
  List<Map<String, String>> history = const [],
  DateTime? now,
  http.Client? client,
}) async {
  final recent = history.length > maxHistory
      ? history.sublist(history.length - maxHistory)
      : history;

  final answer = await askLlm(
    [
      {
        'role': 'system',
        'content': buildPlanPrompt(now ?? DateTime.now(), events),
      },
      ...recent,
      {'role': 'user', 'content': message},
    ],
    wantJson: true,
    client: client,
  );

  final Map<String, dynamic> json;
  try {
    // some models put text around the JSON even if we ask them not to
    final decoded = jsonDecode(
        answer.substring(answer.indexOf('{'), answer.lastIndexOf('}') + 1));
    json = decoded as Map<String, dynamic>;
  } catch (e) {
    throw LlmException('Could not understand the answer. Try again.');
  }

  final reply = json['reply'];
  if (reply is! String || reply.trim().isEmpty) {
    throw LlmException('Could not understand the answer. Try again.');
  }

  final changes = <CalendarChange>[];
  var skipped = 0;
  final list = json['changes'];
  if (list is List) {
    for (final item in list) {
      try {
        changes
            .add(CalendarChange.fromJson(item as Map<String, dynamic>, events));
      } catch (e) {
        skipped++;
        // shows up in the flutter run console, so we can see what went wrong
        debugPrint('Left out a change from the LLM: ${jsonEncode(item)} ($e)');
      }
    }
  }

  return ChatPlan(reply: reply.trim(), changes: changes, skipped: skipped);
}

String buildPlanPrompt(DateTime now, List<CalendarEvent> events) {
  final weekday = weekdayNames[now.weekday - 1];
  final today = _formatDate(now);
  final lines = [
    for (var i = 0; i < events.length; i++) _describeEvent(i, events[i]),
  ].join('\n');

  return '''
You are the assistant in a calendar app. You help the user plan their week.
Today is $weekday $today and the time is ${formatTime(now)}.

These are the events in the calendar, each with its number:
$lines

Respond only with JSON with exactly these keys, in this order:
- "changes": a list of changes to the calendar, empty if nothing should change
- "reply": a short answer to the user, as a string. It must only describe the
  changes in the list, with the same times. Write times in the reply like
  "Thursday 13:00", never like 2026-11-12T13:00

Each change is one of these:
- {"type": "add", "title": "...", "start": "...", "end": "..."}
- {"type": "move", "event": number, "new_start": "...", "new_end": "..."}
- {"type": "delete", "event": number}

Write dates as local time like 2026-01-31T14:00, without a time zone.

Rules:
- Make the changes the user asks for. Don't change anything else, except to
  make room as described below.
- Give a new event a short title, like "Meeting" or "Lunch with Anna". Never
  put the time or length in the title.
- Events must never overlap. If a new or moved event would overlap a flexible
  event, also move that flexible event to a free time, as close to its old
  time as possible. Do this even if the user did not ask for it.
- Never move a fixed event. Only delete an event if the user asks for it.
- If an overlap with a fixed event can't be avoided, make no changes and
  explain why in the reply.
- A move must give the event a new time, never the time it already has.
- If the user only asks a question, answer it and leave "changes" empty.
''';
}

String _describeEvent(int number, CalendarEvent event) {
  final day = weekdayNames[event.start.weekday - 1];
  final kind = event.fixed ? 'fixed' : 'flexible';
  return '$number: ${event.title}, $day ${_formatDate(event.start)} '
      '${formatTime(event.start)}-${formatTime(event.end)}, $kind';
}

String _formatDate(DateTime d) =>
    '${d.year}-${twoDigits(d.month)}-${twoDigits(d.day)}';

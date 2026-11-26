import 'dart:convert';
import 'dart:io';

import 'package:chrono/data/sample_data.dart';
import 'package:chrono/models/app_settings.dart';
import 'package:chrono/models/calendar_event.dart';
import 'package:chrono/screens/chat_screen.dart';
import 'package:chrono/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// A fake API that always answers with this plan
MockClient fakeLlm(Map<String, dynamic> plan) {
  return MockClient((request) async {
    return http.Response(
      jsonEncode({
        'choices': [
          {
            'message': {'content': jsonEncode(plan)},
          },
        ],
      }),
      200,
    );
  });
}

void main() {
  final addPlan = {
    'reply': 'I added the meeting.',
    'changes': [
      {
        'type': 'add',
        'title': 'Important meeting',
        'start': '2026-11-11T13:00',
        'end': '2026-11-11T14:00',
      },
    ],
  };

  late Directory folder;
  late List<CalendarEvent> eventsBefore;

  setUp(() {
    clearChat();
    folder = Directory.systemTemp.createTempSync('chrono_chat_settings');
    storageFolder = folder;
    eventsBefore = List.of(myEvents);
  });

  tearDown(() {
    myEvents
      ..clear()
      ..addAll(eventsBefore);
    mySettings.value = const AppSettings();
    storageFolder = null;
    folder.deleteSync(recursive: true);
  });

  Future<void> askForMeeting(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: ChatScreen(client: fakeLlm(addPlan))),
    );
    await tester.enterText(find.byType(TextField), 'Add a meeting');
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();
  }

  bool meetingInCalendar() =>
      myEvents.any((event) => event.title == 'Important meeting');

  testWidgets('with asking on, the changes wait for a review', (tester) async {
    mySettings.value = const AppSettings(askBeforeChanging: true);
    await askForMeeting(tester);

    expect(find.text('Review changes'), findsOneWidget);
    expect(meetingInCalendar(), false);
  });

  testWidgets('with asking off, the changes go in right away', (tester) async {
    mySettings.value = const AppSettings(askBeforeChanging: false);
    await askForMeeting(tester);

    expect(find.text('Review changes'), findsNothing);
    expect(find.text('The changes are in your calendar.'), findsOneWidget);
    expect(meetingInCalendar(), true);
  });
}

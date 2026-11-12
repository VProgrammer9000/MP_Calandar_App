import 'dart:async';
import 'dart:convert';

import 'package:chrono/data/sample_data.dart';
import 'package:chrono/screens/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// A fake API that answers with this plan, after the test lets it
MockClient fakeLlm(Map<String, dynamic> plan, {Completer<void>? wait}) {
  return MockClient((request) async {
    await wait?.future;
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

Future<void> send(WidgetTester tester, String message) async {
  await tester.enterText(find.byType(TextField), message);
  await tester.tap(find.text('Send'));
  await tester.pump();
}

void main() {
  final movePlan = {
    'reply': 'I moved the gym one hour later.',
    'changes': [
      {'type': 'delete', 'event': 0},
    ],
  };

  testWidgets('shows the reply from the assistant', (tester) async {
    final wait = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(home: ChatScreen(client: fakeLlm(movePlan, wait: wait))),
    );

    await send(tester, 'Move the gym');
    expect(find.text('Move the gym'), findsOneWidget);
    expect(find.text('Thinking...'), findsOneWidget);

    wait.complete();
    await tester.pumpAndSettle();

    expect(find.text('Thinking...'), findsNothing);
    expect(find.text('I moved the gym one hour later.'), findsOneWidget);
    expect(find.text('Review changes'), findsOneWidget);
  });

  testWidgets('the review page lists the changes from the assistant',
      (tester) async {
    final plan = {
      'reply': 'Done',
      'changes': [
        {
          'type': 'add',
          'title': 'Important meeting',
          'start': '2026-11-11T13:00',
          'end': '2026-11-11T14:00',
        },
        {'type': 'delete', 'event': 0},
        {'type': 'delete', 'event': 999},
      ],
    };
    await tester.pumpWidget(
      MaterialApp(home: ChatScreen(client: fakeLlm(plan))),
    );

    await send(tester, 'Make room for a meeting');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Review changes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Changes list'));
    await tester.pumpAndSettle();

    expect(find.text('1 added · 0 adjusted · 1 deleted'), findsOneWidget);
    expect(find.text('1 change left out'.toUpperCase()), findsOneWidget);
    expect(find.text('Important meeting'), findsOneWidget);
    expect(find.text('Wed 11 Nov 13:00–14:00'), findsOneWidget);
    expect(find.text('DELETED'), findsOneWidget);
  });

  testWidgets('the calendar tab shows the day after the changes',
      (tester) async {
    // the sample calendar is built around today, so use its real events
    final work = myEvents.indexWhere((e) => e.title == 'Work on Chrono app');
    final start = myEvents[work].start;
    String at(int hour) =>
        DateTime(start.year, start.month, start.day, hour).toIso8601String();
    // a meeting at 13-14, and the work (13-15) moved down to make room
    final plan = {
      'reply': 'Made room',
      'changes': [
        {
          'type': 'add',
          'title': 'Important meeting',
          'start': at(13),
          'end': at(14),
        },
        {'type': 'move', 'event': work, 'new_start': at(14), 'new_end': at(16)},
      ],
    };
    tester.view.physicalSize = const Size(400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(home: ChatScreen(client: fakeLlm(plan))),
    );
    await send(tester, 'Make room for a meeting');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Review changes'));
    await tester.pumpAndSettle();

    expect(find.text('13:00 Important meeting'), findsOneWidget);
    // the moved event is only shown at its new time
    expect(find.text('14:00 Work on Chrono app (was 13:00)'), findsOneWidget);
    expect(find.textContaining('13:00 Work on Chrono app'), findsNothing);
    // the other events that day are there too
    expect(find.text('09:00 Mobile Programming lecture'), findsOneWidget);
  });

  testWidgets('blocks at the same time are next to each other', (tester) async {
    final work = myEvents.indexWhere((e) => e.title == 'Work on Chrono app');
    final start = myEvents[work].start;
    String at(int hour) =>
        DateTime(start.year, start.month, start.day, hour).toIso8601String();
    // the assistant adds something on top of the work without moving it
    final plan = {
      'reply': 'Added it',
      'changes': [
        {'type': 'add', 'title': 'Call', 'start': at(13), 'end': at(14)},
      ],
    };
    tester.view.physicalSize = const Size(400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(home: ChatScreen(client: fakeLlm(plan))),
    );
    await send(tester, 'Add a call');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Review changes'));
    await tester.pumpAndSettle();

    final call = tester.getRect(find.text('13:00 Call'));
    final workRect = tester.getRect(find.text('13:00 Work on Chrono app'));
    expect(call.overlaps(workRect), isFalse);
  });

  group('accept and reject', () {
    final addPlan = {
      'reply': 'Added it',
      'changes': [
        {
          'type': 'add',
          'title': 'Important meeting',
          'start': '2026-11-11T13:00',
          'end': '2026-11-11T14:00',
        },
      ],
    };

    // opens the review page for the add plan, and puts the calendar back after
    Future<void> openReview(WidgetTester tester) async {
      final before = [...myEvents];
      addTearDown(() => myEvents
        ..clear()
        ..addAll(before));

      await tester.pumpWidget(
        MaterialApp(home: ChatScreen(client: fakeLlm(addPlan))),
      );
      await send(tester, 'Add a meeting');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Review changes'));
      await tester.pumpAndSettle();
    }

    testWidgets('accept puts the changes in the calendar', (tester) async {
      await openReview(tester);
      final count = myEvents.length;

      await tester.tap(find.text('Accept changes'));
      await tester.pumpAndSettle();

      expect(myEvents.length, count + 1);
      expect(myEvents.last.title, 'Important meeting');
      expect(find.text('The changes are in your calendar.'), findsOneWidget);
      // back in the chat, and the plan can't be used again
      expect(find.text('Added it'), findsOneWidget);
      expect(find.text('Review changes'), findsNothing);
    });

    testWidgets('reject changes nothing', (tester) async {
      await openReview(tester);
      final before = [...myEvents];

      await tester.tap(find.text('Reject changes'));
      await tester.pumpAndSettle();

      expect(myEvents, before);
      expect(find.text('Nothing was changed.'), findsOneWidget);
      expect(find.text('Review changes'), findsNothing);
    });
  });

  testWidgets('a follow-up is sent with the chat so far', (tester) async {
    final sent = <List<dynamic>>[];
    var calls = 0;
    final client = MockClient((request) async {
      sent.add(jsonDecode(request.body)['messages']);
      calls++;
      // the second call fails, so its error should not be in the history
      if (calls == 2) return http.Response('', 429);
      final plan = {
        'reply': 'Added the meeting',
        'changes': [
          {
            'type': 'add',
            'title': 'Meeting',
            'start': '2026-11-11T13:00',
            'end': '2026-11-11T14:00',
          },
        ],
      };
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
    await tester.pumpWidget(MaterialApp(home: ChatScreen(client: client)));

    await send(tester, 'Meeting at 13');
    await tester.pumpAndSettle();
    await send(tester, 'Hello?');
    await tester.pumpAndSettle();
    await send(tester, 'Actually it starts at 14');
    await tester.pumpAndSettle();

    // the first message is sent alone, after the prompt
    expect(sent[0].length, 2);
    // the third one has the chat before it, without the error
    final third = sent[2];
    expect(third.map((m) => m['role']),
        ['system', 'user', 'assistant', 'user', 'user']);
    expect(third[1]['content'], 'Meeting at 13');
    expect(third[2]['content'], contains('Added the meeting'));
    expect(third[2]['content'], contains('Not accepted yet'));
    expect(third[2]['content'],
        contains('- add "Meeting" Wed 11 Nov 13:00-14:00'));
    expect(third[3]['content'], 'Hello?');
    expect(third[4]['content'], 'Actually it starts at 14');
  });

  group('refine', () {
    Map<String, dynamic> meetingAt(int hour) => {
          'reply': 'Meeting at $hour',
          'changes': [
            {
              'type': 'add',
              'title': 'Meeting',
              'start': '2026-11-11T$hour:00',
              'end': '2026-11-11T${hour + 1}:00',
            },
          ],
        };

    // answers with the plans in order and keeps what was sent
    MockClient answers(List<Map<String, dynamic>?> plans, List<dynamic> sent) {
      var call = 0;
      return MockClient((request) async {
        sent.add(jsonDecode(request.body)['messages']);
        final plan = plans[call++];
        // null means the request fails
        if (plan == null) return http.Response('', 429);
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

    Future<void> openReview(WidgetTester tester, MockClient client) async {
      final before = [...myEvents];
      addTearDown(() => myEvents
        ..clear()
        ..addAll(before));
      tester.view.physicalSize = const Size(400, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(home: ChatScreen(client: client)));
      await send(tester, 'Meeting at 13');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Review changes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Changes list'));
      await tester.pumpAndSettle();
    }

    testWidgets('a further change replaces the plan and can be accepted',
        (tester) async {
      final sent = [];
      await openReview(
          tester, answers([meetingAt(13), meetingAt(16), meetingAt(9)], sent));
      expect(find.text('Wed 11 Nov 13:00–14:00'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Make it 16 instead');
      await tester.tap(find.text('Preview changes'));
      await tester.pumpAndSettle();

      // the new plan is shown, with its answer
      expect(find.text('Wed 11 Nov 16:00–17:00'), findsOneWidget);
      expect(find.text('Wed 11 Nov 13:00–14:00'), findsNothing);
      expect(find.text('Meeting at 16'), findsOneWidget);
      // the refine was sent with the chat that led to the plan
      final refine = sent[1] as List;
      expect(refine.map((m) => m['role']),
          ['system', 'user', 'assistant', 'user']);
      expect(refine[2]['content'], contains('- add "Meeting"'));
      expect(refine[3]['content'], 'Make it 16 instead');

      // accept puts the refined meeting in the calendar
      await tester.tap(find.text('Accept changes'));
      await tester.pumpAndSettle();
      expect(myEvents.last.start.hour, 16);

      // and the chat remembers that the refined plan was accepted.
      // wait for the snack bar to go, it covers the send button
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await send(tester, 'Thanks');
      await tester.pumpAndSettle();
      final next = sent[2] as List;
      expect(next[2]['content'], contains('accepted'));
      expect(next[2]['content'], contains('16:00-17:00'));
    });

    testWidgets('a failed refine keeps the plan and shows the error',
        (tester) async {
      final sent = [];
      await openReview(tester, answers([meetingAt(13), null], sent));

      await tester.enterText(find.byType(TextField), 'Make it 16 instead');
      await tester.tap(find.text('Preview changes'));
      await tester.pumpAndSettle();

      expect(find.text('Too many requests. Try again later.'), findsOneWidget);
      expect(find.text('Wed 11 Nov 13:00–14:00'), findsOneWidget);
    });
  });

  testWidgets('no review button when nothing changes', (tester) async {
    final plan = {'reply': 'The gym is at 18:00.', 'changes': []};
    await tester.pumpWidget(
      MaterialApp(home: ChatScreen(client: fakeLlm(plan))),
    );

    await send(tester, 'When is the gym?');
    await tester.pumpAndSettle();

    expect(find.text('The gym is at 18:00.'), findsOneWidget);
    expect(find.text('Review changes'), findsNothing);
  });

  testWidgets('an error is shown in the chat', (tester) async {
    final client = MockClient((request) async => http.Response('', 429));
    await tester.pumpWidget(MaterialApp(home: ChatScreen(client: client)));

    await send(tester, 'Hi');
    await tester.pumpAndSettle();

    expect(find.text('Too many requests. Try again later.'), findsOneWidget);
  });
}

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
    // quick reply is picked by default, so no review
    expect(find.text('Review changes'), findsNothing);
  });

  testWidgets('plan changes shows the review button', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: ChatScreen(client: fakeLlm(movePlan))),
    );

    await tester.tap(find.text('Plan changes'));
    await send(tester, 'Move the gym');
    await tester.pumpAndSettle();

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

    await tester.tap(find.text('Plan changes'));
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
        {'type': 'move', 'event': work, 'start': at(14), 'end': at(16)},
      ],
    };
    tester.view.physicalSize = const Size(400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(home: ChatScreen(client: fakeLlm(plan))),
    );
    await tester.tap(find.text('Plan changes'));
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
      await tester.tap(find.text('Plan changes'));
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

  testWidgets('no review button when nothing changes', (tester) async {
    final plan = {'reply': 'The gym is at 18:00.', 'changes': []};
    await tester.pumpWidget(
      MaterialApp(home: ChatScreen(client: fakeLlm(plan))),
    );

    await tester.tap(find.text('Plan changes'));
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

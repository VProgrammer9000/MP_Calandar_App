import 'dart:convert';

import 'package:chrono/data/sample_data.dart';
import 'package:chrono/screens/calendar_screen.dart';
import 'package:chrono/screens/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// A fake API that answers with this plan, and remembers what was asked
MockClient fakeLlm(Map<String, dynamic> plan, List<String> asked) {
  return MockClient((request) async {
    final body = jsonDecode(request.body);
    asked.add(body['messages'].last['content']);
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

Future<void> openReschedule(WidgetTester tester, http.Client client,
    {String title = 'Work on Chrono app'}) async {
  tester.view.physicalSize = const Size(400, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MaterialApp(home: CalendarScreen(client: client)));
  await tester.tap(find.text(title));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Reschedule'));
  await tester.pumpAndSettle();
}

void main() {
  late int work;
  late Map<String, dynamic> movePlan;

  setUp(() {
    myEvents
      ..clear()
      ..addAll(sampleEvents());
    work = myEvents.indexWhere((e) => e.title == 'Work on Chrono app');
    final day = myEvents[work].start;
    movePlan = {
      'reply': 'I moved it to 16:00.',
      'changes': [
        {
          'type': 'move',
          'event': work,
          'new_start': DateTime(day.year, day.month, day.day, 16)
              .toIso8601String(),
          'new_end': DateTime(day.year, day.month, day.day, 18)
              .toIso8601String(),
        },
      ],
    };
  });

  testWidgets('reschedule shows the plan and accept moves the event',
      (tester) async {
    final asked = <String>[];
    await openReschedule(tester, fakeLlm(movePlan, asked));

    // the request names the event and its window
    expect(asked.single, contains('"Work on Chrono app"'));
    expect(asked.single, contains('Keep the same length'));

    expect(find.byType(ChangePreviewScreen), findsOneWidget);
    await tester.tap(find.text('Accept changes'));
    await tester.pumpAndSettle();

    expect(find.byType(ChangePreviewScreen), findsNothing);
    final moved = myEvents.firstWhere((e) => e.title == 'Work on Chrono app');
    expect(moved.start.hour, 16);
    expect(moved.end.hour, 18);
  });

  testWidgets('reject keeps the event where it was', (tester) async {
    await openReschedule(tester, fakeLlm(movePlan, []));

    await tester.tap(find.text('Reject changes'));
    await tester.pumpAndSettle();

    expect(myEvents[work].start.hour, 13);
    expect(find.text('REVIEW'), findsNothing);
  });

  testWidgets('going back keeps the banner so the plan can be reviewed',
      (tester) async {
    await openReschedule(tester, fakeLlm(movePlan, []));

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('A new time for "Work on Chrono app" is ready'),
        findsOneWidget);
    await tester.tap(find.text('REVIEW'));
    await tester.pumpAndSettle();
    expect(find.byType(ChangePreviewScreen), findsOneWidget);
  });

  testWidgets('no changes shows the reply instead', (tester) async {
    final plan = {'reply': 'There is no free time before Friday.'};
    await openReschedule(tester, fakeLlm(plan, []));

    expect(find.byType(ChangePreviewScreen), findsNothing);
    expect(find.text('There is no free time before Friday.'), findsOneWidget);
  });

  testWidgets('an error from the API is shown', (tester) async {
    final client = MockClient((request) async => http.Response('', 429));
    await openReschedule(tester, client);

    expect(find.text('Too many requests. Try again later.'), findsOneWidget);
    expect(find.text('REVIEW'), findsNothing);
  });

  testWidgets('fixed events are not sent to the assistant', (tester) async {
    final asked = <String>[];
    await openReschedule(tester, fakeLlm(movePlan, asked),
        title: 'Mobile Programming lecture');

    expect(asked, isEmpty);
    expect(find.text('Fixed events can\'t be moved'), findsOneWidget);
  });
}

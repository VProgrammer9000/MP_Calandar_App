import 'dart:async';
import 'dart:convert';

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

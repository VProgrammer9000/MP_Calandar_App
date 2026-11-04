import 'dart:convert';

import 'package:chrono/data/sample_data.dart';
import 'package:chrono/models/task_draft.dart';
import 'package:chrono/utils/dates.dart';
import 'package:chrono/widgets/add_by_prompt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

MockClient fakeLlm(Map<String, dynamic> task) {
  return MockClient((request) async {
    return http.Response(
      jsonEncode({
        'choices': [
          {
            'message': {'content': jsonEncode(task)},
          },
        ],
      }),
      200,
    );
  });
}

// Opens the prompt on a second page so we can see what it pops with
Future<List<dynamic>> openPrompt(
    WidgetTester tester, http.Client client) async {
  tester.view.physicalSize = const Size(400, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final results = <dynamic>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            results.add(
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      Scaffold(body: AddByPrompt(client: client)),
                ),
              ),
            );
          },
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return results;
}

void main() {
  setUp(() {
    myEvents.clear();
  });

  testWidgets('reads the prompt, shows slots and adds them to the calendar',
      (tester) async {
    final deadline = addDays(dateOnly(DateTime.now()), 7);
    final results = await openPrompt(
      tester,
      fakeLlm({
        'title': 'Study',
        'length_minutes': 240,
        'split_minutes': 120,
        'deadline': deadline.toIso8601String(),
        'label': 'University',
        'fixed': false,
        'priority': 'normal',
      }),
    );

    await tester.enterText(find.byType(TextFormField), 'Study 4h');
    await tester.tap(find.text('Read it & find slots'));
    await tester.pumpAndSettle();

    expect(find.text('WHAT IT READ'), findsOneWidget);
    expect(find.text('Study'), findsWidgets);
    expect(find.text('University'), findsOneWidget);
    expect(find.text('Flexible'), findsOneWidget);
    expect(find.byType(CheckboxListTile), findsNWidgets(2));
    expect(find.text('Add 2 blocks'), findsOneWidget);

    // take one away
    await tester.tap(find.byType(CheckboxListTile).first);
    await tester.pump();
    expect(find.text('Add 1 block'), findsOneWidget);

    await tester.tap(find.text('Add 1 block'));
    await tester.pumpAndSettle();

    expect(myEvents.length, 1);
    expect(myEvents.first.title, 'Study');
    expect(results.single, isA<TaskDraft>());
    expect(results.single.title, 'Study');
  });

  testWidgets('shows the error and adds nothing when the API fails',
      (tester) async {
    await openPrompt(
      tester,
      MockClient((request) async => http.Response('nope', 429)),
    );

    await tester.enterText(find.byType(TextFormField), 'Study 4h');
    await tester.tap(find.text('Read it & find slots'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Too many requests'), findsOneWidget);
    expect(find.text('WHAT IT READ'), findsNothing);
    expect(find.text('Read it & find slots'), findsOneWidget);
    expect(myEvents, isEmpty);
  });

  testWidgets('tells the user when there is not enough free time',
      (tester) async {
    final yesterday = addDays(dateOnly(DateTime.now()), -1);
    await openPrompt(
      tester,
      fakeLlm({'title': 'Old task', 'deadline': yesterday.toIso8601String()}),
    );

    await tester.enterText(find.byType(TextFormField), 'Old task');
    await tester.tap(find.text('Read it & find slots'));
    await tester.pumpAndSettle();

    expect(find.textContaining('No free time'), findsOneWidget);
    expect(find.byType(CheckboxListTile), findsNothing);
  });

  testWidgets('does nothing with an empty prompt', (tester) async {
    await openPrompt(
      tester,
      MockClient((request) async => throw Exception('should not be called')),
    );

    await tester.tap(find.text('Read it & find slots'));
    await tester.pumpAndSettle();

    expect(find.text('WHAT IT READ'), findsNothing);
    expect(find.textContaining('Could not'), findsNothing);
  });
}

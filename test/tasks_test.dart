import 'package:chrono/data/sample_data.dart';
import 'package:chrono/models/task.dart';
import 'package:chrono/models/task_draft.dart';
import 'package:chrono/screens/tasks_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpTasks(WidgetTester tester) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: TasksScreen()));
}

void main() {
  // start every test with the same sample tasks
  setUp(() {
    myTasks
      ..clear()
      ..addAll(sampleTasks());
  });

  testWidgets('checking a task marks it done and updates the count', (tester) async {
    await pumpTasks(tester);
    expect(find.text('5 OPEN · 12 H TO PLACE'), findsOneWidget);

    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();

    expect(myTasks.first.done, true);
    expect(find.text('4 OPEN · 9 H TO PLACE'), findsOneWidget);
  });

  testWidgets('filters show only matching tasks', (tester) async {
    await pumpTasks(tester);

    await tester.tap(find.widgetWithText(FilterChip, 'Fixed'));
    await tester.pump();
    expect(find.text('Shift at the cafe'), findsOneWidget);
    expect(find.text('Call the bank'), findsNothing);

    await tester.tap(find.widgetWithText(FilterChip, 'Flexible'));
    await tester.pump();
    expect(find.text('Shift at the cafe'), findsNothing);
    expect(find.byType(CheckboxListTile), findsWidgets);

    await tester.ensureVisible(find.widgetWithText(FilterChip, 'Due'));
    await tester.tap(find.widgetWithText(FilterChip, 'Due'));
    await tester.pump();
    // closest deadline first
    final titles = tester
        .widgetList<CheckboxListTile>(find.byType(CheckboxListTile))
        .map((tile) => (tile.title as Text).data)
        .toList();
    expect(titles, [
      'Prepare slides for team meeting',
      'Finish Mobile Programming report',
      'Read chapter 5 for Algorithms',
    ]);
  });

  testWidgets('swipe to delete and undo', (tester) async {
    await pumpTasks(tester);

    await tester.drag(find.text('Read chapter 5 for Algorithms'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Read chapter 5 for Algorithms'), findsNothing);
    expect(myTasks.length, 5);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('Read chapter 5 for Algorithms'), findsOneWidget);
    expect(myTasks[1].title, 'Read chapter 5 for Algorithms');
    expect(myTasks.length, 6);
  });

  test('a task from the form keeps what the user filled in', () {
    final task = Task.fromDraft(TaskDraft(
      title: 'Laundry',
      length: const Duration(minutes: 45),
      label: 'Personal',
      fixed: true,
      priority: Priority.low,
    ));

    expect(task.title, 'Laundry');
    expect(task.minutes, 45);
    expect(task.label, 'Personal');
    expect(task.fixed, true);
    expect(task.done, false);
    expect(Task.fromDraft(const TaskDraft(title: 'x')).minutes, 60);
  });
}

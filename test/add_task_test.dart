import 'package:chrono/screens/add_task_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('add by prompt fills the field from an example', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: AddTaskScreen()));
    expect(find.text('Add to my week'), findsOneWidget);
    expect(find.text('Read it & find slots'), findsOneWidget);

    await tester.tap(find.text('Gym 3x this week'));
    await tester.pump();
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text,
      'Gym 3x this week',
    );
  });

  testWidgets('add by form needs a title', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: AddTaskScreen()));
    await tester.tap(find.text('Form'));
    await tester.pumpAndSettle();
    expect(find.text('earliest start'), findsOneWidget);

    await tester.dragUntilVisible(
      find.text('Add task'),
      find.byType(SingleChildScrollView),
      const Offset(0, -200),
    );
    await tester.tap(find.text('Add task'));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.text('Give it a title'),
      find.byType(SingleChildScrollView),
      const Offset(0, 200),
    );
    expect(find.text('Give it a title'), findsOneWidget);
  });

  testWidgets('add event form needs a title too', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: AddTaskScreen(type: AddType.event)),
    );
    await tester.dragUntilVisible(
      find.text('Add event'),
      find.byType(SingleChildScrollView),
      const Offset(0, -200),
    );
    await tester.tap(find.text('Add event'));
    await tester.pumpAndSettle();

    // the page stays open with the error
    expect(find.byType(AddTaskScreen), findsOneWidget);
    await tester.dragUntilVisible(
      find.text('Give it a title'),
      find.byType(SingleChildScrollView),
      const Offset(0, 200),
    );
    expect(find.text('Give it a title'), findsOneWidget);
  });
}

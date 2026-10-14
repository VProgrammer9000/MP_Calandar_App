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
}

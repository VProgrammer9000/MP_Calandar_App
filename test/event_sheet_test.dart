import 'package:chrono/screens/calendar_screen.dart';
import 'package:chrono/widgets/event_detail_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> openLecture(WidgetTester tester) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(const MaterialApp(home: CalendarScreen()));
  await tester.tap(find.text('Mobile Programming lecture'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('tapping an event opens the detail sheet', (tester) async {
    await openLecture(tester);

    expect(find.byType(EventDetailSheet), findsOneWidget);
    expect(find.text('FIXED · UNIVERSITY'), findsOneWidget);
    for (final row in ['when', 'length', 'window', 'priority', 'label']) {
      expect(find.text(row), findsOneWidget);
    }
    expect(find.text('Fixed time'), findsOneWidget);
    expect(find.text('1h 30m'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Reschedule'), findsOneWidget);
    expect(find.text('Delete task'), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(EventDetailSheet), findsNothing);
  });

  testWidgets('save keeps the changes', (tester) async {
    await openLecture(tester);

    await tester.tap(find.text('Normal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('High').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.byType(EventDetailSheet), findsNothing);

    // open it again, the new priority is still there
    await tester.tap(find.text('Mobile Programming lecture'));
    await tester.pumpAndSettle();
    expect(find.text('High'), findsOneWidget);
  });

  testWidgets('delete removes the event and undo brings it back', (tester) async {
    await openLecture(tester);

    await tester.tap(find.text('Delete task'));
    await tester.pumpAndSettle();
    expect(find.text('Mobile Programming lecture'), findsNothing);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('Mobile Programming lecture'), findsOneWidget);
  });
}

import 'package:chrono/main.dart';
import 'package:chrono/screens/calendar_screen.dart';
import 'package:chrono/widgets/day_timeline.dart';
import 'package:chrono/widgets/month_grid.dart';
import 'package:chrono/widgets/week_timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('starts on login and goes to the tabs', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ChronoApp());
    expect(find.text('Welcome back'), findsOneWidget);

    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(SegmentedButton<CalendarView>), findsOneWidget);
    expect(find.byType(DayTimeline), findsOneWidget);

    await tester.tap(find.text('Week'));
    await tester.pumpAndSettle();
    expect(find.byType(WeekTimeline), findsOneWidget);
    expect(find.textContaining('WEEK '), findsOneWidget);

    await tester.tap(find.text('Month'));
    await tester.pumpAndSettle();
    expect(find.byType(MonthGrid), findsOneWidget);

    await tester.tap(find.text('Tasks'));
    await tester.pumpAndSettle();
    expect(find.text('Tasks come here'), findsOneWidget);
  });
}

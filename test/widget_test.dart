import 'package:chrono/main.dart';
import 'package:chrono/screens/calendar_screen.dart';
import 'package:chrono/widgets/day_timeline.dart';
import 'package:chrono/widgets/month_grid.dart';
import 'package:chrono/widgets/week_timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('goes from onboarding to login to the tabs', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ChronoApp());
    expect(find.text('Tell it what you need to do.'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);

    // empty fields should not log in
    final loginButton = find.widgetWithText(FilledButton, 'Log in').last;
    await tester.ensureVisible(loginButton);
    await tester.tap(loginButton);
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.enterText(find.byType(TextFormField).at(0), 'test@test.com');
    await tester.enterText(find.byType(TextFormField).at(1), '1234');
    await tester.tap(loginButton);
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
    expect(find.text('All'), findsOneWidget);
    expect(find.byType(CheckboxListTile), findsWidgets);
  });

  testWidgets('skip login goes straight to the tabs', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ChronoApp());
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    final skipButton = find.text('Skip login');
    await tester.ensureVisible(skipButton);
    await tester.tap(skipButton);
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}

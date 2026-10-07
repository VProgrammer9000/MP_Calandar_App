import 'package:chrono/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('starts on login and goes to the tabs', (tester) async {
    await tester.pumpWidget(const ChronoApp());
    expect(find.text('Welcome back'), findsOneWidget);

    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Calendar comes here'), findsOneWidget);

    await tester.tap(find.text('Tasks'));
    await tester.pumpAndSettle();
    expect(find.text('All'), findsOneWidget);
    expect(find.byType(CheckboxListTile), findsWidgets);
  });
}

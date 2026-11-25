import 'package:chrono/widgets/sliding_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('old text slides out while the new one slides in',
      (tester) async {
    Widget header(String text) => MaterialApp(
          home: Scaffold(
            body: SlidingText(text, style: const TextStyle(fontSize: 26)),
          ),
        );

    await tester.pumpWidget(header('Monday 16'));
    await tester.pumpWidget(header('Tuesday 17'));
    await tester.pump(const Duration(milliseconds: 100));

    // halfway, both are on screen
    expect(find.text('Monday 16'), findsOneWidget);
    expect(find.text('Tuesday 17'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('Monday 16'), findsNothing);
    expect(find.text('Tuesday 17'), findsOneWidget);
  });
}

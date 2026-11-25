import 'package:chrono/widgets/fade_slide_in.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget row({required bool animate}) => MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              FadeSlideIn(
                animate: animate,
                child: const SizedBox(height: 60, child: Text('New task')),
              ),
            ],
          ),
        ),
      );

  double height(WidgetTester tester) =>
      tester.getSize(find.byType(FadeSlideIn)).height;

  testWidgets('a new row opens up from zero height', (tester) async {
    await tester.pumpWidget(row(animate: true));
    expect(height(tester), 0);

    await tester.pump(const Duration(milliseconds: 150));
    expect(height(tester), greaterThan(0));
    expect(height(tester), lessThan(60));

    await tester.pumpAndSettle();
    expect(height(tester), 60);
  });

  testWidgets('an old row is shown right away', (tester) async {
    await tester.pumpWidget(row(animate: false));
    expect(height(tester), 60);
  });
}

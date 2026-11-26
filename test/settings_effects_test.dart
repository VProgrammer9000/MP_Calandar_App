import 'package:chrono/models/app_settings.dart';
import 'package:chrono/models/task_draft.dart';
import 'package:chrono/services/chat_service.dart';
import 'package:chrono/utils/slot_finder.dart';
import 'package:flutter_test/flutter_test.dart';

// Checks that the settings really change how the planner and the assistant
// work, not only what the settings page shows
void main() {
  // a Wednesday
  final now = DateTime(2026, 11, 4, 7, 0);

  group('working hours', () {
    test('tasks are not planned before the day starts', () {
      final slots = findSlots(
        const TaskDraft(title: 'Read', length: Duration(hours: 1)),
        [],
        now,
        dayStartMinutes: 10 * 60 + 30,
        dayEndMinutes: 17 * 60,
      );
      expect(slots.first.start, DateTime(2026, 11, 4, 10, 30));
    });

    test('a task that does not fit before the day ends goes to tomorrow', () {
      final evening = DateTime(2026, 11, 4, 16, 30);
      final slots = findSlots(
        const TaskDraft(title: 'Read', length: Duration(hours: 1)),
        [],
        evening,
        dayStartMinutes: 9 * 60,
        dayEndMinutes: 17 * 60,
      );
      expect(slots.first.start, DateTime(2026, 11, 5, 9, 0));
    });

    test('the assistant is told the working hours', () {
      final prompt = buildPlanPrompt(
        now,
        [],
        settings: const AppSettings(
          workStartMinutes: 9 * 60,
          workEndMinutes: 17 * 60 + 30,
        ),
      );
      expect(prompt, contains('working hours are 09:00 to 17:30'));
    });
  });
}

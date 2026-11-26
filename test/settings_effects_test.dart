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

  test('a task without a length gets the default length', () {
    final slots = findSlots(
      const TaskDraft(title: 'Call mom'),
      [],
      now,
      defaultTaskMinutes: 90,
    );
    expect(slots.first.end.difference(slots.first.start).inMinutes, 90);
  });

  test('a length the user gave wins over the default', () {
    final slots = findSlots(
      const TaskDraft(title: 'Call mom', length: Duration(minutes: 30)),
      [],
      now,
      defaultTaskMinutes: 90,
    );
    expect(slots.first.end.difference(slots.first.start).inMinutes, 30);
  });

  group('assistant', () {
    test('uses the name and answers in the picked language', () {
      final prompt = buildPlanPrompt(
        now,
        [],
        settings: const AppSettings(
          name: 'Viktor',
          language: AssistantLanguage.korean,
        ),
      );
      expect(prompt, contains('The user is called Viktor'));
      expect(prompt, contains('Write "reply" in Korean'));
    });

    test('without a name it is left out, and English is the default', () {
      final prompt = buildPlanPrompt(now, []);
      expect(prompt, isNot(contains('The user is called')));
      expect(prompt, contains('Write "reply" in English'));
    });
  });
}

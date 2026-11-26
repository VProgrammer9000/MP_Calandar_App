import 'package:flutter/foundation.dart';

enum AssistantLanguage { english, korean }

// What the user picked on the settings page. The AI screens read these, so
// changing a setting changes how the assistant plans and answers.
class AppSettings {
  final String name;
  // working hours as minutes after midnight, new tasks are only put in here
  final int workStartMinutes;
  final int workEndMinutes;
  // used when the user doesn't say how long a task takes
  final int defaultTaskMinutes;
  // show the changes from the chat first, or put them in the calendar
  // right away
  final bool askBeforeChanging;
  final AssistantLanguage language;

  // the same as how the app worked before there were settings
  const AppSettings({
    this.name = '',
    this.workStartMinutes = 8 * 60,
    this.workEndMinutes = 22 * 60,
    this.defaultTaskMinutes = 60,
    this.askBeforeChanging = true,
    this.language = AssistantLanguage.english,
  });

  AppSettings copyWith({
    String? name,
    int? workStartMinutes,
    int? workEndMinutes,
    int? defaultTaskMinutes,
    bool? askBeforeChanging,
    AssistantLanguage? language,
  }) {
    return AppSettings(
      name: name ?? this.name,
      workStartMinutes: workStartMinutes ?? this.workStartMinutes,
      workEndMinutes: workEndMinutes ?? this.workEndMinutes,
      defaultTaskMinutes: defaultTaskMinutes ?? this.defaultTaskMinutes,
      askBeforeChanging: askBeforeChanging ?? this.askBeforeChanging,
      language: language ?? this.language,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'work_start_minutes': workStartMinutes,
        'work_end_minutes': workEndMinutes,
        'default_task_minutes': defaultTaskMinutes,
        'ask_before_changing': askBeforeChanging,
        'language': language.name,
      };

  // a value that is missing or broken keeps its default
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    const defaults = AppSettings();
    int readMinutes(String key, int fallback) {
      final value = json[key];
      return value is int && value >= 0 && value <= 24 * 60 ? value : fallback;
    }

    final start = readMinutes('work_start_minutes', defaults.workStartMinutes);
    final end = readMinutes('work_end_minutes', defaults.workEndMinutes);
    final validHours = start < end;

    return AppSettings(
      name: json['name'] is String ? json['name'] : defaults.name,
      workStartMinutes: validHours ? start : defaults.workStartMinutes,
      workEndMinutes: validHours ? end : defaults.workEndMinutes,
      defaultTaskMinutes: json['default_task_minutes'] is int &&
              json['default_task_minutes'] > 0
          ? json['default_task_minutes']
          : defaults.defaultTaskMinutes,
      askBeforeChanging: json['ask_before_changing'] is bool
          ? json['ask_before_changing']
          : defaults.askBeforeChanging,
      language: AssistantLanguage.values.firstWhere(
        (language) => language.name == json['language'],
        orElse: () => defaults.language,
      ),
    );
  }
}

// The settings everywhere in the app. Screens listen to it, so they update
// as soon as a setting is changed.
final mySettings = ValueNotifier<AppSettings>(const AppSettings());

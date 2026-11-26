import 'dart:io';

import 'package:chrono/models/app_settings.dart';
import 'package:chrono/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory folder;

  setUp(() {
    folder = Directory.systemTemp.createTempSync('chrono_settings_test');
    storageFolder = folder;
    mySettings.value = const AppSettings();
  });

  tearDown(() {
    storageFolder = null;
    mySettings.value = const AppSettings();
    folder.deleteSync(recursive: true);
  });

  test('settings are saved and read back', () async {
    const changed = AppSettings(
      name: 'Viktor',
      workStartMinutes: 9 * 60,
      workEndMinutes: 17 * 60 + 30,
      defaultTaskMinutes: 90,
      askBeforeChanging: false,
      language: AssistantLanguage.korean,
    );
    await saveSettings(changed);

    mySettings.value = const AppSettings();
    await loadSettings();

    final loaded = mySettings.value;
    expect(loaded.name, 'Viktor');
    expect(loaded.workStartMinutes, 9 * 60);
    expect(loaded.workEndMinutes, 17 * 60 + 30);
    expect(loaded.defaultTaskMinutes, 90);
    expect(loaded.askBeforeChanging, false);
    expect(loaded.language, AssistantLanguage.korean);
  });

  test('without a file the defaults stay', () async {
    await loadSettings();
    expect(mySettings.value.workStartMinutes, 8 * 60);
    expect(mySettings.value.askBeforeChanging, true);
  });

  test('broken values fall back to the defaults', () {
    final settings = AppSettings.fromJson({
      'name': 42,
      'work_start_minutes': 20 * 60,
      'work_end_minutes': 9 * 60,
      'default_task_minutes': -5,
      'language': 'klingon',
    });
    expect(settings.name, '');
    // the end before the start makes no sense, so both are reset
    expect(settings.workStartMinutes, 8 * 60);
    expect(settings.workEndMinutes, 22 * 60);
    expect(settings.defaultTaskMinutes, 60);
    expect(settings.language, AssistantLanguage.english);
  });
}

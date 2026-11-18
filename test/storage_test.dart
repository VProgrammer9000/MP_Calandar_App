import 'dart:io';

import 'package:chrono/data/sample_data.dart';
import 'package:chrono/models/calendar_event.dart';
import 'package:chrono/models/task.dart';
import 'package:chrono/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory folder;

  setUp(() {
    folder = Directory.systemTemp.createTempSync('chrono_test');
    storageFolder = folder;
    myTasks
      ..clear()
      ..addAll(sampleTasks());
    myEvents
      ..clear()
      ..addAll(sampleEvents());
  });

  tearDown(() {
    storageFolder = null;
    folder.deleteSync(recursive: true);
  });

  test('sample data stays when nothing is saved yet', () async {
    await loadData();
    expect(myTasks.length, sampleTasks().length);
    expect(myEvents.length, sampleEvents().length);
  });

  test('saved tasks and events come back after loading', () async {
    myTasks.clear();
    myTasks.add(Task(title: 'Buy milk', minutes: 15, label: 'Personal'));
    myTasks.first.done = true;
    myEvents.clear();
    myEvents.add(CalendarEvent(
      title: 'Dentist',
      start: DateTime(2026, 11, 20, 10),
      end: DateTime(2026, 11, 20, 11),
      fixed: true,
    ));
    await saveData();

    // like a restart: the lists start as sample data again
    myTasks
      ..clear()
      ..addAll(sampleTasks());
    myEvents
      ..clear()
      ..addAll(sampleEvents());
    await loadData();

    expect(myTasks.length, 1);
    expect(myTasks.first.title, 'Buy milk');
    expect(myTasks.first.done, true);
    expect(myTasks.first.minutes, 15);
    expect(myEvents.length, 1);
    expect(myEvents.first.title, 'Dentist');
    expect(myEvents.first.start, DateTime(2026, 11, 20, 10));
    expect(myEvents.first.fixed, true);
  });

  test('an empty saved list stays empty', () async {
    myTasks.clear();
    await saveData();
    myTasks.addAll(sampleTasks());

    await loadData();
    expect(myTasks, isEmpty);
  });

  test('a broken file does not crash and keeps the sample data', () async {
    File('${folder.path}/tasks.json').writeAsStringSync('not json');
    await loadData();
    expect(myTasks.length, sampleTasks().length);
  });
}

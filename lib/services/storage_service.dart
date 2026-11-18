import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../data/sample_data.dart';
import '../models/calendar_event.dart';
import '../models/task.dart';

// Saves the tasks and events as json files in the app documents folder,
// so they are still there when the app is opened again.

// only set by the tests, so they can use a temp folder
Directory? storageFolder;

Future<Directory> _getFolder() async {
  return storageFolder ?? await getApplicationDocumentsDirectory();
}

// Reads the saved tasks and events into myTasks and myEvents.
// If nothing is saved yet the sample data stays.
Future<void> loadData() async {
  try {
    final folder = await _getFolder();

    final tasksFile = File('${folder.path}/tasks.json');
    if (await tasksFile.exists()) {
      final list = jsonDecode(await tasksFile.readAsString()) as List;
      final tasks = list.map((item) => Task.fromJson(item)).toList();
      myTasks
        ..clear()
        ..addAll(tasks);
    }

    final eventsFile = File('${folder.path}/events.json');
    if (await eventsFile.exists()) {
      final list = jsonDecode(await eventsFile.readAsString()) as List;
      final events = list.map((item) => CalendarEvent.fromJson(item)).toList();
      myEvents
        ..clear()
        ..addAll(events);
    }
  } catch (e) {
    // a broken file should not stop the app from starting
    debugPrint('Could not load the saved data: $e');
  }
}

// Writes myTasks and myEvents to the files. Called after every change.
Future<void> saveData() async {
  try {
    final folder = await _getFolder();
    final tasks = myTasks.map((task) => task.toJson()).toList();
    final events = myEvents.map((event) => event.toJson()).toList();
    await File('${folder.path}/tasks.json').writeAsString(jsonEncode(tasks));
    await File('${folder.path}/events.json').writeAsString(jsonEncode(events));
  } catch (e) {
    debugPrint('Could not save the data: $e');
  }
}

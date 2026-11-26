import 'dart:convert';
import 'dart:io';

import 'package:chrono/models/app_settings.dart';
import 'package:chrono/screens/settings_screen.dart';
import 'package:chrono/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory folder;

  setUp(() {
    folder = Directory.systemTemp.createTempSync('chrono_settings_screen');
    storageFolder = folder;
    mySettings.value = const AppSettings();
  });

  tearDown(() {
    storageFolder = null;
    mySettings.value = const AppSettings();
    folder.deleteSync(recursive: true);
  });

  Future<void> openSettings(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
  }

  Map<String, dynamic> savedFile() =>
      jsonDecode(File('${folder.path}/settings.json').readAsStringSync());

  testWidgets('shows the current settings', (tester) async {
    mySettings.value = const AppSettings(name: 'Viktor');
    await openSettings(tester);

    expect(find.text('Viktor'), findsOneWidget);
    expect(find.text('08:00'), findsOneWidget);
    expect(find.text('22:00'), findsOneWidget);
    expect(find.text('1h'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
  });

  testWidgets('turning off asking is saved', (tester) async {
    await openSettings(tester);

    await tester.tap(find.text('Ask before changing my calendar'));
    await tester.runAsync(() => Future.delayed(
          const Duration(milliseconds: 100),
        ));
    await tester.pump();

    expect(mySettings.value.askBeforeChanging, false);
    expect(savedFile()['ask_before_changing'], false);
  });

  testWidgets('picking a language is saved', (tester) async {
    await openSettings(tester);

    await tester.ensureVisible(find.text('Assistant language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Assistant language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('한국어 (Korean)'));
    await tester.runAsync(() => Future.delayed(
          const Duration(milliseconds: 100),
        ));
    await tester.pumpAndSettle();

    expect(mySettings.value.language, AssistantLanguage.korean);
    expect(find.text('한국어 (Korean)'), findsOneWidget);
    expect(savedFile()['language'], 'korean');
  });
}

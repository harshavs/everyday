import 'dart:io';
import 'package:everyday/main.dart';
import 'package:everyday/models/goal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final tempDir = await Directory.systemTemp.createTemp('hive_test');
    Hive.init(tempDir.path);
    Hive.registerAdapter(GoalAdapter());
    Hive.registerAdapter(FrequencyTypeAdapter());
    await Hive.openBox<Goal>('goals_box');
  });

  tearDownAll(() async {
    await Hive.close();
  });

  testWidgets('Renders initial screen correctly with no goals', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify the title is correct.
    expect(find.text('Your Goals'), findsOneWidget);

    // Verify the "no goals" message is shown.
    expect(find.text('No goals yet. Tap the + button to add one!'), findsOneWidget);

    // Verify the Floating Action Button is present.
    expect(find.byIcon(Icons.add), findsOneWidget);
  });
}
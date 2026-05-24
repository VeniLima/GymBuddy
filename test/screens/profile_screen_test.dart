import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite/sqflite.dart';
import 'package:gymbuddy/screens/profile_screen.dart';
import 'package:gymbuddy/db/database_helper.dart';
import 'package:gymbuddy/managers/translation_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {
  @override
  Future<Database> get database async => MockDatabase();
}

class MockDatabase extends Mock implements Database {
  @override
  Future<List<Map<String, dynamic>>> query(String table,
      {bool? distinct,
      List<String>? columns,
      String? where,
      List<Object?>? whereArgs,
      String? groupBy,
      String? having,
      String? orderBy,
      int? limit,
      int? offset}) async =>
      [];
}

void main() {
  late MockDatabaseHelper mockDb;

  setUpAll(() {
    mockDb = MockDatabaseHelper();
    DatabaseHelper.instance = mockDb;
    
    // Default stubs for ProfileScreen data
    when(() => mockDb.getWorkoutConsistencyStats()).thenAnswer((_) async => {'total': 10, 'thisMonth': 5});
    when(() => mockDb.getMuscleGroupDistribution(any())).thenAnswer((_) async => {'Chest': 20, 'Back': 15});
    when(() => mockDb.getExercises()).thenAnswer((_) async => []);
    when(() => mockDb.getWeightLogs()).thenAnswer((_) async => []);
    when(() => mockDb.getWorkoutDatesLast7Days()).thenAnswer((_) async => []);
    when(() => mockDb.getWorkoutDatesCurrentMonth()).thenAnswer((_) async => []);
    when(() => mockDb.getAllWorkoutsOrderedByDate()).thenAnswer((_) async => []);
  });

  Widget createTestableWidget() {
    return MaterialApp(
      home: const ProfileScreen(),
    );
  }

  testWidgets('ProfileScreen should display BMI and category when height and weight are set', (WidgetTester tester) async {
    // 175cm height, 75kg weight -> BMI approx 24.5 (Normal)
    SharedPreferences.setMockInitialValues({
      'user_height': 175.0,
    });
    
    when(() => mockDb.getWeightLogs()).thenAnswer((_) async => [
      {'id': 1, 'date': '2026-05-19', 'weight': 75.0}
    ]);

    await tester.pumpWidget(createTestableWidget());
    await tester.pumpAndSettle();

    // Check height and weight display
    expect(find.text('175'), findsOneWidget);
    expect(find.text('75.0'), findsOneWidget);

    // Check BMI (approx 24.5)
    expect(find.text('24.5'), findsOneWidget);
    expect(find.text('Peso Normal'), findsOneWidget);
  });

  testWidgets('Toggling RPE switch should update SharedPreferences', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'user_enable_rpe': false,
    });

    await tester.pumpWidget(createTestableWidget());
    await tester.pumpAndSettle();

    final rpeSwitch = find.byType(Switch).first; // Based on code order (RPE usually comes first/among others)
    await tester.tap(rpeSwitch);
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('user_enable_rpe'), true);
  });

  testWidgets('Changing language via PopupMenu should update TranslationManager', (WidgetTester tester) async {
    await TranslationManager.instance.setLanguage('pt');
    
    await tester.pumpWidget(createTestableWidget());
    await tester.pumpAndSettle();

    expect(TranslationManager.instance.currentLanguage, 'pt');

    // Find the PopupMenuButton (arrow down icon)
    final langMenu = find.byIcon(Icons.keyboard_arrow_down);
    await tester.tap(langMenu);
    await tester.pumpAndSettle();

    // Select English
    await tester.tap(find.text('English').last);
    await tester.pumpAndSettle();

    expect(TranslationManager.instance.currentLanguage, 'en');
  });
}

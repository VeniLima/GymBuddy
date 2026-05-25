import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gymbuddy/screens/exercise_library_screen.dart';
import 'package:gymbuddy/screens/exercise_library_detail_screen.dart';
import 'package:gymbuddy/db/database_helper.dart';
import 'package:gymbuddy/models/exercise.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {}

class MockAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async => throw UnimplementedError();

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (key == 'assets/exercises.json') {
      return json.encode([
        {
          "name": "Bench Press",
          "primaryMuscles": ["chest"],
          "force": "push",
          "instructions": ["Step 1", "Step 2"],
          "category": "strength",
          "equipment": "barbell",
          "level": "beginner",
          "mechanic": "compound",
          "images": []
        },
        {
          "name": "Squat",
          "primaryMuscles": ["quadriceps"],
          "force": "push",
          "instructions": ["Step 1"],
          "category": "strength",
          "equipment": "barbell",
          "level": "intermediate",
          "mechanic": "compound",
          "images": []
        }
      ]);
    }
    return '';
  }
}

void main() {
  late MockDatabaseHelper mockDb;

  setUpAll(() {
    mockDb = MockDatabaseHelper();
    DatabaseHelper.instance = mockDb;
    SharedPreferences.setMockInitialValues({});
  });

  Widget createTestableWidget() {
    return DefaultAssetBundle(
      bundle: MockAssetBundle(),
      child: MaterialApp(
        home: const ExerciseLibraryScreen(),
      ),
    );
  }

  testWidgets('ExerciseLibraryScreen should load and display exercises from JSON', (WidgetTester tester) async {
    when(() => mockDb.getExercises()).thenAnswer((_) async => []);

    await tester.pumpWidget(createTestableWidget());
    await tester.pumpAndSettle();

    expect(find.text('Supino Reto'), findsOneWidget);
    expect(find.text('Agachamento Livre'), findsOneWidget);
  });

  testWidgets('Searching exercises should filter the list', (WidgetTester tester) async {
    when(() => mockDb.getExercises()).thenAnswer((_) async => []);

    await tester.pumpWidget(createTestableWidget());
    await tester.pumpAndSettle();

    final searchField = find.byType(TextField);
    await tester.enterText(searchField, 'Bench');
    await tester.pump(); 

    expect(find.text('Supino Reto'), findsOneWidget);
    expect(find.text('Agachamento Livre'), findsNothing);
  });

  testWidgets('Filtering by muscle should filter the list', (WidgetTester tester) async {
    when(() => mockDb.getExercises()).thenAnswer((_) async => []);

    await tester.pumpWidget(createTestableWidget());
    await tester.pumpAndSettle();

    // The filter is now a DropdownButton. 
    // Initial value is 'Todos Músculos' (PT)
    expect(find.text('Todos Músculos'), findsOneWidget);
    
    await tester.tap(find.text('Todos Músculos'));
    await tester.pumpAndSettle();

    // Select 'Peito' (Chest)
    await tester.tap(find.text('Peito').last);
    await tester.pumpAndSettle();

    expect(find.text('Supino Reto'), findsOneWidget);
    expect(find.text('Agachamento Livre'), findsNothing);
  });

  testWidgets('Tapping an exercise should navigate to Detail screen', (WidgetTester tester) async {
    when(() => mockDb.getExercises()).thenAnswer((_) async => []);

    await tester.pumpWidget(createTestableWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Supino Reto'));
    await tester.pumpAndSettle();

    expect(find.byType(ExerciseLibraryDetailScreen), findsOneWidget);
    expect(find.text('Supino Reto'), findsOneWidget);
    expect(find.text('BARBELL'), findsOneWidget);
    expect(find.text('EMPURRAR'), findsOneWidget);
  });
}

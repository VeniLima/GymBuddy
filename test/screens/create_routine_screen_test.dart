import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gymbuddy/screens/create_routine_screen.dart';
import 'package:gymbuddy/models/exercise.dart';
import 'package:gymbuddy/models/routine.dart';
import 'package:gymbuddy/db/database_helper.dart';
import 'package:gymbuddy/managers/translation_manager.dart';
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
          "name": "Bench Press (Barbell)",
          "primaryMuscles": ["chest"],
          "instructions": ["Step 1"],
          "category": "strength",
          "equipment": "barbell",
          "level": "beginner",
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
    
    registerFallbackValue(Routine(name: '', description: ''));
  });

  Widget createTestableWidget() {
    return DefaultAssetBundle(
      bundle: MockAssetBundle(),
      child: MaterialApp(
        home: const CreateRoutineScreen(),
      ),
    );
  }

  testWidgets('CreateRoutineScreen should allow adding and removing exercises', (WidgetTester tester) async {
    final localExercises = [
      Exercise(id: 1, name: 'Bench Press (Barbell)', muscleGroup: 'Chest'),
    ];

    when(() => mockDb.getExercises()).thenAnswer((_) async => localExercises);

    await tester.pumpWidget(createTestableWidget());
    await tester.pumpAndSettle();

    // Verify empty state initially
    expect(find.text('Nenhum exercício adicionado.'), findsOneWidget);

    // Tap Add Exercise Button
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(find.text('Bench Press (Barbell)'), findsOneWidget);
    await tester.tap(find.text('Bench Press (Barbell)'));
    await tester.pumpAndSettle();

    // Verify it was added to the list
    expect(find.text('Supino Reto (Barra)'), findsOneWidget);
    expect(find.text('Nenhum exercício adicionado.'), findsNothing);

    // Remove it
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('Nenhum exercício adicionado.'), findsOneWidget);
  });

  testWidgets('Saving a routine without name should show error snackbar', (WidgetTester tester) async {
    when(() => mockDb.getExercises()).thenAnswer((_) async => []);

    await tester.pumpWidget(createTestableWidget());
    await tester.pumpAndSettle();

    // Tap Save
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Por favor, insira o nome da rotina'), findsOneWidget);
  });

  testWidgets('Saving a valid routine should call database insert', (WidgetTester tester) async {
    final localExercises = [
      Exercise(id: 1, name: 'Bench Press (Barbell)', muscleGroup: 'Chest'),
    ];

    when(() => mockDb.getExercises()).thenAnswer((_) async => localExercises);
    when(() => mockDb.insertRoutine(any(), any(), exerciseSuperSets: any(named: 'exerciseSuperSets')))
        .thenAnswer((_) async => Routine(id: 1, name: 'Test', description: ''));

    await tester.pumpWidget(createTestableWidget());
    await tester.pumpAndSettle();

    // Enter name
    await tester.enterText(find.byType(TextField), 'My New Routine');

    // Add exercise
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    
    await tester.tap(find.text('Bench Press (Barbell)'));
    await tester.pumpAndSettle();

    // Save
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    verify(() => mockDb.insertRoutine(any(), any(), exerciseSuperSets: any(named: 'exerciseSuperSets'))).called(1);
  });
}

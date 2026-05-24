import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gymbuddy/screens/workout_history_screen.dart';
import 'package:gymbuddy/models/workout.dart';
import 'package:gymbuddy/models/workout_set.dart';
import 'package:gymbuddy/models/exercise.dart';
import 'package:gymbuddy/db/database_helper.dart';
import 'package:gymbuddy/managers/translation_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {}

void main() {
  late MockDatabaseHelper mockDb;

  setUpAll(() {
    mockDb = MockDatabaseHelper();
    DatabaseHelper.instance = mockDb;
    SharedPreferences.setMockInitialValues({});
  });

  Widget createTestableWidget() {
    return MaterialApp(
      home: const WorkoutHistoryScreen(),
    );
  }

  testWidgets('WorkoutHistoryScreen should display empty state when no history', (WidgetTester tester) async {
    when(() => mockDb.getAllWorkoutsOrderedByDate()).thenAnswer((_) async => []);
    when(() => mockDb.getExercises()).thenAnswer((_) async => []);

    await tester.pumpWidget(createTestableWidget());
    await tester.pumpAndSettle();

    expect(find.text('Nenhum treino concluído ainda.'), findsOneWidget);
  });

  testWidgets('WorkoutHistoryScreen should list workouts from database', (WidgetTester tester) async {
    final workout = Workout(
      id: 1,
      name: 'Full Body A',
      startTime: DateTime.now().subtract(const Duration(hours: 2)),
      durationSeconds: 3600,
      totalVolume: 5000,
      recordsBroken: 2,
    );

    final exercises = [
      Exercise(id: 1, name: 'Bench Press (Barbell)', muscleGroup: 'Chest')
    ];

    final sets = [
      WorkoutSet(id: 1, workoutId: 1, exerciseId: 1, reps: 10, weight: 60, isCompleted: true)
    ];

    when(() => mockDb.getAllWorkoutsOrderedByDate()).thenAnswer((_) async => [workout]);
    when(() => mockDb.getExercises()).thenAnswer((_) async => exercises);
    when(() => mockDb.getSetsForWorkout(1)).thenAnswer((_) async => sets);

    await tester.pumpWidget(createTestableWidget());
    await tester.pumpAndSettle();

    expect(find.text('Full Body A'), findsOneWidget);
    // Based on _buildQuickMetric implementation, it might be formatted as "5000 kg"
    expect(find.textContaining('5000'), findsOneWidget); 
    expect(find.text('1h 0m'), findsOneWidget); // Duration
  });

  testWidgets('Deleting a workout should trigger confirmation dialog', (WidgetTester tester) async {
    final workout = Workout(
      id: 1,
      name: 'Leg Day',
      startTime: DateTime.now(),
      durationSeconds: 1800,
      totalVolume: 3000,
    );

    when(() => mockDb.getAllWorkoutsOrderedByDate()).thenAnswer((_) async => [workout]);
    when(() => mockDb.getExercises()).thenAnswer((_) async => []);
    when(() => mockDb.getSetsForWorkout(any())).thenAnswer((_) async => []);
    when(() => mockDb.deleteWorkout(1)).thenAnswer((_) async => 1);

    await tester.pumpWidget(createTestableWidget());
    await tester.pumpAndSettle();

    // Use Icons.delete_outline based on code analysis
    final deleteIcon = find.byIcon(Icons.delete_outline);
    expect(deleteIcon, findsWidgets);

    await tester.tap(deleteIcon.first);
    await tester.pumpAndSettle();

    expect(find.text('Excluir Treino'), findsOneWidget);
    
    await tester.tap(find.text('Excluir').last);
    await tester.pumpAndSettle();

    verify(() => mockDb.deleteWorkout(1)).called(1);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:gymbuddy/db/database_helper.dart';
import 'package:gymbuddy/models/exercise.dart';
import 'package:gymbuddy/models/workout.dart';
import 'package:gymbuddy/models/workout_set.dart';
import 'package:gymbuddy/models/routine.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('DatabaseHelper Integration Tests', () {
    late DatabaseHelper dbHelper;

    setUp(() async {
      dbHelper = DatabaseHelper.instance;
      await dbHelper.initTestDatabase();
    });

    tearDown(() async {
      await dbHelper.close();
    });

    test('Initial database should have default exercises', () async {
      final exercises = await dbHelper.getExercises();
      expect(exercises.length, greaterThan(0), reason: 'Default exercises should be inserted on creation');
      expect(exercises.any((e) => e.name.contains('Bench Press')), true);
    });

    test('CRUD Exercises', () async {
      final newEx = Exercise(name: 'My Custom Exercise', muscleGroup: 'Chest', notes: 'Keep elbows tucked');
      
      // Insert
      final inserted = await dbHelper.insertExercise(newEx);
      expect(inserted.id, isNotNull);
      expect(inserted.name, 'My Custom Exercise');
      expect(inserted.notes, 'Keep elbows tucked');

      // Query
      final list = await dbHelper.getExercises();
      final retrieved = list.firstWhere((e) => e.id == inserted.id);
      expect(retrieved.name, 'My Custom Exercise');
      expect(retrieved.notes, 'Keep elbows tucked');

      // Update
      final toUpdate = Exercise(id: inserted.id, name: 'Renamed Exercise', muscleGroup: 'Chest', notes: 'New updated notes');
      final rowsAffected = await dbHelper.updateExercise(toUpdate);
      expect(rowsAffected, 1);
      
      final listAfterUpdate = await dbHelper.getExercises();
      final retrievedAfterUpdate = listAfterUpdate.firstWhere((e) => e.id == inserted.id);
      expect(retrievedAfterUpdate.name, 'Renamed Exercise');
      expect(retrievedAfterUpdate.notes, 'New updated notes');

      // Delete
      await dbHelper.deleteExercise(inserted.id!);
      final listAfterDelete = await dbHelper.getExercises();
      expect(listAfterDelete.any((e) => e.id == inserted.id), false);
    });

    test('CRUD Routines', () async {
      final exercises = await dbHelper.getExercises();
      if (exercises.length < 2) {
        fail('Not enough exercises to run routine test');
      }
      final ex1 = exercises[0];
      final ex2 = exercises[1];

      final routine = Routine(name: 'New Test Routine', description: 'Test Desc');
      final exerciseSets = {
        ex1.id!: 3,
        ex2.id!: 5,
      };

      // Insert
      final inserted = await dbHelper.insertRoutine(routine, exerciseSets);
      expect(inserted.id, isNotNull);

      // Query routines
      final routines = await dbHelper.getRoutines();
      expect(routines.any((r) => r.id == inserted.id && r.name == 'New Test Routine'), true);

      // Query exercises for routine
      final routineExs = await dbHelper.getExercisesForRoutine(inserted.id!);
      expect(routineExs.length, 2);

      // Query sets for routine
      final sets = await dbHelper.getRoutineExerciseSets(inserted.id!);
      expect(sets[ex1.id], 3);
      expect(sets[ex2.id], 5);
    });

    test('Workout and WorkoutSet Integration', () async {
      // 1. Create a workout
      final workout = Workout(
        name: 'Integration Workout',
        startTime: DateTime.now(),
        durationSeconds: 1200,
        totalVolume: 2000,
      );
      final insertedWorkout = await dbHelper.insertWorkout(workout);
      expect(insertedWorkout.id, isNotNull);

      // 2. Add sets
      final exercises = await dbHelper.getExercises();
      final ex = exercises[0];

      final set1 = WorkoutSet(
        workoutId: insertedWorkout.id,
        exerciseId: ex.id!,
        reps: 10,
        weight: 100,
        isCompleted: true,
      );
      await dbHelper.insertWorkoutSet(set1);

      final set2 = WorkoutSet(
        workoutId: insertedWorkout.id,
        exerciseId: ex.id!,
        reps: 5,
        weight: 150,
        isCompleted: true,
      );
      await dbHelper.insertWorkoutSet(set2);

      // 3. Verify Stats
      final maxWeight = await dbHelper.getMaxWeightForExercise(ex.id!);
      expect(maxWeight, 150.0);

      final maxVolume = await dbHelper.getMaxVolumeForExercise(ex.id!);
      expect(maxVolume, 1000.0); // 10*100=1000 vs 5*150=750

      final lastSets = await dbHelper.getLastWorkoutSetsForExercise(ex.id!);
      expect(lastSets.length, 2);
      expect(lastSets[0].weight, 100.0);
      expect(lastSets[1].weight, 150.0);
    });

    test('CRUD Body Measurements', () async {
      // Insert
      final id1 = await dbHelper.insertBodyMeasurement('prof_arm', 40.5);
      final id2 = await dbHelper.insertBodyMeasurement('prof_waist', 80.0);
      expect(id1, isPositive);
      expect(id2, isPositive);

      // Query
      final list = await dbHelper.getBodyMeasurements();
      expect(list.length, greaterThanOrEqualTo(2));
      expect(list.any((m) => m['id'] == id1 && m['type'] == 'prof_arm' && m['value'] == 40.5), true);
      expect(list.any((m) => m['id'] == id2 && m['type'] == 'prof_waist' && m['value'] == 80.0), true);

      // Delete
      await dbHelper.deleteBodyMeasurement(id1);
      final listAfterDelete = await dbHelper.getBodyMeasurements();
      expect(listAfterDelete.any((m) => m['id'] == id1), false);
      expect(listAfterDelete.any((m) => m['id'] == id2), true);
    });
  });
}

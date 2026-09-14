import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gymbuddy/managers/workout_manager.dart';
import 'package:gymbuddy/managers/notification_manager.dart';
import 'package:gymbuddy/db/database_helper.dart';
import 'package:gymbuddy/models/exercise.dart';
import 'package:gymbuddy/models/workout.dart';
import 'package:gymbuddy/models/workout_set.dart';
import 'package:gymbuddy/models/routine.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {}
class MockNotificationManager extends Mock implements NotificationManager {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late WorkoutManager manager;
  late MockDatabaseHelper mockDb;
  late MockNotificationManager mockNotifications;

  setUpAll(() {
    registerFallbackValue(Exercise(name: '', muscleGroup: ''));
    registerFallbackValue(Workout(name: '', startTime: DateTime.now()));
    registerFallbackValue(WorkoutSet(exerciseId: 0, reps: 0, weight: 0));
    registerFallbackValue(<WorkoutSet>[]);
    registerFallbackValue(Routine(name: '', description: ''));

    const MethodChannel('xyz.luan/audioplayers').setMockMethodCallHandler((_) async => null);
    const MethodChannel('xyz.luan/audioplayers.global').setMockMethodCallHandler((_) async => null);
  });

  setUp(() async {
    mockDb = MockDatabaseHelper();
    mockNotifications = MockNotificationManager();
    DatabaseHelper.instance = mockDb;
    NotificationManager.instance = mockNotifications;
    
    SharedPreferences.setMockInitialValues({});

    manager = WorkoutManager.instance;
    manager.cancelWorkout(); // Reset state (also clears any leftover draft, which needs the mock above)

    when(() => mockDb.getExercises()).thenAnswer((_) async => []);
    when(() => mockDb.getMaxWeightForExercise(any())).thenAnswer((_) async => 0.0);
    when(() => mockDb.getMaxVolumeForExercise(any())).thenAnswer((_) async => 0.0);
    when(() => mockDb.getLastWorkoutSetsForExercise(any())).thenAnswer((_) async => []);
    when(() => mockDb.getExerciseMaxStats()).thenAnswer((_) async => {});
    when(() => mockDb.getLastWorkoutSetsForAllExercises()).thenAnswer((_) async => {});
    when(() => mockNotifications.showWorkoutNotification(any(), any(), restTime: any(named: 'restTime')))
        .thenAnswer((_) async => null);
    when(() => mockNotifications.hideWorkoutNotification()).thenAnswer((_) async => null);
  });

  test('startWorkout should initialize state correctly', () async {
    final exercise = Exercise(id: 1, name: 'Push Up', muscleGroup: 'Chest');
    
    await manager.startWorkout('Test Workout', [exercise]);

    expect(manager.isActive, true);
    expect(manager.workoutName, 'Test Workout');
    expect(manager.workoutExercises.containsKey(exercise), true);
    expect(manager.workoutExercises[exercise]!.length, 1);
  });

  test('addSet should add a new set to the exercise', () async {
    final exercise = Exercise(id: 1, name: 'Push Up', muscleGroup: 'Chest');
    await manager.startWorkout('Test', [exercise]);

    manager.addSet(exercise);
    expect(manager.workoutExercises[exercise]!.length, 2);
  });

  test('toggleSetCompletion should toggle and start rest timer', () async {
    final exercise = Exercise(id: 1, name: 'Push Up', muscleGroup: 'Chest');
    await manager.startWorkout('Test', [exercise]);

    manager.toggleSetCompletion(exercise, 0);
    expect(manager.workoutExercises[exercise]![0].isCompleted, true);
  });

  test('finishWorkout should save workout and sets to database', () async {
    final exercise = Exercise(id: 1, name: 'Push Up', muscleGroup: 'Chest');
    await manager.startWorkout('Test', [exercise]);
    
    manager.updateSet(exercise, 0, WorkoutSet(exerciseId: 1, reps: 10, weight: 0, isCompleted: true));
    
    when(() => mockDb.insertWorkoutWithSets(any(), any())).thenAnswer((invocation) async {
      final workout = invocation.positionalArguments[0] as Workout;
      final sets = invocation.positionalArguments[1] as List<WorkoutSet>;
      final savedWorkout = Workout(
        id: 1,
        name: workout.name,
        startTime: workout.startTime,
        endTime: workout.endTime,
        durationSeconds: workout.durationSeconds,
        totalVolume: workout.totalVolume,
        notes: workout.notes,
        recordsBroken: workout.recordsBroken,
      );
      final savedSets = [
        for (var i = 0; i < sets.length; i++)
          WorkoutSet(
            id: i + 1,
            workoutId: 1,
            exerciseId: sets[i].exerciseId,
            reps: sets[i].reps,
            weight: sets[i].weight,
            durationSeconds: sets[i].durationSeconds,
            distance: sets[i].distance,
            setType: sets[i].setType,
            isCompleted: sets[i].isCompleted,
            rpe: sets[i].rpe,
            superSetId: sets[i].superSetId,
          ),
      ];
      return (savedWorkout, savedSets);
    });
    when(() => mockDb.getRoutines()).thenAnswer((_) async => []);

    final result = await manager.finishWorkout();

    expect(result.workout.id, 1);
    expect(result.sets.length, 1);
    expect(manager.isActive, false);
    verify(() => mockDb.insertWorkoutWithSets(any(), any())).called(1);
  });

  group('Draft autosave (active workout survives a process restart)', () {
    test('a mutation (toggleSetCompletion) saves a draft that restoreDraftIfAny() can recover', () async {
      final exercise = Exercise(id: 1, name: 'Push Up', muscleGroup: 'Chest');
      when(() => mockDb.getExercises()).thenAnswer((_) async => [exercise]);

      await manager.startWorkout('Draft Test', [exercise]);
      manager.toggleSetCompletion(exercise, 0); // triggers _saveDraft()
      manager.exerciseRestTimes[1] = 77;

      // Give the fire-and-forget _saveDraft() calls a chance to complete.
      await Future.delayed(Duration.zero);

      // Simulate the process dying and restarting: memory is gone, but
      // SharedPreferences (backed by the mock, which persists for this
      // test) survives.
      manager.isActive = false;
      manager.isMinimized = false;
      manager.workoutExercises.clear();
      manager.workoutName = '';
      manager.secondsElapsed = 0;

      final restored = await manager.restoreDraftIfAny();

      expect(restored, true);
      expect(manager.isActive, true);
      expect(manager.isMinimized, true, reason: 'should land on the resume banner, not the screen');
      expect(manager.workoutName, 'Draft Test');
      expect(manager.workoutExercises.containsKey(exercise), true);
      expect(manager.workoutExercises[exercise]!.first.isCompleted, true);
      expect(manager.exerciseRestTimes[1], 77);

      manager.cancelWorkout();
    });

    test('restoreDraftIfAny() returns false when there is no saved draft', () async {
      final restored = await manager.restoreDraftIfAny();
      expect(restored, false);
      expect(manager.isActive, false);
    });

    test('restoreDraftIfAny() does nothing if a workout is already active in memory', () async {
      final exercise = Exercise(id: 1, name: 'Push Up', muscleGroup: 'Chest');
      when(() => mockDb.getExercises()).thenAnswer((_) async => [exercise]);
      await manager.startWorkout('Already Active', [exercise]);

      final restored = await manager.restoreDraftIfAny();

      expect(restored, false);
      expect(manager.workoutName, 'Already Active');
    });

    test('cancelWorkout() clears the draft so it is not restored later', () async {
      final exercise = Exercise(id: 1, name: 'Push Up', muscleGroup: 'Chest');
      when(() => mockDb.getExercises()).thenAnswer((_) async => [exercise]);
      await manager.startWorkout('To Be Cancelled', [exercise]);
      await Future.delayed(Duration.zero);

      manager.cancelWorkout();

      // Simulate a restart after cancelling.
      manager.workoutExercises.clear();
      final restored = await manager.restoreDraftIfAny();
      expect(restored, false);
    });
  });
}

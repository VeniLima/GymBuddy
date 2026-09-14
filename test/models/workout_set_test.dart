import 'package:flutter_test/flutter_test.dart';
import 'package:gymbuddy/models/workout_set.dart';

void main() {
  group('WorkoutSet Model Tests', () {
    test('Should create a WorkoutSet instance correctly', () {
      final workoutSet = WorkoutSet(
        id: 1,
        exerciseId: 10,
        reps: 12,
        weight: 20.5,
        setType: 'Normal',
        isCompleted: true,
      );

      expect(workoutSet.id, 1);
      expect(workoutSet.exerciseId, 10);
      expect(workoutSet.reps, 12);
      expect(workoutSet.weight, 20.5);
      expect(workoutSet.setType, 'Normal');
      expect(workoutSet.isCompleted, true);
    });

    test('toMap() should return a valid Map', () {
      final workoutSet = WorkoutSet(
        id: 1,
        workoutId: 100,
        exerciseId: 10,
        reps: 12,
        weight: 20.5,
        isCompleted: true,
      );

      final map = workoutSet.toMap();

      expect(map['id'], 1);
      expect(map['workoutId'], 100);
      expect(map['reps'], 12);
      expect(map['weight'], 20.5);
      expect(map['isCompleted'], 1); // 1 for true
    });

    test('fromMap() should create a valid WorkoutSet instance', () {
      final map = {
        'id': 1,
        'workoutId': 100,
        'exerciseId': 10,
        'reps': 15,
        'weight': 30.0,
        'setType': 'Drop',
        'isCompleted': 0,
      };

      final workoutSet = WorkoutSet.fromMap(map);

      expect(workoutSet.id, 1);
      expect(workoutSet.reps, 15);
      expect(workoutSet.weight, 30.0);
      expect(workoutSet.setType, 'Drop');
      expect(workoutSet.isCompleted, false);
    });

    test('fromMap() should handle null/default values safely', () {
      final map = {
        'exerciseId': 5,
        // reps and weight missing
      };

      final workoutSet = WorkoutSet.fromMap(map);

      expect(workoutSet.reps, 0);
      expect(workoutSet.weight, 0.0);
      expect(workoutSet.setType, 'Normal');
    });
  });

  group('WorkoutSet.copyWith', () {
    final base = WorkoutSet(
      id: 1,
      workoutId: 100,
      exerciseId: 10,
      reps: 10,
      weight: 60.0,
      setType: 'Normal',
      isCompleted: false,
      rpe: 8.0,
      superSetId: 'ss-1',
    );

    test('keeps every field unchanged when nothing is passed', () {
      final copy = base.copyWith();
      expect(copy.id, base.id);
      expect(copy.workoutId, base.workoutId);
      expect(copy.exerciseId, base.exerciseId);
      expect(copy.reps, base.reps);
      expect(copy.weight, base.weight);
      expect(copy.setType, base.setType);
      expect(copy.isCompleted, base.isCompleted);
      expect(copy.rpe, base.rpe);
      expect(copy.superSetId, base.superSetId);
    });

    test('overrides only the fields that are passed', () {
      final copy = base.copyWith(weight: 65.0, isCompleted: true);
      expect(copy.weight, 65.0);
      expect(copy.isCompleted, true);
      // everything else preserved
      expect(copy.reps, base.reps);
      expect(copy.setType, base.setType);
      expect(copy.rpe, base.rpe);
    });

    test('can explicitly clear rpe back to null', () {
      final copy = base.copyWith(rpe: null);
      expect(copy.rpe, isNull);
    });

    test('omitting rpe entirely still preserves the original value', () {
      final copy = base.copyWith(weight: 70.0);
      expect(copy.rpe, base.rpe);
    });

    test('setType can be changed independently of everything else', () {
      final copy = base.copyWith(setType: 'Warmup');
      expect(copy.setType, 'Warmup');
      expect(copy.weight, base.weight);
      expect(copy.reps, base.reps);
    });
  });
}

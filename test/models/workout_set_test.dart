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
}

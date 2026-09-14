import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:gymbuddy/db/database_helper.dart';
import 'package:gymbuddy/managers/achievement_manager.dart';
import 'package:gymbuddy/models/workout.dart';
import 'package:gymbuddy/models/workout_set.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('AchievementManager', () {
    late DatabaseHelper dbHelper;
    late AchievementManager manager;

    setUp(() async {
      dbHelper = DatabaseHelper.instance;
      await dbHelper.initTestDatabase();
      manager = AchievementManager.instance;
    });

    tearDown(() async {
      await dbHelper.close();
    });

    test('getUnlockedAchievements returns every definition locked when nothing was unlocked yet', () async {
      final achievements = await manager.getUnlockedAchievements();
      expect(achievements.length, manager.definitions.length);
      expect(achievements.every((a) => !a.isUnlocked), true);
    });

    test('first_workout unlocks once the player has at least one saved workout', () async {
      final workout = Workout(name: 'W1', startTime: DateTime.now(), endTime: DateTime.now());
      await dbHelper.insertWorkout(workout);

      final unlocked = await manager.checkAchievements(workout, []);

      expect(unlocked.any((a) => a.id == 'first_workout'), true);
    });

    test('an already-unlocked achievement is never unlocked (or inserted) twice', () async {
      final workout = Workout(name: 'W1', startTime: DateTime.now(), endTime: DateTime.now());
      await dbHelper.insertWorkout(workout);

      final firstCall = await manager.checkAchievements(workout, []);
      expect(firstCall.any((a) => a.id == 'first_workout'), true);

      final secondCall = await manager.checkAchievements(workout, []);
      expect(secondCall.any((a) => a.id == 'first_workout'), false, reason: 'must not unlock the same achievement again');

      final db = await dbHelper.database;
      final rows = await db.query('unlocked_achievements', where: 'achievementId = ?', whereArgs: ['first_workout']);
      expect(rows.length, 1, reason: 'must not insert a duplicate row either');
    });

    test('early_bird unlocks for a workout finished before 8 AM', () async {
      final workout = Workout(
        name: 'Dawn session',
        startTime: DateTime(2026, 1, 1, 6, 0),
        endTime: DateTime(2026, 1, 1, 7, 30),
      );
      final unlocked = await manager.checkAchievements(workout, []);
      expect(unlocked.any((a) => a.id == 'early_bird'), true);
    });

    test('early_bird does not unlock for a workout finished at or after 8 AM', () async {
      final workout = Workout(
        name: 'Morning session',
        startTime: DateTime(2026, 1, 1, 7, 0),
        endTime: DateTime(2026, 1, 1, 8, 0),
      );
      final unlocked = await manager.checkAchievements(workout, []);
      expect(unlocked.any((a) => a.id == 'early_bird'), false);
    });

    test('cardio_5h unlocks once completed cardio sets add up to 5 hours', () async {
      final exercises = await dbHelper.getExercises();
      final ex = exercises[0];
      final earlierWorkout = await dbHelper.insertWorkout(Workout(name: 'Cardio A', startTime: DateTime.now()));
      await dbHelper.insertWorkoutSet(WorkoutSet(
        workoutId: earlierWorkout.id,
        exerciseId: ex.id!,
        reps: 1,
        weight: 0,
        durationSeconds: 5 * 3600,
        isCompleted: true,
      ));

      final workout = Workout(name: 'Cardio B', startTime: DateTime.now(), endTime: DateTime.now());
      final unlocked = await manager.checkAchievements(workout, []);

      expect(unlocked.any((a) => a.id == 'cardio_5h'), true);
    });

    test(
      'squat_100 unlocks for ANY completed set reaching 100kg, not only squats '
      '(known limitation — see docs/AUDITORIA.md; checkAchievements only receives '
      'WorkoutSet, which has no exercise name/category to check against)',
      () async {
        final workout = Workout(name: 'Chest Day', startTime: DateTime.now(), endTime: DateTime.now());
        final benchPressSet = WorkoutSet(exerciseId: 999, reps: 5, weight: 100, isCompleted: true);

        final unlocked = await manager.checkAchievements(workout, [benchPressSet]);

        expect(unlocked.any((a) => a.id == 'squat_100'), true);
      },
    );

    test('squat_100 does not unlock when no completed set reaches 100kg', () async {
      final workout = Workout(name: 'Light Day', startTime: DateTime.now(), endTime: DateTime.now());
      final sets = [
        WorkoutSet(exerciseId: 1, reps: 5, weight: 99.9, isCompleted: true),
        WorkoutSet(exerciseId: 1, reps: 5, weight: 150, isCompleted: false), // not completed
      ];

      final unlocked = await manager.checkAchievements(workout, sets);

      expect(unlocked.any((a) => a.id == 'squat_100'), false);
    });

    test(
      'streak_4 unlocks from 4 workouts in the last 7 days even when NOT on consecutive '
      'days (known limitation — see docs/AUDITORIA.md; the code only checks 4 unique '
      'days, not consecutiveness, despite the achievement being named/described as a streak)',
      () async {
        final now = DateTime.now();
        // Workouts today, 2 days ago, 4 days ago and 6 days ago: 4 unique days,
        // none of them consecutive.
        for (final daysAgo in [0, 2, 4, 6]) {
          await dbHelper.insertWorkout(Workout(
            name: 'Session -$daysAgo',
            startTime: now.subtract(Duration(days: daysAgo)),
          ));
        }

        final workout = Workout(name: 'Today', startTime: now, endTime: now);
        final unlocked = await manager.checkAchievements(workout, []);

        expect(unlocked.any((a) => a.id == 'streak_4'), true);
      },
    );

    test('streak_4 does not unlock with fewer than 4 unique days in the last 7 days', () async {
      final now = DateTime.now();
      for (final daysAgo in [0, 1]) {
        await dbHelper.insertWorkout(Workout(
          name: 'Session -$daysAgo',
          startTime: now.subtract(Duration(days: daysAgo)),
        ));
      }

      final workout = Workout(name: 'Today', startTime: now, endTime: now);
      final unlocked = await manager.checkAchievements(workout, []);

      expect(unlocked.any((a) => a.id == 'streak_4'), false);
    });

    test('getUnlockedAchievements reflects unlockedAt after an achievement is unlocked', () async {
      final workout = Workout(name: 'W1', startTime: DateTime.now(), endTime: DateTime.now());
      await dbHelper.insertWorkout(workout);
      await manager.checkAchievements(workout, []);

      final achievements = await manager.getUnlockedAchievements();
      final firstWorkout = achievements.firstWhere((a) => a.id == 'first_workout');
      final squat100 = achievements.firstWhere((a) => a.id == 'squat_100');

      expect(firstWorkout.isUnlocked, true);
      expect(firstWorkout.unlockedAt, isNotNull);
      expect(squat100.isUnlocked, false);
    });
  });
}

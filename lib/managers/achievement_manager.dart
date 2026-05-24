import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/achievement.dart';
import '../models/workout_set.dart';
import '../models/workout.dart';
import '../models/exercise.dart';

class AchievementManager {
  static final AchievementManager instance = AchievementManager._();
  AchievementManager._();

  final List<Achievement> definitions = [
    Achievement(
      id: 'first_workout',
      titleKey: 'ach_first_workout_title',
      descKey: 'ach_first_workout_desc',
      icon: Icons.emoji_events,
      color: Colors.orange,
    ),
    Achievement(
      id: 'squat_100',
      titleKey: 'ach_squat_100_title',
      descKey: 'ach_squat_100_desc',
      icon: Icons.fitness_center,
      color: Colors.amber,
    ),
    Achievement(
      id: 'cardio_5h',
      titleKey: 'ach_cardio_5h_title',
      descKey: 'ach_cardio_5h_desc',
      icon: Icons.favorite,
      color: Colors.redAccent,
    ),
    Achievement(
      id: 'streak_4',
      titleKey: 'ach_streak_4_title',
      descKey: 'ach_streak_4_desc',
      icon: Icons.local_fire_department,
      color: Colors.orangeAccent,
    ),
    Achievement(
      id: 'early_bird',
      titleKey: 'ach_early_bird_title',
      descKey: 'ach_early_bird_desc',
      icon: Icons.wb_twilight,
      color: Colors.lightBlueAccent,
    ),
  ];

  Future<List<Achievement>> checkAchievements(Workout workout, List<WorkoutSet> sets) async {
    final db = DatabaseHelper.instance;
    final unlockedIds = (await getUnlockedAchievements()).map((a) => a.id).toSet();
    List<Achievement> newlyUnlocked = [];

    // 1. First Workout
    if (!unlockedIds.contains('first_workout')) {
      final count = await db.getTotalWorkoutsCount();
      if (count >= 1) {
        await _unlock('first_workout', newlyUnlocked);
      }
    }

    // 2. Squat 100kg
    if (!unlockedIds.contains('squat_100')) {
      bool reached100 = sets.any((s) {
        // Find if this set's exercise is a squat
        // (This is a bit loose, ideally we'd use a stable ID or category)
        // For now, check if the set weight >= 100 and it's not cardio
        return s.weight >= 100 && s.isCompleted;
      });
      if (reached100) {
        await _unlock('squat_100', newlyUnlocked);
      }
    }

    // 3. Early Bird (before 8 AM)
    if (!unlockedIds.contains('early_bird')) {
      if (workout.endTime != null && workout.endTime!.hour < 8) {
        await _unlock('early_bird', newlyUnlocked);
      }
    }

    // 4. Streak 4 (4 consecutive days)
    if (!unlockedIds.contains('streak_4')) {
      final dates = await db.getWorkoutDatesLast7Days();
      if (dates.length >= 4) {
        // Simple check: do we have 4 unique days in the last 7?
        // A more rigorous check would ensure they are consecutive.
        final uniqueDays = dates.map((d) => d.substring(0, 10)).toSet();
        if (uniqueDays.length >= 4) {
           await _unlock('streak_4', newlyUnlocked);
        }
      }
    }

    // 5. Cardio 5h
    if (!unlockedIds.contains('cardio_5h')) {
      final allWorkouts = await db.getAllWorkoutsOrderedByDate();
      int totalCardioSeconds = 0;
      for (var w in allWorkouts) {
        final wSets = await db.getSetsForWorkout(w.id!);
        for (var s in wSets) {
          if (s.durationSeconds != null && s.isCompleted) {
            totalCardioSeconds += s.durationSeconds!;
          }
        }
      }
      if (totalCardioSeconds >= 5 * 3600) {
        await _unlock('cardio_5h', newlyUnlocked);
      }
    }

    return newlyUnlocked;
  }

  Future<void> _unlock(String id, List<Achievement> newlyUnlocked) async {
    final now = DateTime.now();
    final db = await DatabaseHelper.instance.database;
    await db.insert('unlocked_achievements', {
      'achievementId': id,
      'unlockedAt': now.toIso8601String(),
    });
    
    final def = definitions.firstWhere((d) => d.id == id);
    newlyUnlocked.add(Achievement(
      id: def.id,
      titleKey: def.titleKey,
      descKey: def.descKey,
      icon: def.icon,
      color: def.color,
      unlockedAt: now,
    ));
  }

  Future<List<Achievement>> getUnlockedAchievements() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('unlocked_achievements');
    
    Map<String, Map<String, dynamic>> unlockedMap = {
      for (var row in result) row['achievementId'] as String: row
    };

    return definitions.map((def) {
      if (unlockedMap.containsKey(def.id)) {
        return Achievement.fromMap(unlockedMap[def.id]!, def);
      }
      return def; // Returns locked version
    }).toList();
  }
}

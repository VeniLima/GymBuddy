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

  group('DatabaseHelper Backup and Restore Tests', () {
    late DatabaseHelper dbHelper;

    setUp(() async {
      dbHelper = DatabaseHelper.instance;
      await dbHelper.initTestDatabase();
    });

    tearDown(() async {
      await dbHelper.close();
    });

    test('Export and Restore validation', () async {
      // 1. Inserir dados de teste
      // Exercício personalizado
      final customEx = await dbHelper.insertExercise(
        Exercise(name: 'Backup Custom Push', muscleGroup: 'Chest', restTimeSeconds: 120),
      );

      // Rotina
      final routine = Routine(name: 'Backup Routine A', description: 'Routine for backup test');
      final routineExs = {customEx.id!: 3};
      final insertedRoutine = await dbHelper.insertRoutine(routine, routineExs);

      // Treino concluído
      final workout = Workout(
        name: 'Backup Workout 1',
        startTime: DateTime.parse('2026-05-20T10:00:00Z'),
        durationSeconds: 3600,
        totalVolume: 1200,
        recordsBroken: 1,
        notes: 'Great backup test session',
      );
      final insertedWorkout = await dbHelper.insertWorkout(workout);

      // Séries de treino
      final set1 = WorkoutSet(
        workoutId: insertedWorkout.id,
        exerciseId: customEx.id!,
        reps: 10,
        weight: 60.0,
        isCompleted: true,
        setType: 'normal',
        rpe: 8.5,
      );
      await dbHelper.insertWorkoutSet(set1);

      // Log de peso
      await dbHelper.insertWeightLog(75.5);

      // 2. Exportar dados
      final backup = await dbHelper.exportToMap();

      expect(backup.containsKey('exercises'), true);
      expect(backup.containsKey('routines'), true);
      expect(backup.containsKey('routine_exercises'), true);
      expect(backup.containsKey('workouts'), true);
      expect(backup.containsKey('workout_sets'), true);
      expect(backup.containsKey('weight_logs'), true);

      // Verificar que o exercício customizado e o treino estão lá
      final List<dynamic> exercisesList = backup['exercises'];
      final List<dynamic> routinesList = backup['routines'];
      final List<dynamic> workoutsList = backup['workouts'];
      final List<dynamic> setsList = backup['workout_sets'];
      final List<dynamic> weightLogsList = backup['weight_logs'];

      expect(exercisesList.any((e) => e['id'] == customEx.id && e['name'] == 'Backup Custom Push'), true);
      expect(routinesList.any((r) => r['id'] == insertedRoutine.id && r['name'] == 'Backup Routine A'), true);
      expect(workoutsList.any((w) => w['id'] == insertedWorkout.id && w['name'] == 'Backup Workout 1'), true);
      expect(setsList.any((s) => s['workoutId'] == insertedWorkout.id && s['rpe'] == 8.5), true);
      expect(weightLogsList.any((l) => l['weight'] == 75.5), true);

      // 3. Modificar ou limpar o banco inserindo novos dados
      await dbHelper.insertWeightLog(99.9);
      final listBeforeRestore = await dbHelper.getWeightLogs();
      expect(listBeforeRestore.any((l) => l['weight'] == 99.9), true);

      // 4. Restaurar a partir do backup exportado
      await dbHelper.restoreFromMap(backup);

      // 5. Verificar integridade dos dados pós-restauração
      final weightLogsAfter = await dbHelper.getWeightLogs();
      // O log de 99.9 foi deletado, e o log de 75.5 voltou
      expect(weightLogsAfter.any((l) => l['weight'] == 99.9), false);
      expect(weightLogsAfter.any((l) => l['weight'] == 75.5), true);

      final exercisesAfter = await dbHelper.getExercises();
      expect(exercisesAfter.any((e) => e.name == 'Backup Custom Push'), true);

      final routinesAfter = await dbHelper.getRoutines();
      expect(routinesAfter.any((r) => r.name == 'Backup Routine A'), true);

      // 6. Testar getRawWorkoutSetsHistory
      final history = await dbHelper.getRawWorkoutSetsHistory();
      expect(history.length, 1);
      expect(history[0]['workoutName'], 'Backup Workout 1');
      expect(history[0]['exerciseName'], 'Backup Custom Push');
      expect(history[0]['weight'], 60.0);
      expect(history[0]['rpe'], 8.5);
    });
  });
}

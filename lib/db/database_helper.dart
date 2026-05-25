import 'package:meta/meta.dart';
import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../models/exercise.dart';
import '../models/workout_set.dart';
import '../models/workout.dart';
import '../models/routine.dart';

class DatabaseHelper {
  static DatabaseHelper _instance = DatabaseHelper._init();
  static DatabaseHelper get instance => _instance;
  @visibleForTesting
  static set instance(DatabaseHelper mock) => _instance = mock;

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('gymbuddy_v3.db');
    return _database!;
  }

  @visibleForTesting
  Future<void> initTestDatabase() async {
    _database = await openDatabase(
      inMemoryDatabasePath,
      version: 16,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getApplicationDocumentsDirectory();
    final path = join(dbPath.path, filePath);

    return await openDatabase(
      path,
      version: 16,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
CREATE TABLE routine_exercises (
  routineId INTEGER NOT NULL,
  exerciseId INTEGER NOT NULL,
  FOREIGN KEY (routineId) REFERENCES routines (id) ON DELETE CASCADE,
  FOREIGN KEY (exerciseId) REFERENCES exercises (id) ON DELETE CASCADE,
  PRIMARY KEY (routineId, exerciseId)
)
''');
    }
    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE routine_exercises ADD COLUMN targetSets INTEGER DEFAULT 1');
      } catch (e) {}
    }
    if (oldVersion < 4) {
      await db.execute('''
CREATE TABLE weight_logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  date TEXT NOT NULL,
  weight REAL NOT NULL
)
''');
    }
    if (oldVersion < 5) {
      final List<Map<String, dynamic>> existing = await db.query('exercises');
      final Set<String> existingNames = existing
          .map((e) => (e['name'] as String).toLowerCase().trim())
          .toSet();

      final newExercises = [
        {'name': 'Bench Press (Barbell)', 'muscleGroup': 'Chest'},
        {'name': 'Chest Fly (Machine)', 'muscleGroup': 'Chest'},
        {'name': 'Dumbbell Row', 'muscleGroup': 'Back'},
        {'name': 'Squat (Barbell)', 'muscleGroup': 'Legs'},
        {'name': 'Incline Bench Press (Barbell)', 'muscleGroup': 'Chest'},
        {'name': 'Incline Dumbbell Press', 'muscleGroup': 'Chest'},
        {'name': 'Dumbbell Bench Press', 'muscleGroup': 'Chest'},
        {'name': 'Cable Crossover', 'muscleGroup': 'Chest'},
        {'name': 'Push-Up', 'muscleGroup': 'Chest'},
        {'name': 'Pull-Up', 'muscleGroup': 'Back'},
        {'name': 'Lat Pulldown (Cable)', 'muscleGroup': 'Back'},
        {'name': 'Barbell Row', 'muscleGroup': 'Back'},
        {'name': 'Seated Cable Row', 'muscleGroup': 'Back'},
        {'name': 'Deadlift (Barbell)', 'muscleGroup': 'Back'},
        {'name': 'Overhead Press (Barbell)', 'muscleGroup': 'Shoulders'},
        {'name': 'Dumbbell Shoulder Press', 'muscleGroup': 'Shoulders'},
        {'name': 'Lateral Raise (Dumbbell)', 'muscleGroup': 'Shoulders'},
        {'name': 'Front Raise (Dumbbell)', 'muscleGroup': 'Shoulders'},
        {'name': 'Rear Delt Fly (Dumbbell)', 'muscleGroup': 'Shoulders'},
        {'name': 'Bicep Curl (Barbell)', 'muscleGroup': 'Biceps'},
        {'name': 'Bicep Curl (Dumbbell)', 'muscleGroup': 'Biceps'},
        {'name': 'Hammer Curl (Dumbbell)', 'muscleGroup': 'Biceps'},
        {'name': 'Preacher Curl (Barbell)', 'muscleGroup': 'Biceps'},
        {'name': 'Tricep Pushdown (Cable)', 'muscleGroup': 'Triceps'},
        {'name': 'Overhead Tricep Extension', 'muscleGroup': 'Triceps'},
        {'name': 'Skull Crusher (Barbell)', 'muscleGroup': 'Triceps'},
        {'name': 'Leg Press', 'muscleGroup': 'Legs'},
        {'name': 'Leg Extension (Machine)', 'muscleGroup': 'Legs'},
        {'name': 'Leg Curl (Machine)', 'muscleGroup': 'Legs'},
        {'name': 'Lunge (Dumbbell)', 'muscleGroup': 'Legs'},
        {'name': 'Romanian Deadlift (Barbell)', 'muscleGroup': 'Legs'},
        {'name': 'Standing Calf Raise', 'muscleGroup': 'Legs'},
        {'name': 'Crunch', 'muscleGroup': 'Core'},
        {'name': 'Plank', 'muscleGroup': 'Core'},
        {'name': 'Hanging Leg Raise', 'muscleGroup': 'Core'},
      ];

      for (var ex in newExercises) {
        if (!existingNames.contains(ex['name']!.toLowerCase().trim())) {
          await db.insert('exercises', ex);
        }
      }
    }
    if (oldVersion < 6) {
      await db.update('exercises', {'muscleGroup': 'Quadriceps'}, where: 'name = ?', whereArgs: ['Squat (Barbell)']);
      await db.update('exercises', {'muscleGroup': 'Quadriceps'}, where: 'name = ?', whereArgs: ['Leg Press']);
      await db.update('exercises', {'muscleGroup': 'Quadriceps'}, where: 'name = ?', whereArgs: ['Leg Extension (Machine)']);
      await db.update('exercises', {'muscleGroup': 'Hamstrings'}, where: 'name = ?', whereArgs: ['Leg Curl (Machine)']);
      await db.update('exercises', {'muscleGroup': 'Glutes'}, where: 'name = ?', whereArgs: ['Lunge (Dumbbell)']);
      await db.update('exercises', {'muscleGroup': 'Hamstrings'}, where: 'name = ?', whereArgs: ['Romanian Deadlift (Barbell)']);
      await db.update('exercises', {'muscleGroup': 'Calves'}, where: 'name = ?', whereArgs: ['Standing Calf Raise']);

      final List<Map<String, dynamic>> existing = await db.query('exercises', where: 'name = ?', whereArgs: ['Hip Adductor (Machine)']);
      if (existing.isEmpty) {
        await db.insert('exercises', {'name': 'Hip Adductor (Machine)', 'muscleGroup': 'Adductors'});
      }
    }
    if (oldVersion < 7) {
      try {
        await db.execute('ALTER TABLE workouts ADD COLUMN notes TEXT DEFAULT ""');
      } catch (e) {}
    }
    if (oldVersion < 8) {
      try {
        await db.execute('ALTER TABLE workouts ADD COLUMN recordsBroken INTEGER DEFAULT 0');  
      } catch (e) {}
    }
    if (oldVersion < 9) {
      try {
        await db.execute('ALTER TABLE workout_sets ADD COLUMN rpe REAL');
      } catch (e) {}
    }
    if (oldVersion < 10) {
      try {
        await db.execute('ALTER TABLE exercises ADD COLUMN restTimeSeconds INTEGER');
      } catch (e) {}
    }
    if (oldVersion < 11) {
      try {
        await db.execute('ALTER TABLE exercises ADD COLUMN notes TEXT');
      } catch (e) {}
    }
    if (oldVersion < 12) {
      try {
        await db.execute('ALTER TABLE exercises ADD COLUMN libraryId TEXT');
        await db.execute('ALTER TABLE exercises ADD COLUMN category TEXT');
        await db.execute('ALTER TABLE exercises ADD COLUMN level TEXT');
        await db.execute('ALTER TABLE exercises ADD COLUMN equipment TEXT');
        await db.execute('ALTER TABLE exercises ADD COLUMN mechanic TEXT');
        await db.execute('ALTER TABLE exercises ADD COLUMN force TEXT');
        await db.execute('ALTER TABLE exercises ADD COLUMN imagePath TEXT');
        await db.execute('ALTER TABLE exercises ADD COLUMN instructionsJson TEXT');
      } catch (e) {}
    }
    if (oldVersion < 13) {
      try {
        await db.execute('ALTER TABLE workout_sets ADD COLUMN durationSeconds INTEGER');
        await db.execute('ALTER TABLE workout_sets ADD COLUMN distance REAL');
        await db.execute('ALTER TABLE workout_sets ADD COLUMN previousDurationSeconds INTEGER');
        await db.execute('ALTER TABLE workout_sets ADD COLUMN previousDistance REAL');
      } catch (e) {}
    }
    if (oldVersion < 14) {
      try {
        await db.execute('ALTER TABLE routine_exercises ADD COLUMN superSetId TEXT');
      } catch (e) {}
    }
    if (oldVersion < 15) {
      try {
        await db.execute('ALTER TABLE workouts ADD COLUMN muscleGroups TEXT');
      } catch (e) {}
    }
    if (oldVersion < 16) {
      await db.execute('''
CREATE TABLE body_measurements (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  date TEXT NOT NULL,
  type TEXT NOT NULL,
  value REAL NOT NULL
)
''');
    }
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const doubleType = 'REAL NOT NULL';
    const boolType = 'INTEGER NOT NULL';

    await db.execute('''
CREATE TABLE exercises (
  id $idType,
  name $textType,
  muscleGroup $textType,
  restTimeSeconds INTEGER,
  notes TEXT,
  libraryId TEXT,
  category TEXT,
  level TEXT,
  equipment TEXT,
  mechanic TEXT,
  force TEXT,
  imagePath TEXT,
  instructionsJson TEXT
)
''');

    await db.execute('''
CREATE TABLE routines (
  id $idType,
  name $textType,
  description TEXT
)
''');

    await db.execute('''
CREATE TABLE routine_exercises (
  routineId $intType,
  exerciseId $intType,
  targetSets INTEGER DEFAULT 1,
  superSetId TEXT,
  FOREIGN KEY (routineId) REFERENCES routines (id) ON DELETE CASCADE,
  FOREIGN KEY (exerciseId) REFERENCES exercises (id) ON DELETE CASCADE,
  PRIMARY KEY (routineId, exerciseId)
)
''');

    await db.execute('''
CREATE TABLE workouts (
  id $idType,
  name $textType,
  startTime $textType,
  endTime TEXT,
  durationSeconds $intType,
  totalVolume $doubleType,
  notes TEXT,
  recordsBroken INTEGER
)
''');

    await db.execute('''
CREATE TABLE workout_sets (
  id $idType,
  workoutId INTEGER,
  exerciseId $intType,
  reps $intType,
  weight $doubleType,
  durationSeconds INTEGER,
  distance REAL,
  setType $textType,
  isCompleted $boolType,
  previousReps INTEGER,
  previousWeight REAL,
  previousDurationSeconds INTEGER,
  previousDistance REAL,
  rpe REAL,
  superSetId TEXT,
  FOREIGN KEY (exerciseId) REFERENCES exercises (id) ON DELETE CASCADE,
  FOREIGN KEY (workoutId) REFERENCES workouts (id) ON DELETE CASCADE
)
''');

    await db.execute('''
      INSERT INTO exercises (name, muscleGroup) VALUES
      ('Bench Press (Barbell)', 'Chest'),
      ('Chest Fly (Machine)', 'Chest'),
      ('Dumbbell Row', 'Back'),
      ('Squat (Barbell)', 'Quadriceps'),
      ('Incline Bench Press (Barbell)', 'Chest'),
      ('Incline Dumbbell Press', 'Chest'),
      ('Dumbbell Bench Press', 'Chest'),
      ('Cable Crossover', 'Chest'),
      ('Push-Up', 'Chest'),
      ('Pull-Up', 'Back'),
      ('Lat Pulldown (Cable)', 'Back'),
      ('Barbell Row', 'Back'),
      ('Seated Cable Row', 'Back'),
      ('Deadlift (Barbell)', 'Back'),
      ('Overhead Press (Barbell)', 'Shoulders'),
      ('Dumbbell Shoulder Press', 'Shoulders'),
      ('Lateral Raise (Dumbbell)', 'Shoulders'),
      ('Front Raise (Dumbbell)', 'Shoulders'),
      ('Rear Delt Fly (Dumbbell)', 'Shoulders'),
      ('Bicep Curl (Barbell)', 'Biceps'),
      ('Bicep Curl (Dumbbell)', 'Biceps'),
      ('Hammer Curl (Dumbbell)', 'Biceps'),
      ('Preacher Curl (Barbell)', 'Biceps'),
      ('Tricep Pushdown (Cable)', 'Triceps'),
      ('Overhead Tricep Extension', 'Triceps'),
      ('Skull Crusher (Barbell)', 'Triceps'),
      ('Leg Press', 'Quadriceps'),
      ('Leg Extension (Machine)', 'Quadriceps'),
      ('Leg Curl (Machine)', 'Hamstrings'),
      ('Lunge (Dumbbell)', 'Glutes'),
      ('Romanian Deadlift (Barbell)', 'Hamstrings'),
      ('Standing Calf Raise', 'Calves'),
      ('Hip Adductor (Machine)', 'Adductors'),
      ('Crunch', 'Core'),
      ('Plank', 'Core'),
      ('Hanging Leg Raise', 'Core')
    ''');

    await db.execute('''
CREATE TABLE weight_logs (
  id $idType,
  date $textType,
  weight $doubleType
)
''');

    await db.execute('''
CREATE TABLE body_measurements (
  id $idType,
  date $textType,
  type $textType,
  value $doubleType
)
''');
  }

  // --- CRUD Exercises ---
  Future<Exercise> insertExercise(Exercise exercise) async {
    final db = await instance.database;
    final id = await db.insert('exercises', exercise.toMap());
    return Exercise(
      id: id,
      name: exercise.name,
      muscleGroup: exercise.muscleGroup,
      restTimeSeconds: exercise.restTimeSeconds,
      notes: exercise.notes,
      libraryId: exercise.libraryId,
      category: exercise.category,
      level: exercise.level,
      equipment: exercise.equipment,
      mechanic: exercise.mechanic,
      force: exercise.force,
      imagePath: exercise.imagePath,
      instructionsJson: exercise.instructionsJson,
    );
  }

  Future<int> updateExercise(Exercise exercise) async {
    final db = await instance.database;
    return await db.update(
      'exercises',
      exercise.toMap(),
      where: 'id = ?',
      whereArgs: [exercise.id],
    );
  }

  Future<List<Exercise>> getExercises() async {
    final db = await instance.database;
    final result = await db.query('exercises', orderBy: 'name ASC');
    return result.map((json) => Exercise.fromMap(json)).toList();
  }

  Future<int> deleteExercise(int id) async {
    final db = await instance.database;
    return await db.delete('exercises', where: 'id = ?', whereArgs: [id]);
  }

  // --- CRUD Routines ---
  Future<Routine> insertRoutine(Routine routine, Map<int, int> exerciseSets, {Map<int, String?>? exerciseSuperSets}) async {
    final db = await instance.database;
    return await db.transaction((txn) async {
      final id = await txn.insert('routines', routine.toMap());

      for (var entry in exerciseSets.entries) {
        await txn.insert('routine_exercises', {
          'routineId': id,
          'exerciseId': entry.key,
          'targetSets': entry.value,
          'superSetId': exerciseSuperSets?[entry.key],
        });
      }

      return Routine(id: id, name: routine.name, description: routine.description);
    });
  }

  Future<void> updateRoutine(Routine routine, Map<int, int> exerciseSets, {Map<int, String?>? exerciseSuperSets}) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.update(
        'routines',
        routine.toMap(),
        where: 'id = ?',
        whereArgs: [routine.id],
      );
      
      await txn.delete(
        'routine_exercises',
        where: 'routineId = ?',
        whereArgs: [routine.id],
      );
      
      for (var entry in exerciseSets.entries) {
        await txn.insert('routine_exercises', {
          'routineId': routine.id,
          'exerciseId': entry.key,
          'targetSets': entry.value,
          'superSetId': exerciseSuperSets?[entry.key],
        });
      }
    });
  }

  Future<List<Routine>> getRoutines() async {
    final db = await instance.database;
    final result = await db.query('routines', orderBy: 'id DESC');
    return result.map((json) => Routine.fromMap(json)).toList();
  }

  Future<List<Exercise>> getExercisesForRoutine(int routineId) async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT e.* FROM exercises e
      INNER JOIN routine_exercises re ON e.id = re.exerciseId
      WHERE re.routineId = ?
    ''', [routineId]);
    return result.map((json) => Exercise.fromMap(json)).toList();
  }

  Future<Map<int, int>> getRoutineExerciseSets(int routineId) async {
    final db = await instance.database;
    final result = await db.query(
      'routine_exercises',
      columns: ['exerciseId', 'targetSets'],
      where: 'routineId = ?',
      whereArgs: [routineId],
    );

    Map<int, int> exerciseSets = {};
    for (var row in result) {
      exerciseSets[row['exerciseId'] as int] = (row['targetSets'] as int?) ?? 1;
    }
    return exerciseSets;
  }

  Future<Map<int, String?>> getRoutineExerciseSuperSets(int routineId) async {
    final db = await instance.database;
    final result = await db.query(
      'routine_exercises',
      columns: ['exerciseId', 'superSetId'],
      where: 'routineId = ?',
      whereArgs: [routineId],
    );

    Map<int, String?> exerciseSuperSets = {};
    for (var row in result) {
      exerciseSuperSets[row['exerciseId'] as int] = row['superSetId'] as String?;
    }
    return exerciseSuperSets;
  }

  Future<void> updateRoutineExercises(int routineId, Map<int, int> exerciseSets) async {      
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.delete('routine_exercises', where: 'routineId = ?', whereArgs: [routineId]);  

      for (var entry in exerciseSets.entries) {
        await txn.insert('routine_exercises', {
          'routineId': routineId,
          'exerciseId': entry.key,
          'targetSets': entry.value,
        });
      }
    });
  }

  Future<int> deleteRoutine(int id) async {
    final db = await instance.database;
    return await db.delete('routines', where: 'id = ?', whereArgs: [id]);
  }

  // --- CRUD Workouts ---
  Future<Workout> insertWorkout(Workout workout) async {
    final db = await instance.database;
    final id = await db.insert('workouts', workout.toMap());
    return Workout(
      id: id,
      name: workout.name,
      startTime: workout.startTime,
      endTime: workout.endTime,
      durationSeconds: workout.durationSeconds,
      totalVolume: workout.totalVolume,
      notes: workout.notes,
      recordsBroken: workout.recordsBroken,
    );
  }

  Future<int> updateWorkout(Workout workout) async {
    final db = await instance.database;
    return db.update(
      'workouts',
      workout.toMap(),
      where: 'id = ?',
      whereArgs: [workout.id],
    );
  }

  Future<int> deleteWorkout(int id) async {
    final db = await instance.database;
    return await db.delete('workouts', where: 'id = ?', whereArgs: [id]);
  }

  // --- Summary Metrics ---
  Future<int> getTotalWorkoutsCount() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM workouts');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getWorkoutsLast7Days() async {
    final db = await instance.database;
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7)).toIso8601String();  
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM workouts WHERE startTime >= ?',
      [sevenDaysAgo]
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<Workout>> getAllWorkoutsOrderedByDate() async {
    final db = await instance.database;
    final result = await db.query('workouts', orderBy: 'startTime ASC');
    return result.map((json) => Workout.fromMap(json)).toList();
  }

  // --- CRUD Workout Sets ---
  Future<WorkoutSet> insertWorkoutSet(WorkoutSet workoutSet) async {
    final db = await instance.database;
    final id = await db.insert('workout_sets', workoutSet.toMap());
    return WorkoutSet(
      id: id,
      workoutId: workoutSet.workoutId,
      exerciseId: workoutSet.exerciseId,
      reps: workoutSet.reps,
      weight: workoutSet.weight,
      durationSeconds: workoutSet.durationSeconds,
      distance: workoutSet.distance,
      setType: workoutSet.setType,
      isCompleted: workoutSet.isCompleted,
      previousReps: workoutSet.previousReps,
      previousWeight: workoutSet.previousWeight,
      previousDurationSeconds: workoutSet.previousDurationSeconds,
      previousDistance: workoutSet.previousDistance,
      rpe: workoutSet.rpe,
      superSetId: workoutSet.superSetId,
    );
  }

  Future<int> updateWorkoutSet(WorkoutSet workoutSet) async {
    final db = await instance.database;
    return db.update(
      'workout_sets',
      workoutSet.toMap(),
      where: 'id = ?',
      whereArgs: [workoutSet.id],
    );
  }

  Future<double> getMaxWeightForExercise(int exerciseId) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT MAX(weight) as max_weight FROM workout_sets WHERE exerciseId = ? AND isCompleted = 1',
      [exerciseId],
    );

    if (result.isNotEmpty && result.first['max_weight'] != null) {
      return (result.first['max_weight'] as num).toDouble();
    }
    return 0.0;
  }

  Future<double> getMaxVolumeForExercise(int exerciseId) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT MAX(weight * reps) as max_vol FROM workout_sets WHERE exerciseId = ? AND isCompleted = 1',
      [exerciseId],
    );

    if (result.isNotEmpty && result.first['max_vol'] != null) {
      return (result.first['max_vol'] as num).toDouble();
    }
    return 0.0;
  }

  Future<List<WorkoutSet>> getLastWorkoutSetsForExercise(int exerciseId) async {
    final db = await instance.database;
    final lastWorkoutQuery = await db.rawQuery(
      'SELECT workoutId FROM workout_sets WHERE exerciseId = ? AND isCompleted = 1 ORDER BY id DESC LIMIT 1',
      [exerciseId]
    );

    if (lastWorkoutQuery.isEmpty || lastWorkoutQuery.first['workoutId'] == null) {
      return [];
    }

    int lastWorkoutId = lastWorkoutQuery.first['workoutId'] as int;

    final result = await db.query(
      'workout_sets',
      where: 'workoutId = ? AND exerciseId = ? AND isCompleted = 1',
      whereArgs: [lastWorkoutId, exerciseId],
      orderBy: 'id ASC',
    );

    return result.map((json) => WorkoutSet.fromMap(json)).toList();
  }

  Future<List<WorkoutSet>> getSetsForWorkout(int workoutId) async {
    final db = await instance.database;
    final result = await db.query(
      'workout_sets',
      where: 'workoutId = ?',
      whereArgs: [workoutId],
    );
    return result.map((json) => WorkoutSet.fromMap(json)).toList();
  }

  Future<int> deleteWorkoutSet(int id) async {
    final db = await instance.database;
    return await db.delete('workout_sets', where: 'id = ?', whereArgs: [id]);
  }

  // --- Analytics & Progress Tracking ---
  Future<Map<String, int>> getMuscleGroupDistribution(int days) async {
    final db = await instance.database;
    final dateLimit = DateTime.now().subtract(Duration(days: days)).toIso8601String();        

    final result = await db.rawQuery('''
      SELECT e.muscleGroup, COUNT(ws.id) as set_count
      FROM workout_sets ws
      INNER JOIN workouts w ON ws.workoutId = w.id
      INNER JOIN exercises e ON ws.exerciseId = e.id
      WHERE ws.isCompleted = 1 AND w.startTime >= ?
      GROUP BY e.muscleGroup
    ''', [dateLimit]);

    Map<String, int> distribution = {};
    for (var row in result) {
      if (row['muscleGroup'] != null) {
        distribution[row['muscleGroup'] as String] = (row['set_count'] as int?) ?? 0;
      }
    }
    return distribution;
  }

  Future<List<Map<String, dynamic>>> getExercisePerformanceHistory(int exerciseId) async {    
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT w.startTime, MAX(ws.weight) as max_weight, MAX(ws.weight * ws.reps) as max_volume
      FROM workout_sets ws
      INNER JOIN workouts w ON ws.workoutId = w.id
      WHERE ws.exerciseId = ? AND ws.isCompleted = 1
      GROUP BY w.id
      ORDER BY w.startTime ASC
    ''', [exerciseId]);
    return result;
  }

  Future<List<Map<String, dynamic>>> getCompletedSetsWithWorkoutInfo(int exerciseId) async {  
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT ws.*, w.startTime, w.name as workoutName, w.id as workoutId
      FROM workout_sets ws
      INNER JOIN workouts w ON ws.workoutId = w.id
      WHERE ws.exerciseId = ? AND ws.isCompleted = 1
      ORDER BY w.startTime DESC, ws.id ASC
    ''', [exerciseId]);
  }

  Future<Map<String, int>> getWorkoutConsistencyStats() async {
    final db = await instance.database;

    final totalResult = await db.rawQuery('SELECT COUNT(*) as count FROM workouts');
    int total = (totalResult.first['count'] as int?) ?? 0;

    final startOfMonth = DateTime(DateTime.now().year, DateTime.now().month, 1).toIso8601String();
    final monthResult = await db.rawQuery('SELECT COUNT(*) as count FROM workouts WHERE startTime >= ?', [startOfMonth]);
    int thisMonth = (monthResult.first['count'] as int?) ?? 0;

    return {
      'total': total,
      'thisMonth': thisMonth,
    };
  }

  Future<List<String>> getWorkoutDatesLast7Days() async {
    final db = await instance.database;
    final now = DateTime.now();
    final sevenDaysAgo = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6)).toIso8601String();
    final result = await db.rawQuery(
      'SELECT startTime FROM workouts WHERE startTime >= ?',
      [sevenDaysAgo]
    );
    return result.map((row) => row['startTime'] as String).toList();
  }

  Future<List<String>> getWorkoutDatesCurrentMonth() async {
    final db = await instance.database;
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1).toIso8601String();
    final result = await db.rawQuery(
      'SELECT startTime FROM workouts WHERE startTime >= ?',
      [startOfMonth]
    );
    return result.map((row) => row['startTime'] as String).toList();
  }

  // --- Weight Logs ---
  Future<int> insertWeightLog(double weight) async {
    final db = await instance.database;
    return await db.insert('weight_logs', {
      'date': DateTime.now().toIso8601String(),
      'weight': weight,
    });
  }

  Future<List<Map<String, dynamic>>> getWeightLogs() async {
    final db = await instance.database;
    return await db.query('weight_logs', orderBy: 'date DESC');
  }

  Future<int> deleteWeightLog(int id) async {
    final db = await instance.database;
    return await db.delete('weight_logs', where: 'id = ?', whereArgs: [id]);
  }

  // --- Body Measurements ---
  Future<int> insertBodyMeasurement(String type, double value) async {
    final db = await instance.database;
    return await db.insert('body_measurements', {
      'date': DateTime.now().toIso8601String(),
      'type': type,
      'value': value,
    });
  }

  Future<List<Map<String, dynamic>>> getBodyMeasurements() async {
    final db = await instance.database;
    return await db.query('body_measurements', orderBy: 'date ASC');
  }

  Future<int> deleteBodyMeasurement(int id) async {
    final db = await instance.database;
    return await db.delete('body_measurements', where: 'id = ?', whereArgs: [id]);
  }

  // --- Backup and Restore ---
  Future<Map<String, dynamic>> exportToMap() async {
    final db = await instance.database;
    final exercises = await db.query('exercises');
    final routines = await db.query('routines');
    final routineExercises = await db.query('routine_exercises');
    final workouts = await db.query('workouts');
    final workoutSets = await db.query('workout_sets');
    final weightLogs = await db.query('weight_logs');
    final bodyMeasurements = await db.query('body_measurements');

    return {
      'exercises': exercises,
      'routines': routines,
      'routine_exercises': routineExercises,
      'workouts': workouts,
      'workout_sets': workoutSets,
      'weight_logs': weightLogs,
      'body_measurements': bodyMeasurements,
    };
  }

  Future<void> restoreFromMap(Map<String, dynamic> data) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      // Deletar em ordem inversa de dependência para respeitar foreign keys
      await txn.delete('workout_sets');
      await txn.delete('routine_exercises');
      await txn.delete('workouts');
      await txn.delete('routines');
      await txn.delete('weight_logs');
      await txn.delete('body_measurements');
      await txn.delete('exercises');

      List<dynamic> getList(String key) => data[key] as List<dynamic>? ?? [];

      // Inserir respeitando a ordem de dependências
      for (var row in getList('exercises')) {
        await txn.insert('exercises', Map<String, dynamic>.from(row));
      }
      for (var row in getList('routines')) {
        await txn.insert('routines', Map<String, dynamic>.from(row));
      }
      for (var row in getList('workouts')) {
        await txn.insert('workouts', Map<String, dynamic>.from(row));
      }
      for (var row in getList('routine_exercises')) {
        await txn.insert('routine_exercises', Map<String, dynamic>.from(row));
      }
      for (var row in getList('workout_sets')) {
        await txn.insert('workout_sets', Map<String, dynamic>.from(row));
      }
      for (var row in getList('weight_logs')) {
        await txn.insert('weight_logs', Map<String, dynamic>.from(row));
      }
      for (var row in getList('body_measurements')) {
        await txn.insert('body_measurements', Map<String, dynamic>.from(row));
      }
    });
  }

  Future<List<Map<String, dynamic>>> getRawWorkoutSetsHistory() async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT 
        w.startTime AS date,
        w.name AS workoutName,
        e.name AS exerciseName,
        ws.setType,
        ws.weight,
        ws.reps,
        ws.rpe
      FROM workout_sets ws
      JOIN workouts w ON ws.workoutId = w.id
      JOIN exercises e ON ws.exerciseId = e.id
      ORDER BY w.startTime DESC, ws.id ASC
    ''');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
    _database = null;
  }
}

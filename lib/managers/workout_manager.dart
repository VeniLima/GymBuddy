import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/exercise.dart';
import '../models/workout.dart';
import '../models/workout_set.dart';
import '../db/database_helper.dart';
import 'workout_foreground_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WorkoutResult {
  final Workout workout;
  final List<WorkoutSet> sets;
  final int recordsBroken;
  final bool routineChanged;

  WorkoutResult(this.workout, this.sets, this.recordsBroken, this.routineChanged);
}

class WorkoutManager extends ChangeNotifier {
  static final WorkoutManager instance = WorkoutManager._();
  WorkoutManager._();

  bool isActive = false;
  bool isMinimized = false;

  Workout? currentWorkout;
  int? routineId;
  String workoutName = '';
  String notes = '';
  
  List<Exercise> availableExercises = [];
  final Map<Exercise, List<WorkoutSet>> workoutExercises = {};
  Map<int, int>? routineOriginalSets;

  int secondsElapsed = 0;
  /// Ticks every second independently of [notifyListeners], so widgets that
  /// only need the elapsed time (e.g. the digital clock) can listen to this
  /// instead of rebuilding on every ChangeNotifier notification.
  final ValueNotifier<int> secondsElapsedNotifier = ValueNotifier(0);
  Timer? _workoutTimer;

  final Map<int, int> exerciseRestTimes = {};
  final Map<int, double> exerciseHistoricalMax = {};
  final Map<int, double> exerciseHistoricalMaxVolume = {};
  final Map<int, List<WorkoutSet>> exercisePreviousSets = {};
  
  Timer? _restTimer;
  Timer? _autoDismissTimer;
  int restSecondsRemaining = 0;
  /// Same idea as [secondsElapsedNotifier]: the per-second rest countdown
  /// updates this instead of calling [notifyListeners], so resting doesn't
  /// rebuild the whole screen every second.
  final ValueNotifier<int> restSecondsRemainingNotifier = ValueNotifier(0);
  bool isResting = false;
  final AudioPlayer audioPlayer = AudioPlayer();

  Map<int, String?> _routineSuperSets = {};

  // --- Draft autosave ---
  //
  // The active workout used to live only in memory: nothing was written to
  // the database until finishWorkout() at the very end. If Android killed
  // the app process in the background (routine — the "workout in progress"
  // notification is a plain notification, not a real foreground service,
  // so it doesn't prevent this), the whole workout was lost with no way to
  // recover it, even though the notification kept showing as if nothing
  // had happened. This periodically snapshots the in-progress workout to
  // SharedPreferences so it can be restored on the next app launch.
  static const String _draftPrefsKey = 'active_workout_draft_v1';

  Future<void> _saveDraft() async {
    if (!isActive || currentWorkout == null) return;
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'workoutName': workoutName,
      'notes': notes,
      'routineId': routineId,
      'startTime': currentWorkout!.startTime.toIso8601String(),
      'secondsElapsed': secondsElapsed,
      'exerciseRestTimes': exerciseRestTimes.map((id, seconds) => MapEntry(id.toString(), seconds)),
      'exercises': workoutExercises.entries
          .map((entry) => {
                'exerciseId': entry.key.id,
                'sets': entry.value.map((s) => s.toMap()).toList(),
              })
          .toList(),
    };
    await prefs.setString(_draftPrefsKey, jsonEncode(data));
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftPrefsKey);
  }

  /// Call once at app startup, before anything reads [isActive]. Returns
  /// true if a draft was found and restored.
  Future<bool> restoreDraftIfAny() async {
    if (isActive) return false;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_draftPrefsKey);
    if (raw == null) return false;

    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final allExercises = await DatabaseHelper.instance.getExercises();
      final exercisesById = {for (var e in allExercises) e.id: e};

      final Map<Exercise, List<WorkoutSet>> restoredExercises = {};
      for (final entry in (data['exercises'] as List<dynamic>)) {
        final exercise = exercisesById[entry['exerciseId']];
        if (exercise == null) continue; // exercise was deleted meanwhile
        restoredExercises[exercise] = (entry['sets'] as List<dynamic>)
            .map((m) => WorkoutSet.fromMap(Map<String, dynamic>.from(m)))
            .toList();
      }

      if (restoredExercises.isEmpty) {
        await _clearDraft();
        return false;
      }

      workoutName = data['workoutName'] as String? ?? '';
      notes = data['notes'] as String? ?? '';
      routineId = data['routineId'] as int?;
      currentWorkout = Workout(name: workoutName, startTime: DateTime.parse(data['startTime'] as String));
      secondsElapsed = data['secondsElapsed'] as int? ?? 0;
      secondsElapsedNotifier.value = secondsElapsed;
      exerciseRestTimes
        ..clear()
        ..addAll((data['exerciseRestTimes'] as Map<String, dynamic>)
            .map((id, seconds) => MapEntry(int.parse(id), seconds as int)));
      workoutExercises
        ..clear()
        ..addAll(restoredExercises);
      routineOriginalSets = null;
      _routineSuperSets = {};
      isActive = true;
      isMinimized = true; // land on the resume banner, not straight into the screen
      isResting = false;

      _workoutTimer?.cancel();
      _workoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        secondsElapsed++;
        secondsElapsedNotifier.value = secondsElapsed;
        if (secondsElapsed % 10 == 0) _saveDraft();
      });

      notifyListeners();
      await WorkoutForegroundService.requestPermissions();
      await WorkoutForegroundService.start(title: 'Treino em Andamento', body: workoutName);
      return true;
    } catch (e) {
      debugPrint('WorkoutManager: failed to restore workout draft: $e');
      await _clearDraft();
      return false;
    }
  }

  Future<void> startWorkout(String name, List<Exercise> initialExercises, {int? rId}) async {
    if (isActive) return;

    isActive = true;
    isMinimized = false;
    workoutName = name;
    routineId = rId;
    notes = '';
    currentWorkout = Workout(name: name, startTime: DateTime.now());
    
    workoutExercises.clear();
    exerciseRestTimes.clear();
    secondsElapsed = 0;
    secondsElapsedNotifier.value = 0;
    restSecondsRemaining = 0;
    restSecondsRemainingNotifier.value = 0;
    isResting = false;
    _restTimer?.cancel();

    if (routineId != null) {
      routineOriginalSets = await DatabaseHelper.instance.getRoutineExerciseSets(routineId!);
      _routineSuperSets = await DatabaseHelper.instance.getRoutineExerciseSuperSets(routineId!);
    } else {
      routineOriginalSets = null;
      _routineSuperSets = {};
    }

    for (var exercise in initialExercises) {
      int targetSets = routineOriginalSets?[exercise.id!] ?? 1;
      bool isCardio = exercise.category?.toLowerCase() == 'cardio';
      String? superSetId = _routineSuperSets[exercise.id!];

      workoutExercises[exercise] = List.generate(
        targetSets, 
        (_) => WorkoutSet(
          exerciseId: exercise.id!, 
          reps: isCardio ? 1 : 0, 
          weight: 0,
          durationSeconds: isCardio ? 600 : null,
          superSetId: superSetId,
        )
      );
      exerciseRestTimes[exercise.id!] = exercise.restTimeSeconds ?? exercise.getAutoRestSeconds();
    }

    await loadExercises();

    _workoutTimer?.cancel();
    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      secondsElapsed++;
      secondsElapsedNotifier.value = secondsElapsed;
      if (secondsElapsed % 10 == 0) _saveDraft();
    });

    notifyListeners();
    await _saveDraft();
    await WorkoutForegroundService.requestPermissions();
    await WorkoutForegroundService.start(title: 'Treino em Andamento', body: workoutName);
  }

  Future<void> loadExercises() async {
    final exercises = await DatabaseHelper.instance.getExercises();
    final maxStats = await DatabaseHelper.instance.getExerciseMaxStats();
    final lastSets = await DatabaseHelper.instance.getLastWorkoutSetsForAllExercises();
    for (var ex in exercises) {
      exerciseHistoricalMax[ex.id!] = maxStats[ex.id!]?['maxWeight'] ?? 0.0;
      exerciseHistoricalMaxVolume[ex.id!] = maxStats[ex.id!]?['maxVolume'] ?? 0.0;
      exercisePreviousSets[ex.id!] = lastSets[ex.id!] ?? [];
    }
    availableExercises = exercises;
    notifyListeners();
  }

  void minimize() {
    isMinimized = true;
    notifyListeners();
  }

  void maximize() {
    isMinimized = false;
    notifyListeners();
  }

  void addExerciseToWorkout(Exercise exercise) {
    if (!workoutExercises.containsKey(exercise)) {
      bool isCardio = exercise.category?.toLowerCase() == 'cardio';
      workoutExercises[exercise] = [
        WorkoutSet(
          exerciseId: exercise.id!, 
          reps: isCardio ? 1 : 0, 
          weight: 0,
          durationSeconds: isCardio ? 600 : null,
          superSetId: _routineSuperSets[exercise.id!],
        )
      ];
      exerciseRestTimes[exercise.id!] = exercise.restTimeSeconds ?? exercise.getAutoRestSeconds();
      notifyListeners();
      _saveDraft();
    }
  }

  void addSet(Exercise exercise) {
    if (workoutExercises.containsKey(exercise)) {
      bool isCardio = exercise.category?.toLowerCase() == 'cardio';
      workoutExercises[exercise]!.add(
        WorkoutSet(
          exerciseId: exercise.id!,
          reps: isCardio ? 1 : 0,
          weight: 0,
          durationSeconds: isCardio ? 600 : null,
          superSetId: _routineSuperSets[exercise.id!],
        )
      );
      notifyListeners();
      _saveDraft();
    }
  }

  void addFeederSets(Exercise exercise, double targetWeight) {
    if (workoutExercises.containsKey(exercise)) {
      double w1 = (targetWeight * 0.50).roundToDouble();
      double w2 = (targetWeight * 0.80).roundToDouble();
      double w3 = (targetWeight * 0.90).roundToDouble();

      final feeder1 = WorkoutSet(
        exerciseId: exercise.id!,
        reps: 8,
        weight: w1,
        setType: 'Warmup',
        superSetId: _routineSuperSets[exercise.id!],
      );

      final feeder2 = WorkoutSet(
        exerciseId: exercise.id!,
        reps: 5,
        weight: w2,
        setType: 'Warmup',
        superSetId: _routineSuperSets[exercise.id!],
      );

      final feeder3 = WorkoutSet(
        exerciseId: exercise.id!,
        reps: 1,
        weight: w3,
        setType: 'Warmup',
        superSetId: _routineSuperSets[exercise.id!],
      );

      // Insert them at the top of the set list
      workoutExercises[exercise]!.insertAll(0, [feeder1, feeder2, feeder3]);

      notifyListeners();
      _saveDraft();
    }
  }

  void removeSet(Exercise exercise, int index) {
    if (workoutExercises.containsKey(exercise) && workoutExercises[exercise]!.length > index) {
      workoutExercises[exercise]!.removeAt(index);
      notifyListeners();
      _saveDraft();
    }
  }
  
  void updateSet(Exercise exercise, int index, WorkoutSet newSet) {
    if (workoutExercises.containsKey(exercise)) {
      workoutExercises[exercise]![index] = newSet;
    }
  }
  
  void toggleSetCompletion(Exercise exercise, int index) {
    if (workoutExercises.containsKey(exercise)) {
      final currentSet = workoutExercises[exercise]![index];
      final newStatus = !currentSet.isCompleted;
      
      workoutExercises[exercise]![index] = WorkoutSet(
        id: currentSet.id,
        workoutId: currentWorkout?.id, // Current workout ID might be null before finish
        exerciseId: currentSet.exerciseId,
        reps: currentSet.reps,
        weight: currentSet.weight,
        durationSeconds: currentSet.durationSeconds,
        distance: currentSet.distance,
        setType: currentSet.setType,
        previousReps: currentSet.previousReps,
        previousWeight: currentSet.previousWeight,
        previousDurationSeconds: currentSet.previousDurationSeconds,
        previousDistance: currentSet.previousDistance,
        isCompleted: newStatus,
        rpe: currentSet.rpe,
        superSetId: currentSet.superSetId,
      );
      
      if (newStatus) {
        bool shouldStartRest = true;
        
        // Superset logic
        if (currentSet.superSetId != null) {
          final allExercises = workoutExercises.keys.toList();
          final exerciseIdx = allExercises.indexOf(exercise);
          
          if (exerciseIdx < allExercises.length - 1) {
            final nextEx = allExercises[exerciseIdx + 1];
            final nextExSets = workoutExercises[nextEx]!;
            
            if (index < nextExSets.length && nextExSets[index].superSetId == currentSet.superSetId) {
              shouldStartRest = false;
            }
          }
        }

        if (shouldStartRest) {
          bool isNextSetDrop = false;
          if (index + 1 < workoutExercises[exercise]!.length) {
            isNextSetDrop = workoutExercises[exercise]![index + 1].setType == 'Drop';
          }
          if (!isNextSetDrop) {
            SharedPreferences.getInstance().then((prefs) {
              final autoRest = prefs.getBool('user_enable_rest_timer') ?? true;
              if (autoRest) {
                final seconds = exerciseRestTimes[exercise.id!] ?? 90;
                startRestTimer(seconds, exerciseName: exercise.translatedName);
              }
            });
          }
        }
        _checkPRs(exercise, currentSet);
      }
      notifyListeners();
      _saveDraft();
    }
  }

  void _checkPRs(Exercise exercise, WorkoutSet set) {
    if (exercise.category?.toLowerCase() == 'cardio') return;

    double currentSetWeight = set.weight;
    double currentSetVolume = set.weight * set.reps;
    
    bool brokeWeight = currentSetWeight > 0 && currentSetWeight > (exerciseHistoricalMax[exercise.id!] ?? 0.0);
    bool brokeVolume = currentSetVolume > 0 && currentSetVolume > (exerciseHistoricalMaxVolume[exercise.id!] ?? 0.0);
    
    if (brokeWeight || brokeVolume) {
      if (brokeWeight) exerciseHistoricalMax[exercise.id!] = currentSetWeight;
      if (brokeVolume) exerciseHistoricalMaxVolume[exercise.id!] = currentSetVolume;
    }
  }

  void startRestTimer(int seconds, {String? exerciseName}) {
    isResting = true;
    restSecondsRemaining = seconds;
    restSecondsRemainingNotifier.value = seconds;
    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (restSecondsRemaining > 0) {
        restSecondsRemaining--;
        restSecondsRemainingNotifier.value = restSecondsRemaining;
        _updateWorkoutNotification(restTime: restSecondsRemaining);
      } else {
        _playBeep();
        timer.cancel();
        _startAutoDismissTimer();
      }
    });
    notifyListeners();
  }

  void addRestTime(int seconds) {
    restSecondsRemaining += seconds;
    restSecondsRemainingNotifier.value = restSecondsRemaining;
    notifyListeners();
  }

  void subtractRestTime(int seconds) {
    if (restSecondsRemaining > seconds) {
      restSecondsRemaining -= seconds;
    } else {
      restSecondsRemaining = 0;
    }
    restSecondsRemainingNotifier.value = restSecondsRemaining;
    notifyListeners();
  }

  void _startAutoDismissTimer() {
    _autoDismissTimer?.cancel();
    _autoDismissTimer = Timer(const Duration(seconds: 10), () {
      isResting = false;
      notifyListeners();
    });
  }

  void skipRestTimer() {
    _restTimer?.cancel();
    isResting = false;
    _updateWorkoutNotification();
    notifyListeners();
  }

  void _updateWorkoutNotification({int? restTime}) {
    String body = workoutName;
    if (restTime != null && restTime > 0) {
      final m = restTime ~/ 60;
      final s = restTime % 60;
      body += ' | Descanso: ${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    WorkoutForegroundService.update(title: 'Treino em Andamento', body: body);
  }

  Future<void> _playBeep() async {
    await audioPlayer.play(AssetSource('beep.wav'));
  }

  void cancelWorkout() {
    isActive = false;
    isMinimized = false;
    _workoutTimer?.cancel();
    _restTimer?.cancel();
    workoutExercises.clear();
    notifyListeners();
    _clearDraft();
    WorkoutForegroundService.stop();
  }

  double calculateVolume() {
    double total = 0;
    workoutExercises.forEach((exercise, sets) {
      if (exercise.category?.toLowerCase() != 'cardio') {
        for (var set in sets) {
          if (set.isCompleted) {
            total += set.weight * set.reps;
          }
        }
      }
    });
    return total;
  }

  int calculateCompletedSets() {
    int total = 0;
    for (var sets in workoutExercises.values) {
      for (var s in sets) {
        if (s.isCompleted) total++;
      }
    }
    return total;
  }

  Future<WorkoutResult> finishWorkout() async {
    int recordsBrokenCount = 0;
    
    for (var entry in workoutExercises.entries) {
      int exerciseId = entry.key.id!;
      bool isCardio = entry.key.category?.toLowerCase() == 'cardio';

      if (!isCardio) {
        double historicalMax = await DatabaseHelper.instance.getMaxWeightForExercise(exerciseId);
        double historicalMaxVol = await DatabaseHelper.instance.getMaxVolumeForExercise(exerciseId);
        
        double maxWeightInThisWorkout = 0;
        double maxVolumeInThisWorkout = 0;
        
        for (var set in entry.value) {
          if (set.isCompleted) {
            if (set.weight > maxWeightInThisWorkout) maxWeightInThisWorkout = set.weight;
            double volume = set.weight * set.reps;
            if (volume > maxVolumeInThisWorkout) maxVolumeInThisWorkout = volume;
          }
        }
        
        bool brokeWeight = (maxWeightInThisWorkout > historicalMax && maxWeightInThisWorkout > 0);
        bool brokeVolume = (maxVolumeInThisWorkout > historicalMaxVol && maxVolumeInThisWorkout > 0);
        if (brokeWeight || brokeVolume) recordsBrokenCount++;
      }
    }

    final workoutToSave = Workout(
      name: workoutName,
      startTime: currentWorkout!.startTime,
      endTime: DateTime.now(),
      durationSeconds: secondsElapsed,
      totalVolume: calculateVolume(),
      notes: notes,
      recordsBroken: recordsBrokenCount,
    );

    final List<WorkoutSet> setsToSave = [];
    for (var sets in workoutExercises.values) {
      for (var set in sets) {
        if (set.isCompleted) {
          setsToSave.add(WorkoutSet(
            exerciseId: set.exerciseId,
            reps: set.reps,
            weight: set.weight,
            durationSeconds: set.durationSeconds,
            distance: set.distance,
            setType: set.setType,
            isCompleted: true,
            rpe: set.rpe,
            superSetId: set.superSetId,
          ));
        }
      }
    }

    final (savedWorkout, completedSets) =
        await DatabaseHelper.instance.insertWorkoutWithSets(workoutToSave, setsToSave);

    bool routineChanged = _hasRoutineChanged();

    cancelWorkout(); // also stops the foreground service and clears the draft

    return WorkoutResult(savedWorkout, completedSets, recordsBrokenCount, routineChanged);
  }

  bool _hasRoutineChanged() {
    if (routineId == null) return false;
    if (routineOriginalSets == null) return false;

    for (var entry in workoutExercises.entries) {
       int exId = entry.key.id!;
       int currentSets = entry.value.length;
       int originalSets = routineOriginalSets![exId] ?? 0;
       if (currentSets != originalSets) return true;
    }
    return false;
  }

  Future<void> updateRoutine() async {
    if (routineId == null) return;
    final routine = await DatabaseHelper.instance.getRoutines().then((list) => list.firstWhere((r) => r.id == routineId));
    
    Map<int, int> newSets = {};
    for (var entry in workoutExercises.entries) {
      newSets[entry.key.id!] = entry.value.length;
    }
    
    await DatabaseHelper.instance.updateRoutine(routine, newSets);
  }

  Future<void> updateExerciseNotes(Exercise exercise, String notesVal) async {
    exercise.notes = notesVal.isEmpty ? null : notesVal;
    await DatabaseHelper.instance.updateExercise(exercise);
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/exercise.dart';
import '../models/workout.dart';
import '../models/workout_set.dart';
import '../db/database_helper.dart';
import 'notification_manager.dart';
import 'translation_manager.dart';
import 'cardio_utils.dart';
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
  Timer? _workoutTimer;

  final Map<int, int> exerciseRestTimes = {};
  final Map<int, double> exerciseHistoricalMax = {};
  final Map<int, double> exerciseHistoricalMaxVolume = {};
  final Map<int, List<WorkoutSet>> exercisePreviousSets = {};
  
  Timer? _restTimer;
  Timer? _autoDismissTimer;
  int restSecondsRemaining = 0;
  bool isResting = false;
  final AudioPlayer audioPlayer = AudioPlayer();

  Map<int, String?> _routineSuperSets = {};

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
    restSecondsRemaining = 0;
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
      notifyListeners();
    });

    notifyListeners();
  }

  Future<void> loadExercises() async {
    final exercises = await DatabaseHelper.instance.getExercises();
    for (var ex in exercises) {
      exerciseHistoricalMax[ex.id!] = await DatabaseHelper.instance.getMaxWeightForExercise(ex.id!);
      exerciseHistoricalMaxVolume[ex.id!] = await DatabaseHelper.instance.getMaxVolumeForExercise(ex.id!);
      exercisePreviousSets[ex.id!] = await DatabaseHelper.instance.getLastWorkoutSetsForExercise(ex.id!);
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
    }
  }

  void removeSet(Exercise exercise, int index) {
    if (workoutExercises.containsKey(exercise) && workoutExercises[exercise]!.length > index) {
      workoutExercises[exercise]!.removeAt(index);
      notifyListeners();
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
    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (restSecondsRemaining > 0) {
        restSecondsRemaining--;
        NotificationManager.instance.showWorkoutNotification(workoutName, secondsElapsed, restTime: restSecondsRemaining);
        notifyListeners();
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
    notifyListeners();
  }

  void subtractRestTime(int seconds) {
    if (restSecondsRemaining > seconds) {
      restSecondsRemaining -= seconds;
    } else {
      restSecondsRemaining = 0;
    }
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
    NotificationManager.instance.showWorkoutNotification(workoutName, secondsElapsed);
    notifyListeners();
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

    final savedWorkout = await DatabaseHelper.instance.insertWorkout(workoutToSave);
    List<WorkoutSet> completedSets = [];
    
    for (var sets in workoutExercises.values) {
      for (var set in sets) {
        if (set.isCompleted) {
          final setToSave = WorkoutSet(
            workoutId: savedWorkout.id,
            exerciseId: set.exerciseId,
            reps: set.reps,
            weight: set.weight,
            durationSeconds: set.durationSeconds,
            distance: set.distance,
            setType: set.setType,
            isCompleted: true,
            rpe: set.rpe,
            superSetId: set.superSetId,
          );
          await DatabaseHelper.instance.insertWorkoutSet(setToSave);
          completedSets.add(setToSave);
        }
      }
    }

    bool routineChanged = _hasRoutineChanged();
    
    cancelWorkout();
    NotificationManager.instance.hideWorkoutNotification();
    
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

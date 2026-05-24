import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/exercise.dart';
import '../models/workout.dart';
import '../models/workout_set.dart';
import '../models/achievement.dart';
import '../managers/workout_manager.dart';
import '../managers/cardio_utils.dart';
import '../managers/achievement_manager.dart';
import 'exercise_library_screen.dart';
import 'workout_summary_screen.dart';
import '../managers/translation_manager.dart';

class ActiveWorkoutScreen extends StatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  WorkoutManager get wm => WorkoutManager.instance;
  TranslationManager get tm => TranslationManager.instance;
  bool get isPt => tm.currentLanguage == 'pt';

  bool _enableRpe = false;
  double _userWeight = 70.0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _enableRpe = prefs.getBool('user_enable_rpe') ?? false;
      _userWeight = prefs.getDouble('user_weight') ?? 70.0;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  String _formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return '${m}m ${s}s';
  }

  String _formatTimeDigital(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _addExerciseToWorkout() async {
    final Exercise? selected = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ExerciseLibraryScreen(isSelector: true),
      ),
    );

    if (selected != null) {
      wm.addExerciseToWorkout(selected);
    }
  }

  void _finishWorkout() async {
    final isPt = tm.currentLanguage == 'pt';
    final notesController = TextEditingController(text: wm.notes);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text(
            isPt ? 'Observações do Treino' : 'Workout Notes',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isPt 
                    ? 'Deseja adicionar alguma observação geral sobre o treino de hoje?' 
                    : 'Would you like to add any general notes about today\'s workout?',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                autofocus: true,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: isPt ? 'Como foi o treino de hoje? (Opcional)...' : 'How was the workout today? (Optional)...',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade800),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.blue),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(isPt ? 'Voltar' : 'Go Back', style: const TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              onPressed: () async {
                wm.notes = notesController.text;
                Navigator.pop(context);
                _performFinishWorkout();
              },
              child: Text(isPt ? 'Concluir' : 'Finish'),
            ),
          ],
        );
      },
    );
  }

  void _performFinishWorkout() async {
    final result = await wm.finishWorkout();
    
    // Check for achievements
    final newAchievements = await AchievementManager.instance.checkAchievements(result.workout, result.sets);

    if (!mounted) return;
    
    _navigateToSummary(result.workout, result.sets, result.recordsBroken, newAchievements);
  }

  void _navigateToSummary(Workout workout, List<WorkoutSet> sets, int recordsBroken, List<dynamic> newAchievements) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutSummaryScreen(
          workout: workout,
          completedSets: sets,
          recordsBroken: recordsBroken,
          newAchievements: newAchievements.cast<Achievement>(),
        ),
      ),
    );
  }

  void _showRestTimePicker(Exercise exercise) {
    final isPt = TranslationManager.instance.currentLanguage == 'pt';
    int currentSeconds = wm.exerciseRestTimes[exercise.id!] ?? 120;
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              height: 250,
              child: Column(
                children: [
                  Text(isPt ? 'Tempo de Descanso' : 'Rest Timer', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, size: 40),
                        onPressed: () {
                          if (currentSeconds > 30) {
                            setModalState(() => currentSeconds -= 30);
                            wm.exerciseRestTimes[exercise.id!] = currentSeconds;
                          }
                        },
                      ),
                      Text(
                        _formatTimeDigital(currentSeconds),
                        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, size: 40),
                        onPressed: () {
                          if (currentSeconds < 300) {
                            setModalState(() => currentSeconds += 30);
                            wm.exerciseRestTimes[exercise.id!] = currentSeconds;
                          }
                        },
                      ),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(isPt ? 'Confirmar' : 'Confirm'),
                    ),
                  ),
                ],
              ),
            );
          }
        );
      }
    );
  }

  Widget _buildRestTimerPill() {
    final isPt = TranslationManager.instance.currentLanguage == 'pt';
    bool isDone = wm.restSecondsRemaining == 0;
    
    return GestureDetector(
      onTap: isDone ? () => wm.skipRestTimer() : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isDone ? Colors.green.shade700 : Colors.blue.shade800,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
          boxShadow: [
            BoxShadow(
              color: isDone ? Colors.green.withOpacity(0.3) : Colors.blue.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
          ]
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(isDone ? Icons.check_circle_outline_rounded : Icons.timer_outlined, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isDone 
                    ? (isPt ? "Hora de treinar!" : "Time to work!") 
                    : _formatTimeDigital(wm.restSecondsRemaining),
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            if (!isDone)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 22),
                    onPressed: () => wm.skipRestTimer(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              )
            else
              const Icon(Icons.close, color: Colors.white54, size: 18),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tm = TranslationManager.instance;
    final isPt = tm.currentLanguage == 'pt';

    return ListenableBuilder(
      listenable: wm,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(wm.workoutName.isEmpty ? (isPt ? 'Registrar Treino' : 'Log Workout') : wm.workoutName),
            leading: IconButton(
              icon: const Icon(Icons.keyboard_arrow_down),
              onPressed: () {
                wm.minimize();
                Navigator.pop(context);
              },
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () {
                  wm.cancelWorkout();
                  Navigator.pop(context);
                },
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ElevatedButton(
                  onPressed: _finishWorkout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: Text(tm.translate('act_finish')),
                ),
              ),
            ],
          ),
          body: Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text(isPt ? 'Tempo' : 'Time', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(_formatTimeDigital(wm.secondsElapsed), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                            ],
                          ),
                        ),
                        Expanded(child: _buildMetric(tm.translate('hist_volume'), '${wm.calculateVolume().toInt()} kg', Colors.white)),
                        Expanded(child: _buildMetric(tm.translate('hist_sets'), '${_calculateTotalCompletedSets()}', Colors.white)),
                      ],
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView(
                      children: [
                        ...wm.workoutExercises.entries.map((entry) {
                          return _buildExerciseBlock(entry.key, entry.value);
                        }),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: TextButton(
                            onPressed: _addExerciseToWorkout,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.blue,
                              backgroundColor: Colors.blue.withOpacity(0.1),
                            ),
                            child: Text(tm.translate('cr_add_exercise')),
                          ),
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ],
              ),
              if (wm.isResting)
                Positioned(
                  bottom: 24,
                  left: 24,
                  right: 24,
                  child: _buildRestTimerPill(),
                ),
            ],
          ),
        );
      },
    );
  }

  int _calculateTotalCompletedSets() {
    int total = 0;
    for (var sets in wm.workoutExercises.values) {
      for (var set in sets) {
        if (set.isCompleted) total++;
      }
    }
    return total;
  }

  Widget _buildMetric(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ],
    );
  }

  Widget _buildExerciseBlock(Exercise exercise, List<WorkoutSet> sets) {
    int restTime = wm.exerciseRestTimes[exercise.id!] ?? 120;
    bool isCardio = exercise.category?.toLowerCase() == 'cardio';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(exercise.translatedName, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16)),
                const Icon(Icons.more_vert),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: InkWell(
              onTap: () => _showRestTimePicker(exercise),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer_outlined, size: 16, color: Colors.blue.shade200),
                  const SizedBox(width: 4),
                  Text(tm.translate('act_rest_timer', args: [_formatTime(restTime)]), style: TextStyle(color: Colors.blue.shade200, fontSize: 12)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Icon(Icons.edit_note, size: 18, color: Colors.grey.shade400),
                const SizedBox(width: 6),
                Expanded(
                  child: TextFormField(
                    key: ValueKey('ex_note_${exercise.id}'),
                    initialValue: exercise.notes ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: tm.translate('act_exercise_notes'),
                      hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (val) {
                      wm.updateExerciseNotes(exercise, val);
                    },
                  ),
                ),
              ],
            ),
          ),
          if (sets.isNotEmpty && sets.first.superSetId != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.blue.withOpacity(0.3), width: 0.5),
                ),
                child: Text(
                  tm.translate('act_superset_label'),
                  style: const TextStyle(color: Colors.blue, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                SizedBox(width: 30, child: Text(tm.translate('act_set'), style: const TextStyle(color: Colors.grey, fontSize: 12))),
                Expanded(child: Text(tm.translate('act_previous'), style: const TextStyle(color: Colors.grey, fontSize: 12))),
                SizedBox(width: 60, child: Text(isCardio ? tm.translate('act_time') : tm.translate('act_weight'), style: const TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center)),
                const SizedBox(width: 12),
                SizedBox(width: 60, child: Text(isCardio ? tm.translate('act_dist_cal') : tm.translate('act_reps'), style: const TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center)),
                const SizedBox(width: 12),
                if (!isCardio && _enableRpe) ...[
                  SizedBox(width: 45, child: Text('RPE', style: const TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center)),
                  const SizedBox(width: 8),
                ] else ...[
                  const SizedBox(width: 16),
                ],
                const SizedBox(width: 40, child: Icon(Icons.check, size: 16, color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(sets.length, (index) {
            final set = sets[index];
            final bool isInSuperSet = set.superSetId != null;
            
            double historicalMax = wm.exerciseHistoricalMax[exercise.id!] ?? 0.0;
            double historicalMaxVol = wm.exerciseHistoricalMaxVolume[exercise.id!] ?? 0.0;
            double currentVolume = set.weight * set.reps;
            
            bool isWeightPR = !isCardio && set.isCompleted && set.weight > 0 && set.weight > historicalMax;
            bool isVolumePR = !isCardio && set.isCompleted && currentVolume > 0 && currentVolume > historicalMaxVol;
            bool isAnyPR = isWeightPR || isVolumePR;
            
            String formatW(double w) => w == w.roundToDouble() ? w.toInt().toString() : w.toString();
            String previousText = '-';
            WorkoutSet? prevSet;
            final prevSets = wm.exercisePreviousSets[exercise.id!];
            if (prevSets != null && index < prevSets.length) {
              prevSet = prevSets[index];
              if (isCardio) {
                previousText = '${CardioUtils.formatDuration(prevSet.durationSeconds ?? 0)} | ${formatW(prevSet.distance ?? 0)}';
              } else {
                previousText = '${formatW(prevSet.weight)}kg x ${prevSet.reps}';
              }
            }

            return Container(
              color: isAnyPR ? Colors.amber.withOpacity(0.15) : (set.isCompleted ? Colors.green.withOpacity(0.2) : Colors.transparent),
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  if (isInSuperSet)
                    Container(
                      width: 4,
                      height: 32,
                      margin: const EdgeInsets.only(left: 4, right: 8),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                      ),
                    )
                  else
                    const SizedBox(width: 16),
                  SizedBox(
                    width: 30,
                    child: GestureDetector(
                      onTap: () => _showSetTypeSelector(exercise, index, set),
                      child: Center(
                        child: _buildSetTypeBadge(index, set, set.isCompleted, isAnyPR),
                      ),
                    ),
                  ),
                  Expanded(child: Text(previousText, style: const TextStyle(color: Colors.grey, fontSize: 13))),
                  if (isCardio) ...[
                    // Cardio Time Input
                    SizedBox(
                      width: 60,
                      child: Container(
                        decoration: BoxDecoration(color: Colors.grey.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                        child: TextFormField(
                          key: ValueKey('${exercise.id}_${index}_d'),
                          initialValue: CardioUtils.formatDuration(set.durationSeconds ?? 0),
                          keyboardType: TextInputType.datetime,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 4),
                          ),
                          onChanged: (val) {
                            int newDuration = CardioUtils.parseDuration(val);
                            double? estimatedCal;
                            if (newDuration > 0 && (set.distance == null || set.distance == 0)) {
                               estimatedCal = CardioUtils.estimateCalories(
                                category: exercise.category!,
                                userWeight: _userWeight,
                                durationSeconds: newDuration,
                                exerciseName: exercise.name,
                              );
                            }
                            wm.updateSet(exercise, index, WorkoutSet(
                              id: set.id, workoutId: set.workoutId, exerciseId: set.exerciseId,
                              reps: 1, weight: 0, 
                              durationSeconds: newDuration,
                              distance: estimatedCal ?? set.distance,
                              setType: set.setType, isCompleted: set.isCompleted,
                              rpe: set.rpe,
                              superSetId: set.superSetId,
                            ));
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Cardio Distance/Calories Input
                    SizedBox(
                      width: 60,
                      child: Container(
                        decoration: BoxDecoration(color: Colors.grey.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                        child: TextFormField(
                          key: ValueKey('${exercise.id}_${index}_v'),
                          initialValue: set.distance == null || set.distance == 0 ? '' : formatW(set.distance!),
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 4),
                          ),
                          onChanged: (val) {
                            wm.updateSet(exercise, index, WorkoutSet(
                              id: set.id, workoutId: set.workoutId, exerciseId: set.exerciseId,
                              reps: 1, weight: 0, 
                              durationSeconds: set.durationSeconds,
                              distance: double.tryParse(val) ?? 0,
                              setType: set.setType, isCompleted: set.isCompleted,
                              rpe: set.rpe,
                              superSetId: set.superSetId,
                            ));
                          },
                        ),
                      ),
                    ),
                  ] else ...[
                    // Standard Weight Input
                    SizedBox(
                      width: 60,
                      child: Container(
                        decoration: BoxDecoration(color: Colors.grey.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                        child: TextFormField(
                          key: ValueKey('${exercise.id}_${index}_${set.weight}_${set.reps}_w'),
                          initialValue: set.weight == 0 ? '' : formatW(set.weight),
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 18),
                          decoration: InputDecoration(
                            hintText: prevSet != null ? formatW(prevSet.weight) : '-',
                            hintStyle: const TextStyle(color: Colors.grey, fontSize: 18),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 4),
                          ),
                          onChanged: (val) {
                            wm.updateSet(exercise, index, WorkoutSet(
                              id: set.id, workoutId: set.workoutId, exerciseId: set.exerciseId,
                              reps: set.reps, weight: double.tryParse(val) ?? 0, setType: set.setType, isCompleted: set.isCompleted,
                              rpe: set.rpe,
                              superSetId: set.superSetId,
                            ));
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Standard Reps Input
                    SizedBox(
                      width: 60,
                      child: Container(
                        decoration: BoxDecoration(color: Colors.grey.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                        child: TextFormField(
                          key: ValueKey('${exercise.id}_${index}_${set.weight}_${set.reps}_r'),
                          initialValue: set.reps == 0 ? '' : set.reps.toString(),
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 18),
                          decoration: InputDecoration(
                            hintText: prevSet != null ? prevSet.reps.toString() : '-',
                            hintStyle: const TextStyle(color: Colors.grey, fontSize: 18),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 4),
                          ),
                          onChanged: (val) {
                            wm.updateSet(exercise, index, WorkoutSet(
                              id: set.id, workoutId: set.workoutId, exerciseId: set.exerciseId,
                              reps: int.tryParse(val) ?? 0, weight: set.weight, setType: set.setType, isCompleted: set.isCompleted,
                              rpe: set.rpe,
                              superSetId: set.superSetId,
                            ));
                          },
                        ),
                      ),
                    ),
                  ],
                  if (!isCardio && _enableRpe) ...[
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 45,
                      height: 32,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: set.rpe != null ? Colors.blue.withOpacity(0.15) : Colors.grey.withOpacity(0.15),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                        onPressed: () => _showRpeSelector(exercise, index, set),
                        child: Text(
                          set.rpe != null 
                              ? (set.rpe == set.rpe!.roundToDouble() ? set.rpe!.toInt().toString() : set.rpe!.toString())
                              : '-',
                          style: TextStyle(
                            fontSize: 15,
                            color: set.rpe != null ? Colors.blue.shade200 : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ] else ...[
                    const SizedBox(width: 16),
                  ],
                  SizedBox(
                    width: 40,
                    child: IconButton(
                      icon: Icon(Icons.check, color: set.isCompleted ? Colors.green : Colors.grey),
                      onPressed: () {
                        if (!isCardio) {
                          double finalWeight = set.weight;
                          int finalReps = set.reps;

                          if ((set.weight == 0 || set.reps == 0) && prevSet != null) {
                            if (finalWeight == 0) finalWeight = prevSet.weight;
                            if (finalReps == 0) finalReps = prevSet.reps;

                            wm.updateSet(exercise, index, WorkoutSet(
                              id: set.id,
                              workoutId: set.workoutId,
                              exerciseId: set.exerciseId,
                              reps: finalReps,
                              weight: finalWeight,
                              setType: set.setType,
                              isCompleted: set.isCompleted,
                              rpe: set.rpe,
                              superSetId: set.superSetId,
                            ));
                          }
                        }

                        wm.toggleSetCompletion(exercise, index);
                        
                        if (!set.isCompleted && !isCardio) { 
                          double currentSetWeight = set.weight;
                          double currentSetVolume = set.weight * set.reps;
                          
                          bool brokeWeight = currentSetWeight > 0 && currentSetWeight > (wm.exerciseHistoricalMax[exercise.id!] ?? 0.0);
                          bool brokeVolume = currentSetVolume > 0 && currentSetVolume > (wm.exerciseHistoricalMaxVolume[exercise.id!] ?? 0.0);
                          
                          if (brokeWeight || brokeVolume) {
                            String msg = brokeWeight && brokeVolume
                                ? (isPt ? 'Novo Recorde Pessoal Duplo! Carga (${currentSetWeight}kg) e Volume (${currentSetVolume}kg)!' : 'New Double PR! Weight (${currentSetWeight}kg) and Volume (${currentSetVolume}kg)!')
                                : brokeWeight
                                    ? (isPt ? 'Novo Recorde de Carga! ${currentSetWeight}kg!' : 'New Weight PR! ${currentSetWeight}kg!')
                                    : (isPt ? 'Novo Recorde de Volume! ${currentSetVolume}kg (${set.weight}x${set.reps})!' : 'New Volume PR! ${currentSetVolume}kg (${set.weight}x${set.reps})!');
                            
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    SvgPicture.asset('assets/crown.svg', width: 24, height: 24, colorFilter: const ColorFilter.mode(Colors.amber, BlendMode.srcIn)),
                                    const SizedBox(width: 12),
                                    Expanded(child: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                                  ],
                                ),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: Colors.grey.shade900,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.amber, width: 1)),
                                duration: const Duration(seconds: 3),
                              )
                            );
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            );
          }),
          TextButton.icon(
            onPressed: () => wm.addSet(exercise),
            icon: const Icon(Icons.add, size: 16),
            label: Text(tm.translate('act_add_set'), style: const TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetTypeBadge(int index, WorkoutSet set, bool isCompleted, bool isAnyPR) {
    Color bgColor = Colors.grey.withOpacity(0.15);
    Color textColor = Colors.white;
    String text = '${index + 1}';
    
    if (set.setType == 'Warmup') {
      bgColor = Colors.amber.shade700;
      textColor = Colors.black;
      text = 'W';
    } else if (set.setType == 'Failure') {
      bgColor = Colors.red.shade600;
      textColor = Colors.white;
      text = 'F';
    } else if (set.setType == 'Drop') {
      bgColor = Colors.blue.shade600;
      textColor = Colors.white;
      text = 'D';
    } else if (isCompleted) {
      bgColor = Colors.green.shade600;
      textColor = Colors.white;
    }

    Widget badge = Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        boxShadow: isCompleted || set.setType != 'Normal'
            ? [BoxShadow(color: bgColor.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 1))]
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );

    if (isAnyPR) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          badge,
          Positioned(
            top: -6,
            right: -6,
            child: SvgPicture.asset(
              'assets/crown.svg',
              width: 11,
              height: 11,
              colorFilter: const ColorFilter.mode(Colors.amber, BlendMode.srcIn),
            ),
          ),
        ],
      );
    }

    return badge;
  }

  void _showSetTypeSelector(Exercise exercise, int index, WorkoutSet set) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Text(
                    tm.translate('act_type_title'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Colors.white10,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(tm.translate('act_type_normal'), style: const TextStyle(color: Colors.white)),
                  subtitle: Text(tm.translate('act_type_normal_sub'), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  trailing: set.setType == 'Normal' ? const Icon(Icons.check, color: Colors.blue) : null,
                  onTap: () {
                    wm.updateSet(exercise, index, WorkoutSet(
                      id: set.id, workoutId: set.workoutId, exerciseId: set.exerciseId,
                      reps: set.reps, weight: set.weight, setType: 'Normal', isCompleted: set.isCompleted,
                      rpe: set.rpe,
                      superSetId: set.superSetId,
                    ));
                    setState(() {});
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.amber.shade700,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Text('W', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(tm.translate('act_type_warmup'), style: const TextStyle(color: Colors.white)),
                  subtitle: Text(tm.translate('act_type_warmup_sub'), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  trailing: set.setType == 'Warmup' ? const Icon(Icons.check, color: Colors.blue) : null,
                  onTap: () {
                    wm.updateSet(exercise, index, WorkoutSet(
                      id: set.id, workoutId: set.workoutId, exerciseId: set.exerciseId,
                      reps: set.reps, weight: set.weight, setType: 'Warmup', isCompleted: set.isCompleted,
                      rpe: set.rpe,
                      superSetId: set.superSetId,
                    ));
                    setState(() {});
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Text('F', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(tm.translate('act_type_failure'), style: const TextStyle(color: Colors.white)),
                  subtitle: Text(tm.translate('act_type_failure_sub'), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  trailing: set.setType == 'Failure' ? const Icon(Icons.check, color: Colors.blue) : null,
                  onTap: () {
                    wm.updateSet(exercise, index, WorkoutSet(
                      id: set.id, workoutId: set.workoutId, exerciseId: set.exerciseId,
                      reps: set.reps, weight: set.weight, setType: 'Failure', isCompleted: set.isCompleted,
                      rpe: set.rpe,
                      superSetId: set.superSetId,
                    ));
                    setState(() {});
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade600,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Text('D', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(tm.translate('act_type_drop'), style: const TextStyle(color: Colors.white)),
                  subtitle: Text(tm.translate('act_type_drop_sub'), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  trailing: set.setType == 'Drop' ? const Icon(Icons.check, color: Colors.blue) : null,
                  onTap: () {
                    wm.updateSet(exercise, index, WorkoutSet(
                      id: set.id, workoutId: set.workoutId, exerciseId: set.exerciseId,
                      reps: set.reps, weight: set.weight, setType: 'Drop', isCompleted: set.isCompleted,
                      rpe: set.rpe,
                      superSetId: set.superSetId,
                    ));
                    setState(() {});
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRpeSelector(Exercise exercise, int index, WorkoutSet set) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Rate of Perceived Exertion (RPE)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: List.generate(11, (i) {
                    double val = 5 + (i * 0.5);
                    if (val > 10) return const SizedBox.shrink();
                    bool isSelected = set.rpe == val;
                    return InkWell(
                      onTap: () {
                        wm.updateSet(exercise, index, WorkoutSet(
                          id: set.id, workoutId: set.workoutId, exerciseId: set.exerciseId,
                          reps: set.reps, weight: set.weight, setType: set.setType, isCompleted: set.isCompleted,
                          rpe: val,
                          superSetId: set.superSetId,
                        ));
                        setState(() {});
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue : Colors.white10,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? Colors.blueAccent : Colors.white24),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          val == val.roundToDouble() ? val.toInt().toString() : val.toString(),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    );
                  }).where((w) => w is! SizedBox).toList(),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    wm.updateSet(exercise, index, WorkoutSet(
                      id: set.id, workoutId: set.workoutId, exerciseId: set.exerciseId,
                      reps: set.reps, weight: set.weight, setType: set.setType, isCompleted: set.isCompleted,
                      rpe: null,
                      superSetId: set.superSetId,
                    ));
                    setState(() {});
                    Navigator.pop(context);
                  },
                  child: const Text('Limpar RPE', style: TextStyle(color: Colors.redAccent)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

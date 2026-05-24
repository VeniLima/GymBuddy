import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../db/database_helper.dart';
import '../models/workout.dart';
import '../models/workout_set.dart';
import '../models/exercise.dart';
import '../managers/translation_manager.dart';

class WorkoutHistoryScreen extends StatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  State<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen> {
  bool _isLoading = true;
  List<Workout> _history = [];
  Map<int, List<WorkoutSet>> _workoutSets = {};
  Map<int, Exercise> _exercisesMap = {};

  @override
  void initState() {
    super.initState();
    _loadWorkoutHistory();
  }

  Future<void> _loadWorkoutHistory() async {
    setState(() {
      _isLoading = true;
    });

    final history = await DatabaseHelper.instance.getAllWorkoutsOrderedByDate();
    // Reverter para mostrar os mais recentes primeiro
    final reversedHistory = history.reversed.toList();

    // Carrega exercícios para mapear nomes e grupos musculares por ID
    final exercises = await DatabaseHelper.instance.getExercises();
    final Map<int, Exercise> exMap = {};
    for (var ex in exercises) {
      if (ex.id != null) {
        exMap[ex.id!] = ex;
      }
    }

    // Carrega as séries de cada treino concluído
    final Map<int, List<WorkoutSet>> setsMap = {};
    for (var workout in reversedHistory) {
      if (workout.id != null) {
        setsMap[workout.id!] = await DatabaseHelper.instance.getSetsForWorkout(workout.id!);
      }
    }

    if (mounted) {
      setState(() {
        _history = reversedHistory;
        _exercisesMap = exMap;
        _workoutSets = setsMap;
        _isLoading = false;
      });
    }
  }

  String _formatRelativeDate(DateTime date) {
    final isPt = TranslationManager.instance.currentLanguage == 'pt';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return isPt ? 'Agora mesmo' : 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return isPt 
          ? 'Há $minutes minuto${minutes > 1 ? 's' : ''}'
          : '$minutes minute${minutes > 1 ? 's' : ''} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return isPt
          ? 'Há $hours hora${hours > 1 ? 's' : ''}'
          : '$hours hour${hours > 1 ? 's' : ''} ago';
    } else {
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final compareDate = DateTime(date.year, date.month, date.day);

      if (compareDate == today) {
        return isPt ? 'Hoje' : 'Today';
      } else if (compareDate == yesterday) {
        return isPt ? 'Ontem' : 'Yesterday';
      } else {
        final diffDays = today.difference(compareDate).inDays;
        if (diffDays < 7) {
          return isPt ? 'Há $diffDays dias' : '$diffDays days ago';
        } else if (diffDays < 30) {
          int weeks = diffDays ~/ 7;
          return isPt
              ? 'Há $weeks semana${weeks > 1 ? 's' : ''}'
              : '$weeks week${weeks > 1 ? 's' : ''} ago';
        } else {
          int months = diffDays ~/ 30;
          return isPt
              ? 'Há $months mê${months > 1 ? 'ses' : 's'}'
              : '$months month${months > 1 ? 's' : ''} ago';
        }
      }
    }
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    int minutes = seconds ~/ 60;
    if (minutes < 60) {
      int remSecs = seconds % 60;
      return '${minutes}m ${remSecs}s';
    } else {
      int hours = minutes ~/ 60;
      int remMins = minutes % 60;
      return '${hours}h ${remMins}m';
    }
  }

  Future<void> _confirmDelete(int workoutId) async {
    final tm = TranslationManager.instance;
    final isPt = tm.currentLanguage == 'pt';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(isPt ? 'Excluir Treino' : 'Delete Workout', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          isPt 
              ? 'Deseja mesmo excluir este treino do seu histórico? Esta ação é irreversível.'
              : 'Are you sure you want to delete this workout from your history? This action is irreversible.',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tm.translate('ex_cancel'), style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(isPt ? 'Excluir' : 'Delete', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.deleteWorkout(workoutId);
      _loadWorkoutHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isPt ? 'Treino excluído com sucesso.' : 'Workout deleted successfully.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tm = TranslationManager.instance;
    final isPt = tm.currentLanguage == 'pt';

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          tm.translate('hist_title'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
          : _history.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_toggle_off, size: 64, color: Colors.grey[700]),
                      const SizedBox(height: 16),
                      Text(
                        isPt ? 'Nenhum treino concluído ainda.' : 'No workouts completed yet.',
                        style: TextStyle(color: Colors.grey[500], fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isPt ? 'Seus treinos finalizados aparecerão aqui!' : 'Your finished workouts will show up here!',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final workout = _history[index];
                    final sets = _workoutSets[workout.id] ?? [];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: WorkoutHistoryCard(
                        workout: workout,
                        sets: sets,
                        exercisesMap: _exercisesMap,
                        formatRelativeDate: _formatRelativeDate,
                        formatDuration: _formatDuration,
                        onDelete: () => _confirmDelete(workout.id!),
                      ),
                    );
                  },
                ),
    );
  }
}

class WorkoutHistoryCard extends StatefulWidget {
  final Workout workout;
  final List<WorkoutSet> sets;
  final Map<int, Exercise> exercisesMap;
  final String Function(DateTime) formatRelativeDate;
  final String Function(int) formatDuration;
  final VoidCallback onDelete;

  const WorkoutHistoryCard({
    super.key,
    required this.workout,
    required this.sets,
    required this.exercisesMap,
    required this.formatRelativeDate,
    required this.formatDuration,
    required this.onDelete,
  });

  @override
  State<WorkoutHistoryCard> createState() => _WorkoutHistoryCardState();
}

class _WorkoutHistoryCardState extends State<WorkoutHistoryCard> {
  TranslationManager get tm => TranslationManager.instance;
  bool get isPt => tm.currentLanguage == 'pt';

  bool _isExpanded = false;

  String _translateMuscle(String muscle) {
    final isPt = TranslationManager.instance.currentLanguage == 'pt';
    if (!isPt) return muscle;
    switch (muscle) {
      case 'Chest': return 'Peito';
      case 'Back': return 'Costas';
      case 'Shoulders': return 'Ombros';
      case 'Biceps': return 'Bíceps';
      case 'Triceps': return 'Tríceps';
      case 'Abs': return 'Abdômen';
      case 'Core': return 'Abdômen';
      case 'Quadriceps': return 'Quadríceps';
      case 'Hamstrings': return 'Isquiotibiais';
      case 'Adductors': return 'Adutores';
      case 'Glutes': return 'Glúteos';
      case 'Calves': return 'Panturrilha';
      default: return muscle;
    }
  }

  String _formatShareDate(DateTime date) {
    final isPt = TranslationManager.instance.currentLanguage == 'pt';
    final weekDays = isPt
        ? ['Segunda-feira', 'Terça-feira', 'Quarta-feira', 'Quinta-feira', 'Sexta-feira', 'Sábado', 'Domingo']
        : ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final months = isPt
        ? ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez']
        : ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    final dayOfWeek = weekDays[date.weekday - 1];
    final month = months[date.month - 1];
    final day = date.day;
    final year = date.year;
    
    int hour = date.hour;
    final isPm = hour >= 12;
    if (hour > 12) hour -= 12;
    if (hour == 0) hour = 12;
    final minuteStr = date.minute.toString().padLeft(2, '0');
    final amPm = isPm ? 'pm' : 'am';
    
    return isPt
        ? '$dayOfWeek, $month $day, $year às $hour:$minuteStr$amPm'
        : '$dayOfWeek, $month $day, $year at $hour:$minuteStr$amPm';
  }

  void _showSharePreviewDialog(BuildContext context, String shareText) {
    final tm = TranslationManager.instance;
    final isPt = tm.currentLanguage == 'pt';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.08), width: 0.5),
        ),
        title: Row(
          children: [
            const Icon(Icons.share, color: Colors.blue, size: 22),
            const SizedBox(width: 8),
            Text(
              isPt ? 'Compartilhar Treino' : 'Share Workout',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.85,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isPt 
                    ? 'O texto abaixo será copiado formatado para você colar onde preferir:' 
                    : 'The formatted text below will be copied for you to paste wherever you like:',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 280),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.05), width: 0.5),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      shareText,
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tm.translate('ex_cancel'), style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: shareText));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 12),
                      Expanded(child: Text(isPt ? 'Treino copiado com sucesso!' : 'Workout copied successfully!', style: const TextStyle(color: Colors.white))),
                    ],
                  ),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.grey.shade900,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.blue.withOpacity(0.3), width: 1)),
                  duration: const Duration(seconds: 3),
                )
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: Text(isPt ? 'Copiar' : 'Copy'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  void _shareWorkoutText(BuildContext context) {
    final workout = widget.workout;
    final buffer = StringBuffer();
    buffer.writeln(workout.name);
    buffer.writeln(_formatShareDate(workout.startTime));
    
    if (workout.notes.isNotEmpty) {
      buffer.writeln('"${workout.notes}"');
    }
    buffer.writeln(); // Linha em branco
    
    // Agrupa séries por ID de exercício
    final Map<int, List<WorkoutSet>> exerciseGroups = {};
    for (var set in widget.sets) {
      exerciseGroups.putIfAbsent(set.exerciseId, () => []).add(set);
    }
    
    final exerciseIds = exerciseGroups.keys.toList();
    for (int i = 0; i < exerciseIds.length; i++) {
      final exId = exerciseIds[i];
      final exSets = exerciseGroups[exId] ?? [];
      final isPt = TranslationManager.instance.currentLanguage == 'pt';
      final exercise = widget.exercisesMap[exId];
      final exName = exercise?.translatedName ?? (isPt ? 'Exercício Desconhecido' : 'Unknown Exercise');
      
      buffer.writeln(exName);
      
      String formatW(double w) => w == w.roundToDouble() ? w.toInt().toString() : w.toString();
      
      for (int sIndex = 0; sIndex < exSets.length; sIndex++) {
        final set = exSets[sIndex];
        String suffix = '';
        if (set.setType == 'Warmup') suffix = isPt ? ' (Aquecimento)' : ' (Warm Up)';
        if (set.setType == 'Failure') suffix = isPt ? ' (Falha)' : ' (Failure)';
        if (set.setType == 'Drop') suffix = ' (Drop Set)';
        final rpeString = set.rpe != null 
            ? ' @${set.rpe == set.rpe!.roundToDouble() ? set.rpe!.toInt() : set.rpe}'
            : '';
        buffer.writeln(isPt 
            ? 'Série ${sIndex + 1}$suffix: ${formatW(set.weight)} kg x ${set.reps}$rpeString'
            : 'Set ${sIndex + 1}$suffix: ${formatW(set.weight)} kg x ${set.reps}$rpeString');
      }
      
      if (i < exerciseIds.length - 1) {
        buffer.writeln(); // Espaçamento entre exercícios
      }
    }

    final shareText = buffer.toString();
    _showSharePreviewDialog(context, shareText);
  }

  @override
  Widget build(BuildContext context) {
    // Agrupa séries por ID de exercício
    final Map<int, List<WorkoutSet>> exerciseGroups = {};
    for (var set in widget.sets) {
      exerciseGroups.putIfAbsent(set.exerciseId, () => []).add(set);
    }

    final exerciseIds = exerciseGroups.keys.toList();
    final int totalExercises = exerciseIds.length;
    final int displayCount = _isExpanded ? totalExercises : (totalExercises > 3 ? 3 : totalExercises);

    // Coleta grupos musculares treinados de forma única
    final Set<String> muscles = widget.sets.map((s) {
      final ex = widget.exercisesMap[s.exerciseId];
      return ex?.muscleGroup ?? '';
    }).where((m) => m.isNotEmpty).toSet();

    return Card(
      color: Theme.of(context).cardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withOpacity(0.08), width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Linha Superior: Nome, Data Relativa, Deletar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.workout.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, color: Colors.grey[500], size: 12),
                          const SizedBox(width: 4),
                          Text(
                            widget.formatRelativeDate(widget.workout.startTime),
                            style: TextStyle(color: Colors.grey[500], fontSize: 13),
                          ),
                        ],
                      ),
                      if (muscles.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: muscles.map((m) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _translateMuscle(m).toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.workout.recordsBroken > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.withOpacity(0.3), width: 0.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('👑', style: TextStyle(fontSize: 10)),
                            const SizedBox(width: 4),
                            Text(
                              isPt
                                  ? '${widget.workout.recordsBroken} Recorde${widget.workout.recordsBroken > 1 ? 's' : ''}'
                                  : '${widget.workout.recordsBroken} Record${widget.workout.recordsBroken > 1 ? 's' : ''}',
                              style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    IconButton(
                      icon: Icon(Icons.share_outlined, color: Colors.blue[400], size: 20),
                      onPressed: () => _shareWorkoutText(context),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: Colors.red[400], size: 20),
                      onPressed: widget.onDelete,
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Notas do treino (se existirem)
            if (widget.workout.notes.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.withOpacity(0.1), width: 0.5),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.note_alt_outlined, size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.workout.notes,
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Linha de Métricas Rápidas: Duração, Volume, Séries (Unified Dashboard Container)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.05), width: 0.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildQuickMetric(tm.translate('hist_duration'), widget.formatDuration(widget.workout.durationSeconds), Icons.timer),
                  _buildQuickMetric(tm.translate('hist_volume'), '${widget.workout.totalVolume.toInt()} kg', Icons.fitness_center),
                  _buildQuickMetric(tm.translate('hist_sets'), '${widget.sets.length}', Icons.check_circle_outline),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.grey, height: 1, thickness: 0.1),
            const SizedBox(height: 12),

            // Lista de Exercícios
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayCount,
              itemBuilder: (context, index) {
                final exId = exerciseIds[index];
                final exSets = exerciseGroups[exId] ?? [];
                final exercise = widget.exercisesMap[exId];
                final exName = exercise?.translatedName ?? (isPt ? 'Exercício Desconhecido' : 'Unknown Exercise');

                String formatW(double w) => w == w.roundToDouble() ? w.toInt().toString() : w.toString();

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Número da contagem do exercício no treino
                      Container(
                        margin: const EdgeInsets.only(top: 2, right: 10),
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      // Detalhes do Exercício
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  isPt 
                                      ? '${exSets.length} série${exSets.length > 1 ? 's' : ''}:   '
                                      : '${exSets.length} set${exSets.length > 1 ? 's' : ''}:   ',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Expanded(
                                  child: Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: exSets.map((s) {
                                      Color badgeBgColor = Colors.white.withOpacity(0.05);
                                      Color badgeBorderColor = Colors.white.withOpacity(0.08);
                                      Color badgeTextColor = Colors.grey[300]!;
                                      String textPrefix = '';

                                      if (s.setType == 'Warmup') {
                                        badgeBgColor = Colors.amber.withOpacity(0.08);
                                        badgeBorderColor = Colors.amber.withOpacity(0.2);
                                        badgeTextColor = Colors.amber.shade300;
                                        textPrefix = 'W: ';
                                      } else if (s.setType == 'Failure') {
                                        badgeBgColor = Colors.red.withOpacity(0.08);
                                        badgeBorderColor = Colors.red.withOpacity(0.2);
                                        badgeTextColor = Colors.red.shade300;
                                        textPrefix = 'F: ';
                                      } else if (s.setType == 'Drop') {
                                        badgeBgColor = Colors.blue.withOpacity(0.08);
                                        badgeBorderColor = Colors.blue.withOpacity(0.2);
                                        badgeTextColor = Colors.blue.shade300;
                                        textPrefix = 'D: ';
                                      }

                                      final rpeSuffix = s.rpe != null
                                          ? ' @${s.rpe == s.rpe!.roundToDouble() ? s.rpe!.toInt() : s.rpe}'
                                          : '';

                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: badgeBgColor,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: badgeBorderColor, width: 0.5),
                                        ),
                                        child: Text(
                                          '$textPrefix${s.reps}x${formatW(s.weight)}kg$rpeSuffix',
                                          style: TextStyle(
                                            color: badgeTextColor,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Botão "Ver mais" / "Ver menos"
            if (totalExercises > 3)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: Icon(
                      _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      size: 16,
                      color: Colors.blue,
                    ),
                    label: Text(
                      _isExpanded 
                          ? (isPt ? 'Ver menos' : 'Show less') 
                          : (isPt 
                              ? 'Ver mais (+${totalExercises - 3} exercícios)' 
                              : 'Show more (+${totalExercises - 3} exercises)'),
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickMetric(String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: Colors.grey[500]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(color: Colors.grey[500], fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

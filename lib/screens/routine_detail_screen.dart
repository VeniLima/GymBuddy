import 'package:flutter/material.dart';
import '../models/routine.dart';
import '../models/exercise.dart';
import '../db/database_helper.dart';
import '../managers/workout_manager.dart';
import '../managers/translation_manager.dart';
import 'active_workout_screen.dart';
import 'create_routine_screen.dart';

class RoutineDetailScreen extends StatefulWidget {
  final Routine routine;

  const RoutineDetailScreen({super.key, required this.routine});

  @override
  State<RoutineDetailScreen> createState() => _RoutineDetailScreenState();
}

class _RoutineDetailScreenState extends State<RoutineDetailScreen> {
  late Routine _routine;
  List<Exercise> _exercises = [];
  Map<int, int> _exerciseSets = {};
  bool _isLoading = true;
  final TranslationManager tm = TranslationManager.instance;

  @override
  void initState() {
    super.initState();
    _routine = widget.routine;
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() {
      _isLoading = true;
    });

    if (_routine.id != null) {
      final exercises = await DatabaseHelper.instance.getExercisesForRoutine(_routine.id!);
      final sets = await DatabaseHelper.instance.getRoutineExerciseSets(_routine.id!);
      
      final updatedRoutines = await DatabaseHelper.instance.getRoutines();
      final updatedRoutine = updatedRoutines.firstWhere((r) => r.id == _routine.id, orElse: () => _routine);

      if (mounted) {
        setState(() {
          _exercises = exercises;
          _exerciseSets = sets;
          _routine = updatedRoutine;
          _isLoading = false;
        });
      }
    }
  }

  void _editRoutine() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateRoutineScreen(routine: _routine),
      ),
    ).then((saved) {
      if (saved == true) {
        _loadDetails();
      }
    });
  }

  void _deleteRoutine() async {
    final isPt = tm.currentLanguage == 'pt';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          isPt ? 'Excluir Rotina?' : 'Delete Routine?',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          isPt 
              ? 'Tem certeza que deseja excluir esta rotina? Esta ação não pode ser desfeita.' 
              : 'Are you sure you want to delete this routine? This action cannot be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(isPt ? 'Cancelar' : 'Cancel', style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(isPt ? 'Excluir' : 'Delete', style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && _routine.id != null) {
      await DatabaseHelper.instance.deleteRoutine(_routine.id!);
      if (mounted) {
        Navigator.pop(context, true); // Retorna true para atualizar a tela anterior
      }
    }
  }

  void _startWorkout() async {
    await WorkoutManager.instance.startWorkout(_routine.name, _exercises, rId: _routine.id);
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ActiveWorkoutScreen()),
      ).then((_) {
        _loadDetails();
      });
    }
  }

  String _translateMuscle(String muscle) {
    final isPt = tm.currentLanguage == 'pt';
    const Map<String, String> muscleTranslationPt = {
      'Chest': 'Peito',
      'Back': 'Costas',
      'Shoulders': 'Ombros',
      'Biceps': 'Bíceps',
      'Triceps': 'Tríceps',
      'Quadriceps': 'Quadríceps',
      'Hamstrings': 'Isquiotibiais',
      'Adductors': 'Adutores',
      'Glutes': 'Glúteos',
      'Calves': 'Panturrilha',
      'Core': 'Abdômen',
    };
    return (isPt ? muscleTranslationPt[muscle] : muscle) ?? muscle;
  }

  @override
  Widget build(BuildContext context) {
    final isPt = tm.currentLanguage == 'pt';

    return Scaffold(
      appBar: AppBar(
        title: Text(isPt ? 'Detalhes da Rotina' : 'Routine Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: isPt ? 'Editar' : 'Edit',
            onPressed: _editRoutine,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            tooltip: isPt ? 'Excluir' : 'Delete',
            onPressed: _deleteRoutine,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _routine.name,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  if (_routine.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _routine.description,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    isPt
                        ? 'Exercícios (${_exercises.length})'
                        : 'Exercises (${_exercises.length})',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _exercises.isEmpty
                        ? Center(
                            child: Text(
                              isPt
                                  ? 'Nenhum exercício adicionado a esta rotina.'
                                  : 'No exercises added to this routine.',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _exercises.length,
                            itemBuilder: (context, index) {
                              final exercise = _exercises[index];
                              final setsCount = _exerciseSets[exercise.id] ?? 1;
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 1,
                                child: ListTile(
                                  leading: const Icon(Icons.fitness_center),
                                  title: Text(exercise.translatedName),
                                  subtitle: Text(_translateMuscle(exercise.muscleGroup)),
                                  trailing: Chip(
                                    label: Text(
                                      isPt
                                          ? '$setsCount ${setsCount == 1 ? "Série" : "Séries"}'
                                          : '$setsCount ${setsCount == 1 ? "Set" : "Sets"}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    backgroundColor: Colors.blue.withOpacity(0.1),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _exercises.isEmpty ? null : _startWorkout,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isPt ? 'Iniciar Treino' : 'Start Workout',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

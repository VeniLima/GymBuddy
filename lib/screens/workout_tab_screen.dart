import 'package:flutter/material.dart';
import 'active_workout_screen.dart';
import 'create_routine_screen.dart';
import 'routine_detail_screen.dart';
import '../managers/workout_manager.dart';
import '../db/database_helper.dart';
import '../models/routine.dart';
import '../models/exercise.dart';
import 'workout_history_screen.dart';
import '../managers/translation_manager.dart';

class WorkoutTabScreen extends StatefulWidget {
  const WorkoutTabScreen({super.key});

  @override
  State<WorkoutTabScreen> createState() => _WorkoutTabScreenState();
}

class _WorkoutTabScreenState extends State<WorkoutTabScreen> {
  List<Routine> _routines = [];
  Map<int, List<Exercise>> _routineExercises = {};
  bool _isLoading = true;
  TranslationManager get tm => TranslationManager.instance;

  @override
  void initState() {
    super.initState();
    tm.addListener(_onLanguageChanged);
    _loadRoutines();
  }

  @override
  void dispose() {
    tm.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadRoutines() async {
    setState(() {
      _isLoading = true;
    });
    
    final routines = await DatabaseHelper.instance.getRoutines();
    Map<int, List<Exercise>> exercisesMap = {};
    
    for (var r in routines) {
      if (r.id != null) {
        exercisesMap[r.id!] = await DatabaseHelper.instance.getExercisesForRoutine(r.id!);
      }
    }
    
    if (mounted) {
      setState(() {
        _routines = routines;
        _routineExercises = exercisesMap;
        _isLoading = false;
      });
    }
  }

  void _startRoutine(int routineId, String name, List<Exercise> exercises) async {
    await WorkoutManager.instance.startWorkout(name, exercises, rId: routineId);
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ActiveWorkoutScreen()),
      ).then((_) {
        _loadRoutines();
      });
    }
  }

  void _openCreateRoutine() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateRoutineScreen()),
    ).then((saved) {
      if (saved == true) {
        _loadRoutines(); // Atualiza a lista quando volta se salvou algo
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tm = TranslationManager.instance;
    final isPt = tm.currentLanguage == 'pt';

    return Scaffold(
      appBar: AppBar(
        title: Text(tm.translate('wk_title')),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WorkoutHistoryScreen()),
              ).then((_) {
                _loadRoutines();
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isPt ? 'Início Rápido' : 'Quick Start',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await WorkoutManager.instance.startWorkout(
                      isPt ? 'Treino Vazio' : 'Empty Workout', 
                      [],
                    );
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ActiveWorkoutScreen(),
                        ),
                      ).then((_) => _loadRoutines());
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: Text(tm.translate('wk_start_empty')),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    foregroundColor: Colors.blue,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isPt ? 'Minhas Rotinas' : 'My Routines',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.create_new_folder_outlined),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _openCreateRoutine,
                      icon: const Icon(Icons.assignment_outlined),
                      label: Text(tm.translate('wk_new_routine')),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.search),
                      label: Text(isPt ? 'Explorar' : 'Explore'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _routines.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Center(
                        child: Text(
                          isPt 
                              ? 'Você ainda não possui rotinas.\nCrie uma para começar!' 
                              : 'You don\'t have any routines yet.\nCreate one to get started!',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _routines.length,
                      itemBuilder: (context, index) {
                        final routine = _routines[index];
                        final exercises = _routineExercises[routine.id] ?? [];
                        
                        // Cria uma string resumida dos exercícios
                        final exerciseNames = exercises.take(3).map((e) => e.translatedName).join(', ');
                        final subtitle = exercises.length > 3 
                            ? '$exerciseNames...' 
                            : exerciseNames;
                            
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: _buildRoutineCard(routine, subtitle, exercises),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoutineCard(Routine routine, String subtitle, List<Exercise> targetExercises) {
    final tm = TranslationManager.instance;
    final isPt = tm.currentLanguage == 'pt';
    return Card(
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RoutineDetailScreen(routine: routine),
            ),
          ).then((_) {
            _loadRoutines();
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    routine.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                subtitle.isEmpty 
                    ? (isPt ? 'Sem exercícios cadastrados' : 'No exercises registered') 
                    : subtitle,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _startRoutine(routine.id!, routine.name, targetExercises),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(isPt ? 'Iniciar Rotina' : 'Start Routine'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

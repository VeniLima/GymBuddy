import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/exercise.dart';
import '../models/routine.dart';
import '../db/database_helper.dart';
import '../managers/translation_manager.dart';
import 'exercise_library_screen.dart';

class CreateRoutineScreen extends StatefulWidget {
  final Routine? routine;
  const CreateRoutineScreen({super.key, this.routine});

  @override
  State<CreateRoutineScreen> createState() => _CreateRoutineScreenState();
}

class _CreateRoutineScreenState extends State<CreateRoutineScreen> {
  final TextEditingController _nameController = TextEditingController();
  final List<Exercise> _selectedExercises = [];
  final Map<int, int> _selectedExerciseSets = {};
  final Map<int, String?> _selectedExerciseSuperSets = {};
  List<Exercise> _availableExercises = [];
  
  final Set<int> _multiSelect = {};
  bool _isMultiSelectMode = false;

  @override
  void initState() {
    super.initState();
    if (widget.routine != null) {
      _nameController.text = widget.routine!.name;
    }
    _loadExercisesAndRoutine();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadExercisesAndRoutine() async {
    final exercises = await DatabaseHelper.instance.getExercises();
    setState(() {
      _availableExercises = exercises;
    });

    if (widget.routine != null && widget.routine!.id != null) {
      final routineId = widget.routine!.id!;
      final routineExercises = await DatabaseHelper.instance.getExercisesForRoutine(routineId);
      final routineSets = await DatabaseHelper.instance.getRoutineExerciseSets(routineId);
      final routineSuperSets = await DatabaseHelper.instance.getRoutineExerciseSuperSets(routineId);
      
      setState(() {
        _selectedExercises.clear();
        _selectedExercises.addAll(routineExercises);
        
        for (var ex in routineExercises) {
          if (ex.id != null) {
            _selectedExerciseSets[ex.id!] = routineSets[ex.id!] ?? 1;
            _selectedExerciseSuperSets[ex.id!] = routineSuperSets[ex.id!];
          }
        }
      });
    }
  }

  String _translateMuscle(String muscle) {
    final isPt = TranslationManager.instance.currentLanguage == 'pt';
    const Map<String, String> muscleTranslationPt = {
      'Chest': 'Peito',
      'Back': 'Costas',
      'Shoulders': 'Ombros',
      'Biceps': 'Bíceps',
      'Triceps': 'Tríceps',
      'Quadriceps': 'Quadríceps (Frente da coxa)',
      'Hamstrings': 'Isquiotibiais (Atrás da coxa)',
      'Adductors': 'Adutores (Parte interna)',
      'Glutes': 'Glúteos',
      'Calves': 'Panturrilha',
      'Core': 'Abdômen',
    };
    const Map<String, String> muscleTranslationEn = {
      'Chest': 'Chest',
      'Back': 'Back',
      'Shoulders': 'Shoulders',
      'Biceps': 'Biceps',
      'Triceps': 'Triceps',
      'Quadriceps': 'Quadriceps (Front thigh)',
      'Hamstrings': 'Hamstrings (Back thigh)',
      'Adductors': 'Adductors (Inner thigh)',
      'Glutes': 'Glutes',
      'Calves': 'Calves',
      'Core': 'Core',
    };
    return (isPt ? muscleTranslationPt[muscle] : muscleTranslationEn[muscle]) ?? muscle;
  }

  void _addExercise() async {
    final Exercise? selected = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ExerciseLibraryScreen(isSelector: true),
      ),
    );

    if (selected != null) {
      setState(() {
        if (!_selectedExercises.any((e) => e.id == selected.id)) {
          _selectedExercises.add(selected);
          _selectedExerciseSets[selected.id!] = 1;
          _selectedExerciseSuperSets[selected.id!] = null;
        }
      });
    }
  }

  void _replaceExercise(int indexToReplace) async {
    final Exercise? selected = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ExerciseLibraryScreen(isSelector: true),
      ),
    );

    if (selected != null) {
      setState(() {
        final oldEx = _selectedExercises[indexToReplace];
        _selectedExerciseSets.remove(oldEx.id);
        _selectedExerciseSuperSets.remove(oldEx.id);
        
        _selectedExercises[indexToReplace] = selected;
        _selectedExerciseSets[selected.id!] = 1;
        _selectedExerciseSuperSets[selected.id!] = null;
      });
    }
  }

  void _createSuperSet() {
    if (_multiSelect.length < 2) return;

    final superSetId = const Uuid().v4();
    setState(() {
      for (var id in _multiSelect) {
        _selectedExerciseSuperSets[id] = superSetId;
      }
      _isMultiSelectMode = false;
      _multiSelect.clear();
    });
  }

  void _ungroupSuperSet(String? superSetId) {
    if (superSetId == null) return;
    setState(() {
      _selectedExerciseSuperSets.forEach((exId, sid) {
        if (sid == superSetId) {
          _selectedExerciseSuperSets[exId] = null;
        }
      });
    });
  }

  Future<void> _saveRoutine() async {
    final tm = TranslationManager.instance;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tm.translate('cr_please_enter_name'))));
      return;
    }
    if (_selectedExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tm.translate('cr_please_add_exercises'))));
      return;
    }

    Map<int, int> exerciseSets = {};
    for (var e in _selectedExercises) {
      exerciseSets[e.id!] = _selectedExerciseSets[e.id!] ?? 1;
    }

    if (widget.routine != null) {
      final updatedRoutine = Routine(
        id: widget.routine!.id,
        name: name,
        description: widget.routine!.description,
      );
      await DatabaseHelper.instance.updateRoutine(updatedRoutine, exerciseSets, exerciseSuperSets: _selectedExerciseSuperSets);
    } else {
      final newRoutine = Routine(name: name, description: '');
      await DatabaseHelper.instance.insertRoutine(newRoutine, exerciseSets, exerciseSuperSets: _selectedExerciseSuperSets);
    }
    
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tm = TranslationManager.instance;
    final isPt = tm.currentLanguage == 'pt';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.routine != null ? (isPt ? 'Editar Rotina' : 'Edit Routine') : tm.translate('wk_new_routine')),
        actions: [
          if (_isMultiSelectMode)
             TextButton(
               onPressed: _multiSelect.length >= 2 ? _createSuperSet : null,
               child: Text(tm.translate('cr_group_superset'), style: TextStyle(color: _multiSelect.length >= 2 ? Colors.blue : Colors.grey)),
             ),
          if (!_isMultiSelectMode && _selectedExercises.length >= 2)
            IconButton(
              icon: const Icon(Icons.link),
              onPressed: () => setState(() => _isMultiSelectMode = true),
              tooltip: tm.translate('cr_group_superset'),
            ),
          TextButton(
            onPressed: _saveRoutine,
            child: Text(tm.translate('prof_save'), style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: tm.translate('cr_name_placeholder'),
                border: InputBorder.none,
                hintStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _selectedExercises.isEmpty
                  ? Center(child: Text(isPt ? 'Nenhum exercício adicionado.' : 'No exercises added.', style: const TextStyle(color: Colors.grey)))
                  : ReorderableListView.builder(
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (oldIndex < newIndex) {
                            newIndex -= 1;
                          }
                          final item = _selectedExercises.removeAt(oldIndex);
                          _selectedExercises.insert(newIndex, item);
                        });
                      },
                      itemCount: _selectedExercises.length,
                      itemBuilder: (context, index) {
                        final exercise = _selectedExercises[index];
                        final superSetId = _selectedExerciseSuperSets[exercise.id!];
                        final isInSuperSet = superSetId != null;

                        // Check if it's the start or end of a superset block for visual connection
                        bool isStart = false;
                        bool isEnd = false;
                        if (isInSuperSet) {
                           if (index == 0 || _selectedExerciseSuperSets[_selectedExercises[index-1].id!] != superSetId) isStart = true;
                           if (index == _selectedExercises.length - 1 || _selectedExerciseSuperSets[_selectedExercises[index+1].id!] != superSetId) isEnd = true;
                        }

                        return Container(
                          key: ValueKey('${exercise.id}_$index'),
                          margin: EdgeInsets.only(bottom: isInSuperSet && !isEnd ? 0 : 8),
                          decoration: BoxDecoration(
                            color: _multiSelect.contains(exercise.id) ? Colors.blue.withOpacity(0.2) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              if (isInSuperSet)
                                Container(
                                  width: 4,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.vertical(
                                      top: isStart ? const Radius.circular(2) : Radius.zero,
                                      bottom: isEnd ? const Radius.circular(2) : Radius.zero,
                                    ),
                                  ),
                                ),
                              Expanded(
                                child: ListTile(
                                  onLongPress: () {
                                    setState(() {
                                      _isMultiSelectMode = true;
                                      _multiSelect.add(exercise.id!);
                                    });
                                  },
                                  onTap: _isMultiSelectMode ? () {
                                    setState(() {
                                      if (_multiSelect.contains(exercise.id)) {
                                        _multiSelect.remove(exercise.id);
                                        if (_multiSelect.isEmpty) _isMultiSelectMode = false;
                                      } else {
                                        _multiSelect.add(exercise.id!);
                                      }
                                    });
                                  } : null,
                                  leading: _isMultiSelectMode 
                                      ? Checkbox(
                                          value: _multiSelect.contains(exercise.id),
                                          onChanged: (val) {
                                            setState(() {
                                              if (val == true) {
                                                _multiSelect.add(exercise.id!);
                                              } else {
                                                _multiSelect.remove(exercise.id);
                                                if (_multiSelect.isEmpty) _isMultiSelectMode = false;
                                              }
                                            });
                                          },
                                        )
                                      : const Icon(Icons.fitness_center),
                                  title: Text(exercise.translatedName),
                                  subtitle: Text(_translateMuscle(exercise.muscleGroup)),
                                  trailing: _isMultiSelectMode ? null : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isInSuperSet && isStart)
                                        IconButton(
                                          icon: const Icon(Icons.link_off, color: Colors.grey),
                                          tooltip: tm.translate('cr_ungroup'),
                                          onPressed: () => _ungroupSuperSet(superSetId),
                                        ),
                                      IconButton(
                                        icon: const Icon(Icons.swap_horiz, color: Colors.blue),
                                        tooltip: isPt ? 'Substituir' : 'Replace',
                                        onPressed: () => _replaceExercise(index),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.close, color: Colors.red[400]),
                                        tooltip: isPt ? 'Remover' : 'Remove',
                                        onPressed: () {
                                          setState(() {
                                            _selectedExercises.removeAt(index);
                                            _selectedExerciseSets.remove(exercise.id);
                                            _selectedExerciseSuperSets.remove(exercise.id);
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addExercise,
                icon: const Icon(Icons.add),
                label: Text(tm.translate('cr_add_exercise')),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  foregroundColor: Colors.blue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

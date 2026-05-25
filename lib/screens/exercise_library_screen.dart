import 'dart:convert';
import 'package:flutter/material.dart';
import '../managers/translation_manager.dart';
import '../managers/exercise_translator.dart';
import '../db/database_helper.dart';
import '../models/exercise.dart';
import 'exercise_library_detail_screen.dart';
import 'exercise_detail_screen.dart';

class ExerciseLibraryScreen extends StatefulWidget {
  final bool isSelector;
  const ExerciseLibraryScreen({super.key, this.isSelector = false});

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> with SingleTickerProviderStateMixin {
  List<dynamic> _allLibraryExercises = [];
  List<Exercise> _myExercises = [];
  List<dynamic> _filteredExercises = [];
  Set<String> _importedExerciseNames = {};
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedMuscle = 'All';
  String _selectedEquipment = 'All';
  late TabController _tabController;

  final TextEditingController _searchController = TextEditingController();

  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _filterExercises();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isFirstLoad) {
      _loadData();
      _isFirstLoad = false;
    }
  }

  Future<void> _loadData() async {
    try {
      // Load JSON
      final jsonString = await DefaultAssetBundle.of(context).loadString('assets/exercises.json');
      final List<dynamic> libraryData = json.decode(jsonString);

      // Load local exercises
      final localExercises = await DatabaseHelper.instance.getExercises();
      final localNames = localExercises.map((e) => e.name.toLowerCase()).toSet();

      if (mounted) {
        setState(() {
          _allLibraryExercises = libraryData;
          _myExercises = localExercises;
          _importedExerciseNames = localNames;
          _isLoading = false;
          _filterExercises();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      debugPrint('Error loading exercise library: $e');
    }
  }

  void _filterExercises() {
    setState(() {
      if (_tabController.index == 0) {
        // Library Tab
        final tm = TranslationManager.instance;
        _filteredExercises = _allLibraryExercises.where((ex) {
          final rawName = ex['name'].toString();
          final translatedName = ExerciseTranslator.translateName(rawName, tm.currentLanguage);
          final queryLower = _searchQuery.toLowerCase();
          
          final nameMatch = rawName.toLowerCase().contains(queryLower) || 
                            translatedName.toLowerCase().contains(queryLower);
          
          bool muscleMatch = true;
          if (_selectedMuscle != 'All') {
            final primaryMuscles = (ex['primaryMuscles'] as List<dynamic>).map((m) => m.toString().toLowerCase()).toList();
            muscleMatch = false;
            final selected = _selectedMuscle.toLowerCase();

            for (var muscle in primaryMuscles) {
              if (selected == 'biceps' && muscle.contains('biceps')) muscleMatch = true;
              else if (selected == 'triceps' && muscle.contains('triceps')) muscleMatch = true;
              else if (selected == 'chest' && muscle.contains('chest')) muscleMatch = true;
              else if (selected == 'back' && (muscle.contains('back') || muscle.contains('lats') || muscle.contains('traps'))) muscleMatch = true;
              else if (selected == 'shoulders' && muscle.contains('shoulders')) muscleMatch = true;
              else if (selected == 'quadriceps' && muscle.contains('quadriceps')) muscleMatch = true;
              else if (selected == 'hamstrings' && muscle.contains('hamstrings')) muscleMatch = true;
              else if (selected == 'adductors' && muscle.contains('adductors')) muscleMatch = true;
              else if (selected == 'glutes' && muscle.contains('glutes')) muscleMatch = true;
              else if (selected == 'calves' && muscle.contains('calves')) muscleMatch = true;
              else if (selected == 'core' && muscle.contains('abdominals')) muscleMatch = true;
            }
          }

          bool equipmentMatch = true;
          if (_selectedEquipment != 'All') {
            equipmentMatch = (ex['equipment']?.toString() ?? '').toLowerCase() == _selectedEquipment.toLowerCase();
          }

          return nameMatch && muscleMatch && equipmentMatch;
        }).toList();
      } else {
        // My Exercises Tab
        _filteredExercises = _myExercises.where((ex) {
          final nameMatch = ex.name.toLowerCase().contains(_searchQuery.toLowerCase());
          
          bool muscleMatch = true;
          if (_selectedMuscle != 'All') {
            muscleMatch = ex.muscleGroup.toLowerCase() == _selectedMuscle.toLowerCase();
            // Core mapping
            if (!muscleMatch && _selectedMuscle.toLowerCase() == 'core') {
               muscleMatch = ex.muscleGroup.toLowerCase() == 'abdominals';
            }
          }

          bool equipmentMatch = true;
          if (_selectedEquipment != 'All' && ex.equipment != null) {
            equipmentMatch = ex.equipment!.toLowerCase() == _selectedEquipment.toLowerCase();
          }

          return nameMatch && muscleMatch && equipmentMatch;
        }).toList();
      }
    });
  }

  void _showAddExerciseDialog() {
    final tm = TranslationManager.instance;
    final isPt = tm.currentLanguage == 'pt';
    final nameController = TextEditingController();
    String selectedMuscle = 'Chest';

    final muscles = [
      'Chest', 'Back', 'Shoulders', 'Biceps', 'Triceps', 
      'Quadriceps', 'Hamstrings', 'Adductors', 'Glutes', 'Calves', 'Core'
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isPt ? 'Novo Exercício Personalizado' : 'New Custom Exercise'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(hintText: isPt ? 'Nome do exercício' : 'Exercise name'),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              DropdownButton<String>(
                value: selectedMuscle,
                isExpanded: true,
                items: muscles.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedMuscle = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(tm.translate('act_cancel'))),
            TextButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  final newEx = Exercise(name: name, muscleGroup: selectedMuscle);
                  final savedEx = await DatabaseHelper.instance.insertExercise(newEx);
                  if (mounted) {
                    Navigator.pop(context);
                    if (widget.isSelector) {
                      Navigator.pop(context, savedEx);
                    } else {
                      _loadData();
                    }
                  }
                }
              },
              child: Text(tm.translate('prof_save')),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tm = TranslationManager.instance;
    final isPt = tm.currentLanguage == 'pt';

    final List<String> muscleFilters = [
      'All',
      'Chest',
      'Back',
      'Shoulders',
      'Biceps',
      'Triceps',
      'Quadriceps',
      'Hamstrings',
      'Adductors',
      'Glutes',
      'Calves',
      'Core',
    ];

    final List<String> equipmentFilters = ['All'];
    final Set<String> equipments = {};
    for (var ex in _allLibraryExercises) {
      final eq = ex['equipment']?.toString();
      if (eq != null && eq.isNotEmpty) equipments.add(eq);
    }
    equipmentFilters.addAll(equipments.toList()..sort());

    const Map<String, String> muscleTranslationPt = {
      'All': 'Todos Músculos',
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

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(tm.translate('nav_exercises')),
        backgroundColor: Colors.black,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: isPt ? 'Biblioteca' : 'Library'),
            Tab(text: isPt ? 'Meus Exercícios' : 'My Exercises'),
          ],
        ),
        actions: [
          if (!widget.isSelector)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showAddExerciseDialog,
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                _searchQuery = val;
                _filterExercises();
              },
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: tm.translate('ex_search_library'),
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // Filters row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                DropdownButton<String>(
                  value: _selectedMuscle,
                  dropdownColor: Colors.grey[900],
                  underline: Container(),
                  icon: const Icon(Icons.filter_list, color: Colors.blue, size: 16),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  items: muscleFilters.map((m) {
                    return DropdownMenuItem(
                      value: m,
                      child: Text(isPt ? (muscleTranslationPt[m] ?? m) : m),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedMuscle = val);
                      _filterExercises();
                    }
                  },
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _selectedEquipment,
                  dropdownColor: Colors.grey[900],
                  underline: Container(),
                  icon: const Icon(Icons.fitness_center, color: Colors.blue, size: 16),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  items: equipmentFilters.map((e) {
                    String label = e;
                    if (e == 'All') label = tm.translate('ex_all_equipment');
                    else if (e.isEmpty) label = tm.translate('ex_none');
                    else label = e.toUpperCase();
                    
                    return DropdownMenuItem(
                      value: e,
                      child: Text(label),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedEquipment = val);
                      _filterExercises();
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredExercises.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isPt ? 'Nenhum exercício encontrado.' : 'No exercises found.',
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _showAddExerciseDialog,
                              icon: const Icon(Icons.add),
                              label: Text(isPt ? 'Adicionar Personalizado' : 'Add Custom'),
                            )
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredExercises.length,
                        itemBuilder: (context, index) {
                          final item = _filteredExercises[index];
                          
                          if (_tabController.index == 0) {
                            // Library Item
                            final ex = item as Map<String, dynamic>;
                            final String rawName = ex['name'];
                            final String translatedName = ExerciseTranslator.translateName(rawName, tm.currentLanguage);
                            
                            final List<dynamic> primary = ex['primaryMuscles'];
                            final String muscleText = primary.join(', ');
                            final String level = ex['level']?.toString() ?? '';
                            final String force = ex['force']?.toString() ?? '';
                            final String? imgPath = ex['images'] != null && (ex['images'] as List).isNotEmpty ? ex['images'][0] : null;
                            final isImported = _importedExerciseNames.contains(rawName.toLowerCase()) || 
                                               _importedExerciseNames.contains(translatedName.toLowerCase());

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              leading: _buildImageThumbnail(imgPath),
                              title: Text(
                                translatedName,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    muscleText.toUpperCase(),
                                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      if (level.isNotEmpty) ...[
                                        _buildSmallBadge(level.toUpperCase(), Colors.orange),
                                        const SizedBox(width: 4),
                                      ],
                                      if (force.isNotEmpty) 
                                        _buildSmallBadge(tm.translate('ex_$force').toUpperCase(), Colors.blue),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: isImported
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        tm.translate('ex_imported'),
                                        style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    )
                                  : const Icon(Icons.chevron_right, color: Colors.grey),
                              onTap: () async {
                                if (widget.isSelector && isImported) {
                                  final exLocal = _myExercises.firstWhere((e) => 
                                    e.name.toLowerCase() == rawName.toLowerCase() || 
                                    e.name.toLowerCase() == translatedName.toLowerCase());
                                  Navigator.pop(context, exLocal);
                                } else {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ExerciseLibraryDetailScreen(
                                        exerciseData: ex,
                                        isAlreadyImported: isImported,
                                        onImportSuccess: () {
                                          _loadData();
                                        },
                                      ),
                                    ),
                                  );
                                  if (widget.isSelector) {
                                    _loadData(); // To check if it was imported and then select it? 
                                    // Actually, if it's selector, it's better to auto-select after import.
                                    // But detail screen handles import.
                                  }
                                }
                              },
                            );
                          } else {
                            // My Exercise Item
                            final ex = item as Exercise;
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              leading: _buildImageThumbnail(ex.imagePath),
                              title: Text(
                                ex.name,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                ex.muscleGroup.toUpperCase(),
                                style: const TextStyle(color: Colors.grey, fontSize: 11),
                              ),
                              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                              onTap: () {
                                if (widget.isSelector) {
                                  Navigator.pop(context, ex);
                                } else {
                                  if (ex.libraryId != null) {
                                     final libEx = _allLibraryExercises.firstWhere((l) => l['id'] == ex.libraryId, orElse: () => null);
                                     if (libEx != null) {
                                       Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ExerciseLibraryDetailScreen(
                                              exerciseData: libEx,
                                              isAlreadyImported: true,
                                              onImportSuccess: _loadData,
                                            ),
                                          ),
                                        );
                                     }
                                  } else {
                                    // Custom Exercise
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ExerciseDetailScreen(exercise: ex),
                                      ),
                                    ).then((_) => _loadData());
                                  }
                                }
                              },
                            );
                          }
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 1 ? FloatingActionButton(
        onPressed: _showAddExerciseDialog,
        child: const Icon(Icons.add),
      ) : null,
    );
  }

  Widget _buildImageThumbnail(String? imgPath) {
    if (imgPath == null) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.fitness_center, color: Colors.white24, size: 20),
      );
    }
    final imgUrl = 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/$imgPath';
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Image.network(
          imgUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, size: 20),
        ),
      ),
    );
  }

  Widget _buildSmallBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }
}

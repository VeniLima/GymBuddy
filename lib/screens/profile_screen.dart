import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../db/database_helper.dart';
import '../models/exercise.dart';
import '../models/achievement.dart';
import '../managers/translation_manager.dart';
import '../managers/cardio_utils.dart';
import '../managers/achievement_manager.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  TranslationManager get tm => TranslationManager.instance;
  bool get isPt => tm.currentLanguage == 'pt';

  int _totalWorkouts = 0;
  int _thisMonthWorkouts = 0;
  Map<String, int> _muscleDistribution = {};
  
  List<Exercise> _allExercises = [];
  Exercise? _selectedExercise;
  List<Map<String, dynamic>> _exerciseHistory = [];
  
  double _height = 0;
  List<Map<String, dynamic>> _weightLogs = [];
  List<Map<String, dynamic>> _bodyMeasurements = [];
  String _selectedMeasurementType = 'prof_arm';
  List<String> _workoutDatesLast7Days = [];
  List<String> _workoutDatesCurrentMonth = [];
  
  Map<String, double> _cardioDailyTime = {};
  double _totalCardioTimeWeek = 0;
  double _totalCardioCaloriesWeek = 0;
  List<Achievement> _achievements = [];
  
  bool _isLoading = true;
  bool _enableRpe = false;
  bool _enableRestTimer = true;

  @override
  void initState() {
    super.initState();
    tm.addListener(_onLanguageChanged);
    _loadData();
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

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final prefs = await SharedPreferences.getInstance();
    final height = prefs.getDouble('user_height') ?? 0.0;
    
    final stats = await DatabaseHelper.instance.getWorkoutConsistencyStats();
    final dist = await DatabaseHelper.instance.getMuscleGroupDistribution(30);
    final exercises = await DatabaseHelper.instance.getExercises();
    final weightLogs = await DatabaseHelper.instance.getWeightLogs();
    final bodyMeasurements = await DatabaseHelper.instance.getBodyMeasurements();
    final last7Dates = await DatabaseHelper.instance.getWorkoutDatesLast7Days();
    final monthDates = await DatabaseHelper.instance.getWorkoutDatesCurrentMonth();
    final enableRpe = prefs.getBool('user_enable_rpe') ?? false;
    final enableRestTimer = prefs.getBool('user_enable_rest_timer') ?? true;

    // Load cardio data for the last 7 days
    final now = DateTime.now();
    final sevenDaysAgo = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
    final workouts = await DatabaseHelper.instance.getAllWorkoutsOrderedByDate();
    final recentWorkouts = workouts.where((w) => w.startTime.isAfter(sevenDaysAgo)).toList();
    
    Map<String, double> cardioTime = {};
    double totalTime = 0;
    double totalCals = 0;
    
    for (int i = 0; i <= 6; i++) {
      final date = sevenDaysAgo.add(Duration(days: i));
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      cardioTime[dateStr] = 0;
    }

    final exMap = {for (var e in exercises) e.id: e};

    for (var w in recentWorkouts) {
      final sets = await DatabaseHelper.instance.getSetsForWorkout(w.id!);
      final dateStr = '${w.startTime.year}-${w.startTime.month.toString().padLeft(2, '0')}-${w.startTime.day.toString().padLeft(2, '0')}';
      
      for (var s in sets) {
        final ex = exMap[s.exerciseId];
        if (ex?.category?.toLowerCase() == 'cardio' && s.isCompleted) {
          double mins = (s.durationSeconds ?? 0) / 60.0;
          if (cardioTime.containsKey(dateStr)) {
            cardioTime[dateStr] = cardioTime[dateStr]! + mins;
          }
          totalTime += mins;
          totalCals += s.distance ?? 0;
        }
      }
    }
    
    final achievements = await AchievementManager.instance.getUnlockedAchievements();

    setState(() {
      _height = height;
      _enableRpe = enableRpe;
      _enableRestTimer = enableRestTimer;
      _weightLogs = weightLogs;
      _bodyMeasurements = bodyMeasurements;
      _totalWorkouts = stats['total'] ?? 0;
      _thisMonthWorkouts = stats['thisMonth'] ?? 0;
      _muscleDistribution = dist;
      _allExercises = exercises;
      _workoutDatesLast7Days = last7Dates;
      _workoutDatesCurrentMonth = monthDates;
      _cardioDailyTime = cardioTime;
      _totalCardioTimeWeek = totalTime;
      _totalCardioCaloriesWeek = totalCals;
      _achievements = achievements;

      if (exercises.isNotEmpty) {
        if (_selectedExercise != null) {
          _selectedExercise = exercises.firstWhere(
            (e) => e.id == _selectedExercise!.id,
            orElse: () => exercises.first,
          );
        } else {
          _selectedExercise = exercises.first;
        }
      } else {
        _selectedExercise = null;
      }
      _isLoading = false;
    });
    
    if (_selectedExercise != null) {
      await _loadExerciseHistory(_selectedExercise!.id!);
    }
  }

  Future<void> _loadExerciseHistory(int exerciseId) async {
    final history = await DatabaseHelper.instance.getExercisePerformanceHistory(exerciseId);
    setState(() {
      _exerciseHistory = history;
    });
  }
  
  Future<void> _saveHeight(double height) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('user_height', height);
    _loadData();
  }

  Future<void> _addWeight(double weight) async {
    await DatabaseHelper.instance.insertWeightLog(weight);
    _loadData();
  }
  
  Future<void> _deleteWeight(int id) async {
    await DatabaseHelper.instance.deleteWeightLog(id);
    _loadData();
  }

  void _showAddMetricsDialog({bool isHeight = false}) {
    final controller = TextEditingController();
    final tm = TranslationManager.instance;
    final isPt = tm.currentLanguage == 'pt';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            isHeight 
                ? (isPt ? 'Definir Altura (cm)' : 'Set Height (cm)') 
                : (isPt ? 'Registrar Peso (kg)' : 'Log Weight (kg)'), 
            style: const TextStyle(color: Colors.white)
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: isHeight ? 'e.g. 175' : 'e.g. 70.5',
              hintStyle: TextStyle(color: Colors.grey[500]),
              enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(tm.translate('ex_cancel'), style: const TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              onPressed: () {
                final val = double.tryParse(controller.text.replaceAll(',', '.'));
                if (val != null && val > 0) {
                  if (isHeight) {
                    _saveHeight(val);
                  } else {
                    _addWeight(val);
                  }
                  Navigator.pop(context);
                }
              },
              child: Text(tm.translate('prof_save'), style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      }
    );
  }

  Future<void> _addMeasurement(String type, double value) async {
    await DatabaseHelper.instance.insertBodyMeasurement(type, value);
    _loadData();
  }
  
  Future<void> _deleteMeasurement(int id) async {
    await DatabaseHelper.instance.deleteBodyMeasurement(id);
    _loadData();
  }

  void _showAddMeasurementDialog() {
    final controller = TextEditingController();
    final tm = TranslationManager.instance;
    String selectedType = 'prof_arm';
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              title: Text(tm.translate('prof_log_measurement'), style: const TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonHideUnderline(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<String>(
                        value: selectedType,
                        isExpanded: true,
                        dropdownColor: Colors.grey[800],
                        style: const TextStyle(color: Colors.white),
                        items: [
                          DropdownMenuItem(value: 'prof_arm', child: Text(tm.translate('prof_arm'))),
                          DropdownMenuItem(value: 'prof_waist', child: Text(tm.translate('prof_waist'))),
                          DropdownMenuItem(value: 'prof_thigh', child: Text(tm.translate('prof_thigh'))),
                          DropdownMenuItem(value: 'prof_chest', child: Text(tm.translate('prof_chest'))),
                          DropdownMenuItem(value: 'prof_calf', child: Text(tm.translate('prof_calf'))),
                        ],
                        onChanged: (val) {
                          if (val != null) setDialogState(() => selectedType = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'e.g. 40.5 (cm)',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(tm.translate('ex_cancel'), style: const TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  onPressed: () {
                    final val = double.tryParse(controller.text.replaceAll(',', '.'));
                    if (val != null && val > 0) {
                      _addMeasurement(selectedType, val);
                      Navigator.pop(context);
                    }
                  },
                  child: Text(tm.translate('prof_save'), style: const TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      }
    );
  }

  Color _getColorForMuscle(String muscle, int index) {
    final colors = [
      Colors.blue, Colors.red, Colors.green, Colors.orange, 
      Colors.purple, Colors.teal, Colors.pink, Colors.amber
    ];
    return colors[index % colors.length];
  }

  Widget _buildBodyMetricsSection() {
    double currentWeight = _weightLogs.isNotEmpty ? (_weightLogs.first['weight'] as num).toDouble() : 0.0;
    double bmi = 0;
    String bmiCategory = "-";
    Color bmiColor = Colors.grey;
    final tm = TranslationManager.instance;
    final isPt = tm.currentLanguage == 'pt';
    
    if (_height > 0 && currentWeight > 0) {
      double heightMeters = _height / 100;
      bmi = currentWeight / (heightMeters * heightMeters);
      if (bmi < 18.5) { bmiCategory = isPt ? "Abaixo do Peso" : "Underweight"; bmiColor = Colors.blue; }
      else if (bmi < 25) { bmiCategory = isPt ? "Peso Normal" : "Normal Weight"; bmiColor = Colors.green; }
      else if (bmi < 30) { bmiCategory = isPt ? "Sobrepeso" : "Overweight"; bmiColor = Colors.orange; }
      else { bmiCategory = isPt ? "Obesidade" : "Obese"; bmiColor = Colors.red; }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.withOpacity(0.12), Colors.blue.withOpacity(0.03)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isPt ? 'Métricas Corporais' : 'Body Metrics',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Row(
                children: [
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.edit, size: 14),
                    label: Text(tm.translate('prof_height'), style: const TextStyle(fontSize: 12)),
                    onPressed: () => _showAddMetricsDialog(isHeight: true),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.add, size: 14),
                    label: Text(tm.translate('prof_weight'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () => _showAddMetricsDialog(isHeight: false),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Weight
              Column(
                children: [
                  Text(tm.translate('prof_weight'), style: const TextStyle(color: Colors.white54, fontSize: 13)),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        currentWeight > 0 ? currentWeight.toStringAsFixed(1) : '--',
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                      const SizedBox(width: 2),
                      const Text('kg', style: TextStyle(color: Colors.white54, fontSize: 13)),
                    ],
                  ),
                ],
              ),
              // Divider
              Container(height: 35, width: 1, color: Colors.white12),
              // Height
              Column(
                children: [
                  Text(tm.translate('prof_height'), style: const TextStyle(color: Colors.white54, fontSize: 13)),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        _height > 0 ? _height.toStringAsFixed(0) : '--',
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                      const SizedBox(width: 2),
                      const Text('cm', style: TextStyle(color: Colors.white54, fontSize: 13)),
                    ],
                  ),
                ],
              ),
              // Divider
              Container(height: 35, width: 1, color: Colors.white12),
              // BMI
              Column(
                children: [
                  Text(tm.translate('prof_bmi'), style: const TextStyle(color: Colors.white54, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text(
                    bmi > 0 ? bmi.toStringAsFixed(1) : '--',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: bmi > 0 ? bmiColor : Colors.white),
                  ),
                ],
              ),
            ],
          ),
          if (bmi > 0) ...[
            const SizedBox(height: 16),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: bmiColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: bmiColor.withOpacity(0.3)),
                ),
                child: Text(
                  bmiCategory,
                  style: TextStyle(
                    color: bmiColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    final tm = TranslationManager.instance;
    final isPt = tm.currentLanguage == 'pt';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.language, color: Colors.blue, size: 20),
              const SizedBox(width: 12),
              Text(
                tm.translate('prof_language'),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                isPt ? 'Português' : 'English',
                style: const TextStyle(fontSize: 13, color: Colors.blue, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.blue),
                onSelected: (String lang) {
                  tm.setLanguage(lang);
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem(value: 'pt', child: Text('Português')),
                  const PopupMenuItem(value: 'en', child: Text('English')),
                ],
                color: Colors.grey[900],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRpeToggle() {
    final tm = TranslationManager.instance;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                const Icon(Icons.speed, color: Colors.blue, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tm.translate('prof_enable_rpe'),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tm.translate('prof_enable_rpe_desc'),
                        style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _enableRpe,
            activeColor: Colors.blue,
            onChanged: (bool value) async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('user_enable_rpe', value);
              setState(() {
                _enableRpe = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRestTimerSettings() {
    final tm = TranslationManager.instance;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, color: Colors.blue, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tm.translate('prof_enable_timer'),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tm.translate('prof_enable_timer_desc'),
                        style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _enableRestTimer,
            activeColor: Colors.blue,
            onChanged: (bool value) async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('user_enable_rest_timer', value);
              setState(() {
                _enableRestTimer = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Future<void> _exportWorkoutHistoryCSV() async {
    final isPt = tm.currentLanguage == 'pt';
    try {
      final history = await DatabaseHelper.instance.getRawWorkoutSetsHistory();
      if (history.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isPt ? 'Nenhum histórico de treino para exportar.' : 'No workout history to export.'),
        ));
        return;
      }

      final csvBuffer = StringBuffer();
      // CSV Header
      csvBuffer.writeln('Date,Workout Name,Exercise Name,Set Type,Weight (kg),Reps,RPE');
      
      for (var row in history) {
        final date = row['date'] ?? '';
        final workoutName = '"${(row['workoutName'] ?? '').replaceAll('"', '""')}"';
        final exerciseName = '"${(row['exerciseName'] ?? '').replaceAll('"', '""')}"';
        final setType = row['setType'] ?? '';
        final weight = row['weight'] ?? 0.0;
        final reps = row['reps'] ?? 0;
        final rpe = row['rpe'] ?? '';
        csvBuffer.writeln('$date,$workoutName,$exerciseName,$setType,$weight,$reps,$rpe');
      }

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/gymbuddy_history.csv');
      await file.writeAsString(csvBuffer.toString(), encoding: utf8);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: isPt ? 'Histórico de Treinos GymBuddy' : 'GymBuddy Workout History',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isPt ? 'Erro ao exportar CSV: $e' : 'Error exporting CSV: $e'),
      ));
    }
  }

  Future<void> _exportBackupJSON() async {
    final isPt = tm.currentLanguage == 'pt';
    try {
      final backupData = await DatabaseHelper.instance.exportToMap();
      final jsonString = jsonEncode(backupData);

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/gymbuddy_backup.json');
      await file.writeAsString(jsonString, encoding: utf8);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: isPt ? 'Backup GymBuddy' : 'GymBuddy Backup',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isPt ? 'Erro ao exportar Backup: $e' : 'Error exporting Backup: $e'),
      ));
    }
  }

  Future<void> _restoreBackupJSON() async {
    final isPt = tm.currentLanguage == 'pt';
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          isPt ? 'Aviso Importante!' : 'Important Notice!',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          isPt
              ? 'Restaurar um backup substituirá todos os seus dados atuais (rotinas, histórico, logs de peso). Esta ação é irreversível. Deseja continuar?'
              : 'Restoring a backup will replace all your current data (routines, history, weight logs). This action cannot be undone. Do you want to continue?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(isPt ? 'Cancelar' : 'Cancel', style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(isPt ? 'Substituir Tudo' : 'Replace All', style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) {
        return;
      }

      final file = File(result.files.single.path!);
      final content = await file.readAsString(encoding: utf8);
      final data = jsonDecode(content);

      if (data is! Map<String, dynamic> || !data.containsKey('workouts')) {
        throw FormatException(isPt ? 'Formato de arquivo inválido.' : 'Invalid file format.');
      }

      await DatabaseHelper.instance.restoreFromMap(data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isPt ? 'Dados restaurados com sucesso!' : 'Data restored successfully!'),
          backgroundColor: Colors.green,
        ));
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isPt ? 'Erro ao restaurar backup: $e' : 'Error restoring backup: $e'),
          backgroundColor: Colors.redAccent,
        ));
      }
    }
  }

  Widget _buildBackupExportSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.backup_outlined, color: Colors.blue, size: 20),
              const SizedBox(width: 12),
              Text(
                tm.translate('prof_backup_section'),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _exportWorkoutHistoryCSV,
                  icon: const Icon(Icons.download, size: 16),
                  label: Text(tm.translate('prof_backup_csv'), style: const TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Colors.blue.withOpacity(0.15),
                    foregroundColor: Colors.blue,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _exportBackupJSON,
                  icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                  label: Text(tm.translate('prof_backup_json'), style: const TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Colors.blue.withOpacity(0.15),
                    foregroundColor: Colors.blue,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _restoreBackupJSON,
                  icon: const Icon(Icons.cloud_download_outlined, size: 16),
                  label: Text(tm.translate('prof_backup_restore'), style: const TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Colors.green.withOpacity(0.15),
                    foregroundColor: Colors.green,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeightHistorySection() {
    if (_weightLogs.isEmpty) return const SizedBox.shrink();
    final tm = TranslationManager.instance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tm.translate('prof_weight_history'), style: const TextStyle(fontSize: 16, color: Colors.white70)),
        const SizedBox(height: 16),
        // Weight Line Chart
        if (_weightLogs.length > 1)
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text('${value.toInt()}', style: const TextStyle(color: Colors.grey, fontSize: 10));
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _weightLogs.reversed.toList().asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), (entry.value['weight'] as num).toDouble());
                    }).toList(),
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.1)),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        // Recent Logs List
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _weightLogs.length > 5 ? 5 : _weightLogs.length,
          itemBuilder: (context, index) {
            final log = _weightLogs[index];
            final date = DateTime.parse(log['date']);
            final dateStr = DateFormat('MMM d, yyyy - HH:mm', tm.currentLanguage).format(date);
            
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.circle, size: 12, color: Colors.blue),
              title: Text('${(log['weight'] as num).toDouble()} kg', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text(dateStr, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                onPressed: () => _deleteWeight(log['id']),
              ),
            );
          },
        )
      ],
    );
  }

  Widget _buildBodyMeasurementsSection() {
    final tm = TranslationManager.instance;
    final filteredMeasurements = _bodyMeasurements.where((m) => m['type'] == _selectedMeasurementType).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(tm.translate('prof_measurements'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            TextButton(
              onPressed: _showAddMeasurementDialog,
              child: Text(tm.translate('prof_log_measurement'), style: const TextStyle(color: Colors.blue)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedMeasurementType,
              isExpanded: true,
              dropdownColor: Colors.grey[900],
              style: const TextStyle(color: Colors.white),
              items: [
                DropdownMenuItem(value: 'prof_arm', child: Text(tm.translate('prof_arm'))),
                DropdownMenuItem(value: 'prof_waist', child: Text(tm.translate('prof_waist'))),
                DropdownMenuItem(value: 'prof_thigh', child: Text(tm.translate('prof_thigh'))),
                DropdownMenuItem(value: 'prof_chest', child: Text(tm.translate('prof_chest'))),
                DropdownMenuItem(value: 'prof_calf', child: Text(tm.translate('prof_calf'))),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedMeasurementType = val);
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (filteredMeasurements.length > 1)
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text('${value.toInt()}', style: const TextStyle(color: Colors.grey, fontSize: 10));
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: filteredMeasurements.reversed.toList().asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), (entry.value['value'] as num).toDouble());
                    }).toList(),
                    isCurved: true,
                    color: Colors.orange,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(show: true, color: Colors.orange.withOpacity(0.1)),
                  ),
                ],
              ),
            ),
          )
        else if (filteredMeasurements.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(tm.translate('stats_no_data'), style: const TextStyle(color: Colors.white54)),
          ),
        const SizedBox(height: 16),
        if (filteredMeasurements.isNotEmpty) ...[
          Text(tm.translate('prof_measurement_history'), style: const TextStyle(fontSize: 16, color: Colors.white70)),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredMeasurements.length > 5 ? 5 : filteredMeasurements.length,
            itemBuilder: (context, index) {
              final log = filteredMeasurements[index];
              final date = DateTime.parse(log['date']);
              final dateStr = DateFormat('MMM d, yyyy - HH:mm', tm.currentLanguage).format(date);
              
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.circle, size: 12, color: Colors.orange),
                title: Text('${(log['value'] as num).toDouble()} cm', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text(dateStr, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: () => _deleteMeasurement(log['id']),
                ),
              );
            },
          )
        ]
      ],
    );
  }

  Widget _buildConsistencyStreak() {
    final now = DateTime.now();
    final tm = TranslationManager.instance;
    
    // Gera os últimos 7 dias (da esquerda para a direita: mais antigo -> hoje)
    final last7Days = List.generate(7, (index) {
      return DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - index));
    });

    // Converte as datas salvas no banco de dados para apenas a data sem hora (yyyy-MM-dd)
    final Set<String> trainedDates = _workoutDatesLast7Days.map((dateStr) {
      final date = DateTime.parse(dateStr);
      return DateFormat('yyyy-MM-dd').format(date);
    }).toSet();

    String getWeekdayAbbreviation(int weekday) {
      final isPt = tm.currentLanguage == 'pt';
      final abbrevPt = {1: 'Seg', 2: 'Ter', 3: 'Qua', 4: 'Qui', 5: 'Sex', 6: 'Sáb', 7: 'Dom'};
      final abbrevEn = {1: 'Mon', 2: 'Tue', 3: 'Wed', 4: 'Thu', 5: 'Fri', 6: 'Sat', 7: 'Sun'};
      return (isPt ? abbrevPt[weekday] : abbrevEn[weekday]) ?? '';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tm.translate('prof_last_7_days'),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: last7Days.map((day) {
              final dateKey = DateFormat('yyyy-MM-dd').format(day);
              final isTrained = trainedDates.contains(dateKey);
              final isToday = day.year == now.year && day.month == now.month && day.day == now.day;
              
              return Column(
                children: [
                  Text(
                    getWeekdayAbbreviation(day.weekday),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      color: isToday ? Colors.blue : Colors.white60,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isTrained 
                          ? Colors.blue.withOpacity(0.2) 
                          : Colors.white.withOpacity(0.04),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isTrained 
                            ? Colors.blue 
                            : (isToday ? Colors.blue.withOpacity(0.4) : Colors.white10),
                        width: isTrained ? 2 : 1,
                      ),
                      boxShadow: isTrained ? [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ] : null,
                    ),
                    alignment: Alignment.center,
                    child: isTrained 
                        ? const Icon(Icons.check, color: Colors.blue, size: 18)
                        : Text(
                            day.day.toString(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                              color: isToday ? Colors.blue : Colors.grey[500],
                            ),
                          ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyCalendar() {
    final now = DateTime.now();
    final tm = TranslationManager.instance;
    final isPt = tm.currentLanguage == 'pt';
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final firstWeekday = DateTime(now.year, now.month, 1).weekday;
    final firstDayOffset = firstWeekday % 7; // Sunday = 0, Monday = 1, etc.
    
    // Converte as datas salvas no banco de dados para apenas a data sem hora (yyyy-MM-dd)
    final Set<String> trainedDates = _workoutDatesCurrentMonth.map((dateStr) {
      final date = DateTime.parse(dateStr);
      return DateFormat('yyyy-MM-dd').format(date);
    }).toSet();

    final List<String> weekdays = isPt ? ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'] : ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final totalGridItems = firstDayOffset + daysInMonth;

    String getMonthName(int month) {
      const monthsPt = {
        1: 'Janeiro',
        2: 'Fevereiro',
        3: 'Março',
        4: 'Abril',
        5: 'Maio',
        6: 'Junho',
        7: 'Julho',
        8: 'Agosto',
        9: 'Setembro',
        10: 'Outubro',
        11: 'Novembro',
        12: 'Dezembro',
      };
      const monthsEn = {
        1: 'January',
        2: 'February',
        3: 'March',
        4: 'April',
        5: 'May',
        6: 'June',
        7: 'July',
        8: 'August',
        9: 'September',
        10: 'October',
        11: 'November',
        12: 'December',
      };
      return (isPt ? monthsPt[month] : monthsEn[month]) ?? '';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isPt 
                    ? 'Calendário de ${getMonthName(now.month)}' 
                    : '${getMonthName(now.month)} Calendar',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tm.translate('prof_workouts_this_month', args: ['${_workoutDatesCurrentMonth.length}', _workoutDatesCurrentMonth.length == 1 ? '' : 's']),
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Dias da semana cabeçalho
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekdays.map((day) {
              return SizedBox(
                width: 32,
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          // Grid de dias do mês
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalGridItems,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (context, index) {
              if (index < firstDayOffset) {
                return const SizedBox.shrink();
              }
              
              final dayNumber = index - firstDayOffset + 1;
              final dayDate = DateTime(now.year, now.month, dayNumber);
              final dateKey = DateFormat('yyyy-MM-dd').format(dayDate);
              final isTrained = trainedDates.contains(dateKey);
              final isToday = dayNumber == now.day;

              return Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isTrained 
                      ? Colors.blue 
                      : (isToday ? Colors.white.withOpacity(0.04) : Colors.transparent),
                  shape: BoxShape.circle,
                  border: isTrained 
                      ? null 
                      : Border.all(
                          color: isToday 
                              ? Colors.blue.withOpacity(0.6) 
                              : Colors.white.withOpacity(0.05),
                          width: isToday ? 1.5 : 0.5,
                        ),
                  boxShadow: isTrained ? [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    )
                  ] : null,
                ),
                child: Text(
                  dayNumber.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: (isTrained || isToday) ? FontWeight.bold : FontWeight.normal,
                    color: isTrained 
                        ? Colors.white 
                        : (isToday ? Colors.blue : Colors.white60),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildConsistencyCards() {
    final tm = TranslationManager.instance;
    final isPt = tm.currentLanguage == 'pt';
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(isPt ? 'Total de Treinos' : 'Total Workouts', '$_totalWorkouts', Icons.fitness_center),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(isPt ? 'Este Mês' : 'This Month', '$_thisMonthWorkouts', Icons.calendar_month),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue, size: 24),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: Colors.blue.shade200, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildMuscleDistributionChart() {
    final tm = TranslationManager.instance;
    final isPt = tm.currentLanguage == 'pt';
    if (_muscleDistribution.isEmpty) {
      return Center(child: Text(isPt ? 'Sem dados para os últimos 30 dias.' : 'No data for the last 30 days.', style: const TextStyle(color: Colors.grey)));
    }

    int totalSets = _muscleDistribution.values.fold(0, (sum, val) => sum + val);
    
    int colorIndex = 0;
    List<PieChartSectionData> sections = _muscleDistribution.entries.map((entry) {
      final percentage = (entry.value / totalSets) * 100;
      final color = _getColorForMuscle(entry.key, colorIndex++);
      return PieChartSectionData(
        color: color,
        value: entry.value.toDouble(),
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 50,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: sections,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: _muscleDistribution.entries.toList().asMap().entries.map((mapEntry) {
            int idx = mapEntry.key;
            var entry = mapEntry.value;
            
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
            final displayMuscle = isPt ? (muscleTranslationPt[entry.key] ?? entry.key) : entry.key;

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 12, height: 12, color: _getColorForMuscle(entry.key, idx)),
                const SizedBox(width: 4),
                Text('$displayMuscle (${entry.value})', style: const TextStyle(color: Colors.white, fontSize: 12)),
              ],
            );
          }).toList(),
        )
      ],
    );
  }

  Widget _buildCardioSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tm.translate('prof_cardio_section'),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildCardioMetric(
                    tm.translate('prof_total_time'),
                    '${_totalCardioTimeWeek.toInt()} min',
                    Icons.timer_outlined,
                    Colors.greenAccent,
                  ),
                  Container(width: 1, height: 40, color: Colors.white10),
                  _buildCardioMetric(
                    tm.translate('prof_total_calories'),
                    '${_totalCardioCaloriesWeek.toInt()} kcal',
                    Icons.local_fire_department_outlined,
                    Colors.orangeAccent,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 140,
                child: _buildCardioBarChart(),
              ),
              const SizedBox(height: 12),
              Text(
                tm.translate('prof_weekly_cardio'),
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardioMetric(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }

  Widget _buildCardioBarChart() {
    final sortedKeys = _cardioDailyTime.keys.toList()..sort();
    double maxMins = 0;
    for (var m in _cardioDailyTime.values) {
       if (m > maxMins) maxMins = m;
    }
    if (maxMins < 30) maxMins = 30;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxMins * 1.2,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => Colors.grey[900]!,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rod.toY.toInt()} min',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                int idx = value.toInt();
                if (idx < 0 || idx >= sortedKeys.length) return const SizedBox();
                final date = DateTime.parse(sortedKeys[idx]);
                final days = isPt ? ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'] : ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(days[date.weekday % 7], style: const TextStyle(color: Colors.white38, fontSize: 11)),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(sortedKeys.length, (i) {
          final val = _cardioDailyTime[sortedKeys[i]]!;
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: val,
                color: val > 0 ? Colors.greenAccent : Colors.white.withOpacity(0.05),
                width: 16,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxMins * 1.2,
                  color: Colors.white.withOpacity(0.02),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildTrophyGallery() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tm.translate('ach_title'),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.8,
          ),
          itemCount: _achievements.length,
          itemBuilder: (context, index) {
            final ach = _achievements[index];
            return GestureDetector(
              onTap: () => _showAchievementDetail(ach),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(ach.isUnlocked ? 0.05 : 0.02),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: ach.isUnlocked ? ach.color.withOpacity(0.3) : Colors.white10,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      ach.isUnlocked ? ach.icon : Icons.lock_outline,
                      color: ach.isUnlocked ? ach.color : Colors.white24,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        tm.translate(ach.titleKey),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ach.isUnlocked ? Colors.white : Colors.white24,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showAchievementDetail(Achievement ach) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ach.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(ach.icon, color: ach.color, size: 60),
            ),
            const SizedBox(height: 24),
            Text(
              tm.translate(ach.titleKey),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              tm.translate(ach.descKey),
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (ach.isUnlocked)
              Text(
                tm.translate('ach_unlocked_at', args: [
                  '${ach.unlockedAt!.day}/${ach.unlockedAt!.month}/${ach.unlockedAt!.year}'
                ]),
                style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold),
              )
            else
              Column(
                children: [
                   Text(tm.translate('ach_how_to_unlock'), style: const TextStyle(color: Colors.grey, fontSize: 11)),
                   const SizedBox(height: 4),
                   const Icon(Icons.lock, color: Colors.grey, size: 16),
                ],
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceChart() {
    if (_allExercises.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButton<Exercise>(
          value: _selectedExercise,
          isExpanded: true,
          dropdownColor: Colors.grey[900],
          style: const TextStyle(color: Colors.white, fontSize: 16),
          underline: Container(height: 1, color: Colors.blue),
          items: _allExercises.map((e) {
            return DropdownMenuItem(
              value: e,
              child: Text(e.name),
            );
          }).toList(),
          onChanged: (Exercise? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedExercise = newValue;
              });
              _loadExerciseHistory(newValue.id!);
            }
          },
        ),
        const SizedBox(height: 24),
        if (_exerciseHistory.isEmpty)
          Center(child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Text(isPt ? 'Sem histórico para este exercício.' : 'No history for this exercise.', style: const TextStyle(color: Colors.grey)),
          ))
        else if (_exerciseHistory.length == 1)
          Center(child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Text(
              isPt 
                  ? 'Realize mais treinos com este exercício para gerar o gráfico de evolução.' 
                  : 'Perform more workouts with this exercise to generate the progress chart.', 
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ))
        else
          SizedBox(
            height: 250,
            child: LineChart(

              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1)),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), // Hide dates for simplicity
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text('${value.toInt()}kg', style: const TextStyle(color: Colors.grey, fontSize: 10));
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _exerciseHistory.asMap().entries.map((entry) {
                      double maxWeight = (entry.value['max_weight'] as num?)?.toDouble() ?? 0.0;
                      return FlSpot(entry.key.toDouble(), maxWeight);
                    }).toList(),
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blue.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final tm = TranslationManager.instance;
    final isPt = tm.currentLanguage == 'pt';

    return Scaffold(
      appBar: AppBar(
        title: Text(isPt ? 'Perfil e Progresso' : 'Profile & Progress'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildBodyMetricsSection(),
            const SizedBox(height: 16),
            _buildLanguageSelector(),
            const SizedBox(height: 16),
            _buildRpeToggle(),
            const SizedBox(height: 16),
            _buildRestTimerSettings(),
            const SizedBox(height: 16),
            _buildBackupExportSection(),
            const SizedBox(height: 24),

            // Cardio Dashboard
            if (_totalCardioTimeWeek > 0) ...[
              _buildCardioSection(),
              const SizedBox(height: 24),
            ],

            // Achievements
            _buildTrophyGallery(),
            const SizedBox(height: 24),
            
            Text(tm.translate('prof_consistency'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 16),
            _buildConsistencyStreak(),
            const SizedBox(height: 16),
            _buildMonthlyCalendar(),
            const SizedBox(height: 16),
            _buildConsistencyCards(),
            const SizedBox(height: 32),

            if (_weightLogs.isNotEmpty) ...[
              const Divider(color: Colors.white24),
              const SizedBox(height: 24),
              _buildWeightHistorySection(),
              const SizedBox(height: 32),
            ],

            const Divider(color: Colors.white24),
            const SizedBox(height: 24),
            _buildBodyMeasurementsSection(),
            const SizedBox(height: 32),
            
            Text(isPt ? 'Distribuição Muscular (30 dias)' : 'Muscle Distribution (30 days)', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 24),
            _buildMuscleDistributionChart(),
            const SizedBox(height: 32),
            
            Text(isPt ? 'Performance do Exercício (Carga Máxima)' : 'Exercise Performance (Max Weight)', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 16),
            _buildPerformanceChart(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/exercise.dart';
import '../db/database_helper.dart';
import '../managers/translation_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SetPerformance {
  final int id;
  final int reps;
  final double weight;
  final String setType;
  final double? rpe;
  final DateTime date;
  final String workoutName;
  final int workoutId;

  SetPerformance({
    required this.id,
    required this.reps,
    required this.weight,
    required this.setType,
    this.rpe,
    required this.date,
    required this.workoutName,
    required this.workoutId,
  });

  double get estimated1RM {
    if (reps <= 0) return 0.0;
    if (reps == 1) return weight;
    return weight * (1.0 + reps / 30.0);
  }

  double get volume => weight * reps;
}

class ExerciseDetailScreen extends StatefulWidget {
  final Exercise exercise;

  const ExerciseDetailScreen({super.key, required this.exercise});

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  bool _isLoading = true;
  List<SetPerformance> _performances = [];
  
  // Stats
  double _max1RM = 0.0;
  double _maxWeight = 0.0;
  int _maxWeightReps = 0;
  double _maxVolume = 0.0;
  double _maxVolumeWeight = 0.0;
  int _maxVolumeReps = 0;
  int _maxReps = 0;
  double _maxRepsWeight = 0.0;
  int? _customRestTime;

  TranslationManager get tm => TranslationManager.instance;

  @override
  void initState() {
    super.initState();
    _customRestTime = widget.exercise.restTimeSeconds;
    _loadStats();
  }

  Future<void> _loadStats() async {
    final raw = await DatabaseHelper.instance.getCompletedSetsWithWorkoutInfo(widget.exercise.id!);
    final parsed = raw.map((map) {
      return SetPerformance(
        id: map['id'] as int,
        reps: map['reps'] as int,
        weight: (map['weight'] as num).toDouble(),
        setType: map['setType'] as String? ?? 'Normal',
        rpe: map['rpe'] != null ? (map['rpe'] as num).toDouble() : null,
        date: DateTime.parse(map['startTime'] as String),
        workoutName: map['workoutName'] as String? ?? 'Treino',
        workoutId: map['workoutId'] as int,
      );
    }).toList();

    // Compute stats
    if (parsed.isNotEmpty) {
      _max1RM = parsed.map((p) => p.estimated1RM).reduce((a, b) => a > b ? a : b);
      
      final bestWeightSet = parsed.reduce((a, b) => a.weight > b.weight ? a : b);
      _maxWeight = bestWeightSet.weight;
      _maxWeightReps = bestWeightSet.reps;

      final bestVolumeSet = parsed.reduce((a, b) => a.volume > b.volume ? a : b);
      _maxVolume = bestVolumeSet.volume;
      _maxVolumeWeight = bestVolumeSet.weight;
      _maxVolumeReps = bestVolumeSet.reps;

      final bestRepsSet = parsed.reduce((a, b) => a.reps > b.reps ? a : b);
      _maxReps = bestRepsSet.reps;
      _maxRepsWeight = bestRepsSet.weight;
    }



    if (mounted) {
      setState(() {
        _performances = parsed;
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    final isPt = tm.currentLanguage == 'pt';
    final locale = isPt ? 'pt_BR' : 'en_US';
    return DateFormat('dd MMM yyyy', locale).format(date);
  }

  List<FlSpot> _getChartSpots(List<SetPerformance> sortedList) {
    final List<FlSpot> spots = [];
    for (int i = 0; i < sortedList.length; i++) {
      spots.add(FlSpot(i.toDouble(), sortedList[i].estimated1RM));
    }
    return spots;
  }

  List<SetPerformance> _getSortedWorkoutBestPerformances() {
    final Map<int, SetPerformance> bestPerWorkout = {};
    for (var perf in _performances) {
      final existing = bestPerWorkout[perf.workoutId];
      if (existing == null || perf.estimated1RM > existing.estimated1RM) {
        bestPerWorkout[perf.workoutId] = perf;
      }
    }
    return bestPerWorkout.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  @override
  Widget build(BuildContext context) {
    final isPt = tm.currentLanguage == 'pt';
    final displayMuscle = widget.exercise.muscleGroup; // Em exibição real, pode ser traduzido.
    
    // Mapeamento local simples para músculo na AppBar
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
    final muscleName = isPt ? (muscleTranslationPt[displayMuscle] ?? displayMuscle) : displayMuscle;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.exercise.translatedName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Text(
                muscleName,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          bottom: TabBar(
            labelColor: Colors.blueAccent,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blueAccent,
            tabs: [
              Tab(text: tm.translate('stats_tab_records')),
              Tab(text: tm.translate('stats_tab_chart')),
              Tab(text: tm.translate('stats_tab_history')),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
            : TabBarView(
                children: [
                  _buildStatsTab(),
                  _buildChartTab(),
                  _buildHistoryTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.fitness_center_rounded,
                size: 64,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              tm.translate('stats_no_data'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              tm.translate('stats_no_data_sub'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeDigital(int totalSeconds) {
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _showRestTimeDialog() async {
    final isPt = tm.currentLanguage == 'pt';
    final defaultRest = widget.exercise.getAutoRestSeconds();
    int currentSeconds = _customRestTime ?? defaultRest;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isCustom = _customRestTime != null;
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tm.translate('stats_rest_edit_title'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, size: 36, color: Colors.white70),
                        onPressed: () {
                          if (currentSeconds > 30) {
                            setModalState(() => currentSeconds -= 30);
                          }
                        },
                      ),
                      Text(
                        _formatTimeDigital(currentSeconds),
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, size: 36, color: Colors.white70),
                        onPressed: () {
                          if (currentSeconds < 300) {
                            setModalState(() => currentSeconds += 30);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      if (isCustom)
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                            ),
                            onPressed: () async {
                              final updated = Exercise(
                                id: widget.exercise.id,
                                name: widget.exercise.name,
                                muscleGroup: widget.exercise.muscleGroup,
                                restTimeSeconds: null,
                                notes: widget.exercise.notes,
                              );
                              await DatabaseHelper.instance.updateExercise(updated);
                              Navigator.pop(context);
                              setState(() {
                                _customRestTime = null;
                              });
                            },
                            child: Text(tm.translate('stats_rest_reset')),
                          ),
                        ),
                      if (isCustom) const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                          onPressed: () async {
                            final updated = Exercise(
                              id: widget.exercise.id,
                              name: widget.exercise.name,
                              muscleGroup: widget.exercise.muscleGroup,
                              restTimeSeconds: currentSeconds,
                              notes: widget.exercise.notes,
                            );
                            await DatabaseHelper.instance.updateExercise(updated);
                            Navigator.pop(context);
                            setState(() {
                              _customRestTime = currentSeconds;
                            });
                          },
                          child: Text(isPt ? 'Salvar' : 'Save'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }
        );
      }
    );
  }

  Widget _buildRestTimeCard() {
    final hasCustom = _customRestTime != null && _customRestTime! > 0;
    final defaultRest = widget.exercise.getAutoRestSeconds();
    final displaySecs = hasCustom ? _customRestTime! : defaultRest;
    final displayTime = '${(displaySecs / 60).floor()}m${displaySecs % 60 > 0 ? ' ${displaySecs % 60}s' : ''}';
    
    final label = hasCustom 
        ? tm.translate('stats_rest_custom', args: [displayTime])
        : tm.translate('stats_rest_default', args: [displayTime]);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: InkWell(
        onTap: _showRestTimeDialog,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.timer_outlined, color: Colors.blueAccent, size: 20),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tm.translate('stats_rest_time'),
                        style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRestTimeCard(),
          if (_performances.isEmpty)
            _buildEmptyState()
          else
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStatCard(
                  title: tm.translate('stats_est_1rm'),
                  value: '${_max1RM.toStringAsFixed(1)} kg',
                  subtitle: tm.currentLanguage == 'pt' ? 'Fórmula de Epley' : 'Epley Formula',
                  icon: Icons.emoji_events_rounded,
                  color: Colors.amber,
                ),
                _buildStatCard(
                  title: tm.translate('stats_max_weight'),
                  value: '${_maxWeight.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} kg',
                  subtitle: tm.currentLanguage == 'pt' ? 'Para $_maxWeightReps reps' : 'For $_maxWeightReps reps',
                  icon: Icons.fitness_center_rounded,
                  color: Colors.blueAccent,
                ),
                _buildStatCard(
                  title: tm.translate('stats_max_volume'),
                  value: '${_maxVolume.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} kg',
                  subtitle: '${_maxVolumeWeight.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} kg x $_maxVolumeReps reps',
                  icon: Icons.trending_up_rounded,
                  color: Colors.purpleAccent,
                ),
                _buildStatCard(
                  title: tm.translate('stats_max_reps'),
                  value: '$_maxReps reps',
                  subtitle: tm.currentLanguage == 'pt'
                      ? 'Com ${_maxRepsWeight.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} kg'
                      : 'With ${_maxRepsWeight.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} kg',
                  icon: Icons.repeat_rounded,
                  color: Colors.greenAccent,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, color: color, size: 24),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartTab() {
    final sortedList = _getSortedWorkoutBestPerformances();
    if (sortedList.length < 2) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.show_chart_rounded, color: Colors.grey[600], size: 48),
              const SizedBox(height: 16),
              Text(
                tm.currentLanguage == 'pt'
                    ? 'Dados insuficientes para gerar o gráfico.'
                    : 'Not enough data to generate chart.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                tm.currentLanguage == 'pt'
                    ? 'Realize este exercício em pelo menos 2 treinos diferentes.'
                    : 'Perform this exercise in at least 2 different workouts.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    final spots = _getChartSpots(sortedList);
    double minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    double maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);

    // Padding no eixo Y para o gráfico respirar
    minY = (minY - 5).clamp(0.0, double.infinity);
    maxY = maxY + 5;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        color: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tm.translate('stats_chart_title'),
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                tm.currentLanguage == 'pt'
                    ? 'Evolução calculada com base na melhor série de cada sessão.'
                    : 'Evolution calculated based on the best set of each session.',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 220,
                child: LineChart(
                  LineChartData(
                    minY: minY,
                    maxY: maxY,
                    gridData: const FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 10,
                    ),
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
                            return Text(
                              '${value.toInt()}kg',
                              style: const TextStyle(color: Colors.grey, fontSize: 10),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (touchedSpot) => const Color(0xFF2C2C2C),
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((LineBarSpot touchedSpot) {
                            final index = touchedSpot.x.toInt();
                            if (index >= 0 && index < sortedList.length) {
                              final perf = sortedList[index];
                              final dateStr = DateFormat('dd/MM/yy').format(perf.date);
                              return LineTooltipItem(
                                '${perf.estimated1RM.toStringAsFixed(1)} kg\n$dateStr',
                                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              );
                            }
                            return null;
                          }).toList();
                        },
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: Colors.blueAccent,
                        barWidth: 4,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(
                          show: true,
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.blueAccent.withOpacity(0.15),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_performances.isEmpty) {
      return _buildEmptyState();
    }

    // Agrupar execuções por treino (workoutId)
    final Map<int, List<SetPerformance>> groups = {};
    for (var perf in _performances) {
      groups.putIfAbsent(perf.workoutId, () => []).add(perf);
    }

    final sortedWorkoutIds = groups.keys.toList(); // Já está na ordem decrescente de data devido ao ORDER BY do SQL

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: sortedWorkoutIds.length,
      itemBuilder: (context, index) {
        final wId = sortedWorkoutIds[index];
        final sets = groups[wId] ?? [];
        if (sets.isEmpty) return const SizedBox.shrink();

        final firstSet = sets.first;
        final workoutName = firstSet.workoutName;
        final workoutDate = _formatDate(firstSet.date);

        return Card(
          color: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.only(bottom: 16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        workoutName,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      workoutDate,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                const Divider(color: Colors.white12, height: 24),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sets.length,
                  itemBuilder: (context, setIndex) {
                    final set = sets[setIndex];
                    final isWarmup = set.setType == 'Warmup';
                    final isFailure = set.setType == 'Failure';
                    
                    String suffix = '';
                    if (isWarmup) suffix = tm.currentLanguage == 'pt' ? ' (Aquecimento)' : ' (Warm Up)';
                    if (isFailure) suffix = tm.currentLanguage == 'pt' ? ' (Falha)' : ' (Failure)';

                    // Verificar se esta série alcançou ou bateu algum recorde histórico
                    final is1RMRecord = set.estimated1RM >= _max1RM && set.estimated1RM > 0;
                    final isWeightRecord = set.weight >= _maxWeight && set.weight > 0;
                    final isVolumeRecord = set.volume >= _maxVolume && set.volume > 0;
                    final isRepsRecord = set.reps >= _maxReps && set.reps > 0;
                    
                    final isAnyRecord = is1RMRecord || isWeightRecord || isVolumeRecord || isRepsRecord;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isWarmup
                                  ? Colors.orange.withOpacity(0.15)
                                  : isFailure
                                      ? Colors.red.withOpacity(0.15)
                                      : Colors.blueAccent.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${setIndex + 1}',
                              style: TextStyle(
                                color: isWarmup
                                    ? Colors.orange
                                    : isFailure
                                        ? Colors.red
                                        : Colors.blueAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: '${set.weight.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} kg x ${set.reps} reps',
                                    style: const TextStyle(color: Colors.white, fontSize: 14),
                                  ),
                                  if (suffix.isNotEmpty)
                                    TextSpan(
                                      text: suffix,
                                      style: TextStyle(
                                          color: isWarmup ? Colors.orange[300] : Colors.red[300],
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic),
                                    ),
                                  if (set.rpe != null)
                                    TextSpan(
                                      text: ' @RPE ${set.rpe!.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}',
                                      style: const TextStyle(color: Colors.amberAccent, fontSize: 13),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          if (isAnyRecord)
                            Tooltip(
                              message: tm.translate('stats_history_pr'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.amber, width: 0.5),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 12),
                                    const SizedBox(width: 2),
                                    Text(
                                      tm.translate('stats_history_pr'),
                                      style: const TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold),
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
              ],
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import '../models/workout.dart';
import '../models/workout_set.dart';
import '../models/exercise.dart';
import '../models/achievement.dart';
import '../db/database_helper.dart';
import '../managers/translation_manager.dart';

class WorkoutSummaryScreen extends StatefulWidget {
  final Workout workout;
  final List<WorkoutSet> completedSets;
  final int recordsBroken;
  final List<Achievement> newAchievements;

  const WorkoutSummaryScreen({
    super.key,
    required this.workout,
    required this.completedSets,
    this.recordsBroken = 0,
    this.newAchievements = const [],
  });

  @override
  State<WorkoutSummaryScreen> createState() => _WorkoutSummaryScreenState();
}

class _WorkoutSummaryScreenState extends State<WorkoutSummaryScreen> {
  int _totalWorkouts = 0;
  int _workoutsLast7Days = 0;
  List<Workout> _history = [];

  final PageController _pageController = PageController();
  int _currentPage = 0;

  Map<int, String> _exerciseMuscles = {};
  Map<int, Exercise> _exercisesMap = {};

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadMetrics() async {
    final total = await DatabaseHelper.instance.getTotalWorkoutsCount();
    final last7 = await DatabaseHelper.instance.getWorkoutsLast7Days();
    final history = await DatabaseHelper.instance.getAllWorkoutsOrderedByDate();
    final exercises = await DatabaseHelper.instance.getExercises();

    Map<int, String> muscles = {};
    final Map<int, Exercise> exMap = {};
    for (var e in exercises) {
      muscles[e.id!] = e.muscleGroup;
      exMap[e.id!] = e;
    }

    setState(() {
      _totalWorkouts = total;
      _workoutsLast7Days = last7;
      _history = history;
      _exerciseMuscles = muscles;
      _exercisesMap = exMap;
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes}m ${remainingSeconds}s';
  }

  Widget _buildMetricColumn(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildChart() {
    if (_history.isEmpty) {
      return const SizedBox(
          height: 150, child: Center(child: CircularProgressIndicator()));
    }

    List<FlSpot> spots = [];
    double maxVolume = 0;

    if (_history.length == 1) {
      spots.add(const FlSpot(0, 0));
      spots.add(FlSpot(1, _history[0].totalVolume));
      maxVolume = _history[0].totalVolume;
    } else {
      for (int i = 0; i < _history.length; i++) {
        spots.add(FlSpot(i.toDouble(), _history[i].totalVolume));
        if (_history[i].totalVolume > maxVolume) {
          maxVolume = _history[i].totalVolume;
        }
      }
    }

    String formatVolumeLabel(double value) {
      if (value >= 1000) {
        return '${(value / 1000).toStringAsFixed(1)}k';
      }
      return '${value.toInt()}kg';
    }

    return SizedBox(
      height: 200,
      child: Padding(
        padding: const EdgeInsets.only(right: 16.0, top: 16.0, bottom: 8.0),
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: maxVolume == 0 ? 100 : maxVolume * 1.2,
            gridData: const FlGridData(show: false),
            titlesData: FlTitlesData(
              bottomTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 45,
                  getTitlesWidget: (value, meta) {
                    if (value == meta.max) return const SizedBox.shrink();
                    return Text(formatVolumeLabel(value),
                        style:
                            const TextStyle(fontSize: 10, color: Colors.grey));
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: Colors.blue,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: Colors.blue.withOpacity(0.2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPt = TranslationManager.instance.currentLanguage == 'pt';
    int slideCount = 2;
    if (widget.newAchievements.isNotEmpty) slideCount++;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildSlide1(),
                  if (widget.newAchievements.isNotEmpty) _buildAchievementSlide(),
                  _buildSlide2(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  slideCount,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color:
                          _currentPage == index ? Colors.blue : Colors.grey[800],
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    isPt ? 'Concluído' : 'Done',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementSlide() {
    final tm = TranslationManager.instance;
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.stars, size: 60, color: Colors.amber),
            const SizedBox(height: 16),
            Text(
              tm.translate('ach_new_unlock'),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.amber),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.newAchievements.length,
                itemBuilder: (context, index) {
                  final ach = widget.newAchievements[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: ach.color.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(ach.icon, color: ach.color, size: 40),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tm.translate(ach.titleKey),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                tm.translate(ach.descKey),
                                style: const TextStyle(color: Colors.grey, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide1() {
    final isPt = TranslationManager.instance.currentLanguage == 'pt';

    double cardioCalories = 0;
    for (var set in widget.completedSets) {
      final exercise = _exercisesMap[set.exerciseId];
      if (exercise?.category?.toLowerCase() == 'cardio') {
        cardioCalories += set.distance ?? 0;
      }
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.recordsBroken > 0)
              Column(
                children: [
                  SvgPicture.asset(
                    'assets/crown.svg',
                    width: 60,
                    height: 60,
                    colorFilter:
                        const ColorFilter.mode(Colors.amber, BlendMode.srcIn),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isPt
                        ? '${widget.recordsBroken} Novo${widget.recordsBroken > 1 ? 's' : ''} Recorde${widget.recordsBroken > 1 ? 's' : ''}!'
                        : '${widget.recordsBroken} New PR${widget.recordsBroken > 1 ? 's' : ''}!',
                    style: const TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                ],
              )
            else
              const Icon(Icons.emoji_events, size: 80, color: Colors.amber),
            const SizedBox(height: 16),
            Text(
              widget.workout.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(isPt ? 'Treino Concluído!' : 'Workout Completed!',
                style: const TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMetricColumn(_formatTime(widget.workout.durationSeconds),
                    isPt ? 'Tempo' : 'Time'),
                _buildMetricColumn('${widget.workout.totalVolume.toInt()} kg',
                    isPt ? 'Volume' : 'Volume'),
                _buildMetricColumn(
                    '${widget.completedSets.length}', isPt ? 'Séries' : 'Sets'),
              ],
            ),
            if (cardioCalories > 0) ...[
              const SizedBox(height: 16),
              _buildMetricColumn(
                '${cardioCalories.toInt()} kcal',
                isPt ? 'Calorias Cardio (Est.)' : 'Cardio Calories (Est.)',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSlide2() {
    final tm = TranslationManager.instance;
    final isPt = tm.currentLanguage == 'pt';

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isPt ? 'Histórico de Volume' : 'Volume History',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildChart(),
            const SizedBox(height: 24),
            Text(isPt ? 'Resumo de Hoje' : 'Today\'s Summary',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: widget.completedSets.length,
                itemBuilder: (context, index) {
                  final set = widget.completedSets[index];
                  final exercise = _exercisesMap[set.exerciseId];
                  final muscle = _exerciseMuscles[set.exerciseId] ?? '';
                  final isCardio = exercise?.category?.toLowerCase() == 'cardio';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                              color: Colors.blue, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(exercise?.translatedName ?? 'Exercício',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500)),
                              Text(muscle.toUpperCase(),
                                  style: const TextStyle(
                                      fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                        ),
                        Text(
                          isCardio 
                            ? '${(set.durationSeconds ?? 0) ~/ 60}m | ${set.distance?.toInt() ?? 0} kcal'
                            : '${set.weight.toInt()}kg x ${set.reps}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

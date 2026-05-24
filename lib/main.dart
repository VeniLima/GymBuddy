import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/exercise_library_screen.dart';
import 'screens/workout_tab_screen.dart';
import 'screens/active_workout_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/onboarding_screen.dart';
import 'managers/workout_manager.dart';
import 'managers/notification_manager.dart';
import 'managers/translation_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt', null);
  await initializeDateFormatting('en', null);
  await NotificationManager.instance.init();
  await TranslationManager.instance.init();
  
  final prefs = await SharedPreferences.getInstance();
  final isFirstRun = prefs.getBool('is_first_run') ?? true;

  runApp(GymBuddyApp(isFirstRun: isFirstRun));
}


class GymBuddyApp extends StatelessWidget {
  final bool isFirstRun;
  const GymBuddyApp({super.key, required this.isFirstRun});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: TranslationManager.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'GymBuddy',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          home: isFirstRun ? const OnboardingScreen() : const MainNavigation(),
        );
      },
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 1; // Default to Workout tab
  
  final List<Widget> _screens = [
    const ExerciseLibraryScreen(),
    const WorkoutTabScreen(),
    const ProfileScreen(),
  ];

  String _formatTimeDigital(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final tm = TranslationManager.instance;
    return Scaffold(
      body: Stack(
        children: [
          _screens[_currentIndex],
          ListenableBuilder(
            listenable: WorkoutManager.instance,
            builder: (context, _) {
              if (WorkoutManager.instance.isActive && WorkoutManager.instance.isMinimized) {
                return Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () {
                      WorkoutManager.instance.maximize();
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ActiveWorkoutScreen()));
                    },
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade900,
                        border: const Border(top: BorderSide(color: Colors.blue, width: 2)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          const Icon(Icons.fitness_center, color: Colors.white),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  WorkoutManager.instance.workoutName,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${tm.translate('act_workout_in_progress')} - ${_formatTimeDigital(WorkoutManager.instance.secondsElapsed)}',
                                  style: TextStyle(color: Colors.blue.shade200, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.open_in_full, color: Colors.white),
                            onPressed: () {
                              WorkoutManager.instance.maximize();
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const ActiveWorkoutScreen()));
                            },
                          )
                        ],
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.list), label: tm.translate('nav_exercises')),
          BottomNavigationBarItem(icon: const Icon(Icons.fitness_center), label: tm.translate('nav_workout')),
          BottomNavigationBarItem(icon: const Icon(Icons.person), label: tm.translate('nav_profile')),
        ],
      ),
    );
  }
}

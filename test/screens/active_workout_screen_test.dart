import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gymbuddy/screens/active_workout_screen.dart';
import 'package:gymbuddy/managers/workout_manager.dart';
import 'package:gymbuddy/managers/notification_manager.dart';
import 'package:gymbuddy/models/exercise.dart';
import 'package:gymbuddy/models/workout_set.dart';
import 'package:gymbuddy/db/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {}
class MockNotificationManager extends Mock implements NotificationManager {}

class MockAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async => throw UnimplementedError();

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (key == 'assets/exercises.json') {
      return json.encode([]);
    }
    return '';
  }
}

void main() {
  late MockDatabaseHelper mockDb;
  late MockNotificationManager mockNotifications;

  setUpAll(() {
    mockDb = MockDatabaseHelper();
    mockNotifications = MockNotificationManager();
    DatabaseHelper.instance = mockDb;
    NotificationManager.instance = mockNotifications;

    SharedPreferences.setMockInitialValues({
      'user_enable_rest_timer': true,
      'user_enable_rpe': false,
    });

    const MethodChannel('xyz.luan/audioplayers').setMockMethodCallHandler((_) async => null);
    const MethodChannel('xyz.luan/audioplayers.global').setMockMethodCallHandler((_) async => null);

    when(() => mockNotifications.showWorkoutNotification(any(), any(), restTime: any(named: 'restTime')))
        .thenAnswer((_) async => null);
    when(() => mockNotifications.hideWorkoutNotification()).thenAnswer((_) async => null);
  });

  setUp(() {
    final manager = WorkoutManager.instance;
    manager.isActive = false;
    manager.workoutExercises.clear();
    manager.secondsElapsed = 0;
    manager.exerciseHistoricalMax.clear();
    manager.exerciseHistoricalMaxVolume.clear();
    manager.isResting = false;
    manager.exerciseRestTimes.clear();
  });

  Widget createTestableWidget() {
    return DefaultAssetBundle(
      bundle: MockAssetBundle(),
      child: MaterialApp(
        home: const ActiveWorkoutScreen(),
      ),
    );
  }

  testWidgets('Clicking check icon should toggle completion and show rest timer', (WidgetTester tester) async {
    final manager = WorkoutManager.instance;
    final exercise = Exercise(id: 1, name: 'Bench Press', muscleGroup: 'Chest');
    
    manager.isActive = true;
    manager.workoutExercises.clear();
    manager.workoutExercises[exercise] = [
      WorkoutSet(exerciseId: 1, reps: 10, weight: 60, isCompleted: false)
    ];
    manager.exerciseRestTimes[1] = 60;

    await tester.pumpWidget(createTestableWidget());
    await tester.pumpAndSettle();

    // Verify initial state
    expect(manager.workoutExercises[exercise]![0].isCompleted, false);

    final finder = find.ancestor(
      of: find.byIcon(Icons.check),
      matching: find.byType(IconButton),
    ).first;
    
    expect(finder, findsOneWidget);

    await tester.tap(finder);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(manager.workoutExercises[exercise]![0].isCompleted, true);
    expect(manager.isResting, true);

    manager.skipRestTimer();
    manager.cancelWorkout();
    await tester.pumpAndSettle();
  });
}

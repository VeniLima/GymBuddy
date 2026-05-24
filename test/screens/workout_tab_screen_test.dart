import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gymbuddy/screens/workout_tab_screen.dart';
import 'package:gymbuddy/models/routine.dart';
import 'package:gymbuddy/db/database_helper.dart';
import 'package:gymbuddy/managers/workout_manager.dart';
import 'package:gymbuddy/managers/notification_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {}
class MockNotificationManager extends Mock implements NotificationManager {}

void main() {
  late MockDatabaseHelper mockDb;
  late MockNotificationManager mockNotifications;

  setUpAll(() {
    mockDb = MockDatabaseHelper();
    mockNotifications = MockNotificationManager();
    DatabaseHelper.instance = mockDb;
    NotificationManager.instance = mockNotifications;
    SharedPreferences.setMockInitialValues({});
    
    // Mocks globais para plugins
    const MethodChannel('xyz.luan/audioplayers').setMockMethodCallHandler((_) async => null);
    const MethodChannel('xyz.luan/audioplayers.global').setMockMethodCallHandler((_) async => null);
    when(() => mockNotifications.hideWorkoutNotification()).thenAnswer((_) async => null);
  });

  Widget createTestableWidget() {
    return MaterialApp(
      home: const WorkoutTabScreen(),
    );
  }

  testWidgets('WorkoutTabScreen should display "Iniciar Treino Vazio" button', (WidgetTester tester) async {
    when(() => mockDb.getRoutines()).thenAnswer((_) async => []);

    await tester.pumpWidget(createTestableWidget());
    await tester.pumpAndSettle();

    expect(find.text('Iniciar Treino Vazio'), findsOneWidget);
  });

  testWidgets('WorkoutTabScreen should list routines from database', (WidgetTester tester) async {
    final routines = [
      Routine(id: 1, name: 'Full Body', description: 'Test Routine'),
    ];

    when(() => mockDb.getRoutines()).thenAnswer((_) async => routines);
    when(() => mockDb.getExercisesForRoutine(1)).thenAnswer((_) async => []);

    await tester.pumpWidget(createTestableWidget());
    await tester.pumpAndSettle();

    expect(find.text('Full Body'), findsOneWidget);
  });

  testWidgets('Clicking "Iniciar Treino Vazio" should start workout in manager', (WidgetTester tester) async {
    when(() => mockDb.getRoutines()).thenAnswer((_) async => []);
    when(() => mockDb.getExercises()).thenAnswer((_) async => []);
    when(() => mockDb.getMaxWeightForExercise(any())).thenAnswer((_) async => 0.0);
    when(() => mockDb.getMaxVolumeForExercise(any())).thenAnswer((_) async => 0.0);
    when(() => mockDb.getLastWorkoutSetsForExercise(any())).thenAnswer((_) async => []);

    await tester.pumpWidget(createTestableWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Iniciar Treino Vazio'));
    await tester.pumpAndSettle();

    expect(WorkoutManager.instance.isActive, true);
    expect(WorkoutManager.instance.workoutName, 'Treino Vazio');
    
    // Cleanup
    WorkoutManager.instance.cancelWorkout();
  });
}

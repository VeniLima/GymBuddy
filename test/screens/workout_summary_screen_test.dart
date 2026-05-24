import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gymbuddy/screens/workout_summary_screen.dart';
import 'package:gymbuddy/models/workout.dart';
import 'package:gymbuddy/models/workout_set.dart';
import 'package:gymbuddy/models/exercise.dart';
import 'package:gymbuddy/db/database_helper.dart';
import 'package:gymbuddy/managers/translation_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {}

void main() {
  late MockDatabaseHelper mockDb;

  setUpAll(() async {
    mockDb = MockDatabaseHelper();
    DatabaseHelper.instance = mockDb;
    SharedPreferences.setMockInitialValues({});
    await TranslationManager.instance.init();
    
    when(() => mockDb.getTotalWorkoutsCount()).thenAnswer((_) async => 10);
    when(() => mockDb.getWorkoutsLast7Days()).thenAnswer((_) async => 5);
    when(() => mockDb.getAllWorkoutsOrderedByDate()).thenAnswer((_) async => []);
    when(() => mockDb.getExercises()).thenAnswer((_) async => []);
  });

  Widget createTestableWidget(Workout workout, List<WorkoutSet> sets, {int records = 0}) {
    return MaterialApp(
      home: WorkoutSummaryScreen(
        workout: workout,
        completedSets: sets,
        recordsBroken: records,
      ),
    );
  }

  testWidgets('WorkoutSummaryScreen should display workout metrics correctly', (WidgetTester tester) async {
    final workout = Workout(
      name: 'Push Day',
      startTime: DateTime.now(),
      durationSeconds: 3665,
      totalVolume: 4500,
    );
    final sets = [
      WorkoutSet(exerciseId: 1, reps: 10, weight: 60, isCompleted: true),
    ];

    await tester.pumpWidget(createTestableWidget(workout, sets));
    await tester.pump(); 
    await tester.pump(const Duration(seconds: 1)); 

    expect(find.text('Push Day'), findsOneWidget);
    expect(find.text('61m 5s'), findsOneWidget); 
    expect(find.text('4500 kg'), findsOneWidget);
  });

  testWidgets('WorkoutSummaryScreen should allow swiping between summary slides', (WidgetTester tester) async {
    final workout = Workout(name: 'Test', startTime: DateTime.now(), durationSeconds: 60, totalVolume: 100);
    
    await tester.pumpWidget(createTestableWidget(workout, []));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Test'), findsOneWidget);

    // Swipe manually
    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text(TranslationManager.instance.currentLanguage == 'pt' ? 'Histórico de Volume' : 'Volume History'), findsOneWidget);
  });
}

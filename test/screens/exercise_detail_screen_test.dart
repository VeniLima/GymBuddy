import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gymbuddy/screens/exercise_detail_screen.dart';
import 'package:gymbuddy/models/exercise.dart';
import 'package:gymbuddy/db/database_helper.dart';
import 'package:gymbuddy/managers/translation_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {}

void main() {
  late MockDatabaseHelper mockDb;

  setUpAll(() async {
    mockDb = MockDatabaseHelper();
    DatabaseHelper.instance = mockDb;
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('pt_BR', null);
    await initializeDateFormatting('en_US', null);
  });

  Widget createTestableWidget(Exercise exercise) {
    return MaterialApp(
      home: ExerciseDetailScreen(exercise: exercise),
    );
  }

  testWidgets('ExerciseDetailScreen should show empty state when no data', (WidgetTester tester) async {
    final exercise = Exercise(id: 1, name: 'Bench Press', muscleGroup: 'Chest');
    when(() => mockDb.getCompletedSetsWithWorkoutInfo(1)).thenAnswer((_) async => []);

    await tester.pumpWidget(createTestableWidget(exercise));
    await tester.pumpAndSettle();

    expect(find.text('Nenhum dado registrado para este exercício.'), findsOneWidget);
  });

  testWidgets('ExerciseDetailScreen should display personal records correctly', (WidgetTester tester) async {
    final exercise = Exercise(id: 1, name: 'Bench Press', muscleGroup: 'Chest');
    
    final mockData = [
      {
        'id': 1,
        'reps': 10,
        'weight': 100.0,
        'setType': 'Normal',
        'rpe': 9.0,
        'startTime': '2026-05-19T10:00:00Z',
        'workoutName': 'Chest Day',
        'workoutId': 101,
      }
    ];

    when(() => mockDb.getCompletedSetsWithWorkoutInfo(1)).thenAnswer((_) async => mockData);

    await tester.pumpWidget(createTestableWidget(exercise));
    await tester.pumpAndSettle();

    // Check records
    expect(find.text('1RM Estimado'), findsOneWidget);
    expect(find.text('Carga Máxima'), findsOneWidget);
    
    // Check formatted values (regex logic)
    expect(find.text('133.3 kg'), findsOneWidget);
    expect(find.text('100 kg'), findsOneWidget);
    expect(find.text('1000 kg'), findsOneWidget);
  });

  testWidgets('ExerciseDetailScreen tabs navigation with data', (WidgetTester tester) async {
    final exercise = Exercise(id: 1, name: 'Bench Press', muscleGroup: 'Chest');
    
    final mockData = [
      {
        'id': 1, 'reps': 10, 'weight': 100.0, 'setType': 'Normal',
        'startTime': '2026-05-18T10:00:00Z', 'workoutId': 100,
      },
      {
        'id': 2, 'reps': 10, 'weight': 110.0, 'setType': 'Normal',
        'startTime': '2026-05-19T10:00:00Z', 'workoutId': 101,
      }
    ];
    
    when(() => mockDb.getCompletedSetsWithWorkoutInfo(1)).thenAnswer((_) async => mockData);

    await tester.pumpWidget(createTestableWidget(exercise));
    await tester.pumpAndSettle();

    // Tap Chart tab
    await tester.tap(find.text('Evolução'));
    await tester.pumpAndSettle();
    expect(find.text('Evolução de 1RM Estimado'), findsOneWidget);

    // Tap History tab
    await tester.tap(find.text('Histórico'));
    await tester.pumpAndSettle();
    // Verify it is on history tab (some text or widget unique to it)
    expect(find.byType(ListView), findsWidgets);
  });
}

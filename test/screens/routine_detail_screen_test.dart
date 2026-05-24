import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gymbuddy/screens/routine_detail_screen.dart';
import 'package:gymbuddy/models/exercise.dart';
import 'package:gymbuddy/models/routine.dart';
import 'package:gymbuddy/db/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {}

void main() {
  late MockDatabaseHelper mockDb;
  late Routine testRoutine;

  setUpAll(() {
    mockDb = MockDatabaseHelper();
    DatabaseHelper.instance = mockDb;
    SharedPreferences.setMockInitialValues({});
    
    registerFallbackValue(Routine(name: '', description: ''));
  });

  setUp(() {
    testRoutine = Routine(id: 1, name: 'Chest Day', description: 'Focus on bench press');
  });

  Widget createTestableWidget() {
    return MaterialApp(
      home: RoutineDetailScreen(routine: testRoutine),
    );
  }

  testWidgets('RoutineDetailScreen should load and display exercises and sets correctly', (WidgetTester tester) async {
    final exercises = [
      Exercise(id: 1, name: 'Bench Press (Barbell)', muscleGroup: 'Chest'),
      Exercise(id: 2, name: 'Incline Bench Press (Barbell)', muscleGroup: 'Chest'),
    ];
    final sets = {1: 3, 2: 4};

    when(() => mockDb.getExercisesForRoutine(1)).thenAnswer((_) async => exercises);
    when(() => mockDb.getRoutineExerciseSets(1)).thenAnswer((_) async => sets);
    when(() => mockDb.getRoutines()).thenAnswer((_) async => [testRoutine]);

    await tester.pumpWidget(createTestableWidget());
    await tester.pump(); // Start load
    await tester.pump(); // Settle state

    // Verify title and exercises display
    expect(find.text('Chest Day'), findsOneWidget);
    expect(find.text('Focus on bench press'), findsOneWidget);
    expect(find.text('Supino Reto (Barra)'), findsOneWidget);
    expect(find.text('Supino Inclinado (Barra)'), findsOneWidget);
    expect(find.text('3 Séries'), findsOneWidget);
    expect(find.text('4 Séries'), findsOneWidget);
  });

  testWidgets('Clicking Delete should show confirmation dialog and call database delete', (WidgetTester tester) async {
    when(() => mockDb.getExercisesForRoutine(1)).thenAnswer((_) async => []);
    when(() => mockDb.getRoutineExerciseSets(1)).thenAnswer((_) async => {});
    when(() => mockDb.getRoutines()).thenAnswer((_) async => [testRoutine]);
    when(() => mockDb.deleteRoutine(1)).thenAnswer((_) async => 1);

    await tester.pumpWidget(createTestableWidget());
    await tester.pumpAndSettle();

    // Tap Delete Icon
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    // Verify dialog title
    expect(find.text('Excluir Rotina?'), findsOneWidget);

    // Tap Excluir Button
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();

    verify(() => mockDb.deleteRoutine(1)).called(1);
  });
}

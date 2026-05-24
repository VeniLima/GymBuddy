import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite/sqflite.dart';
import 'package:gymbuddy/screens/profile_screen.dart';
import 'package:gymbuddy/db/database_helper.dart';
import 'package:gymbuddy/managers/translation_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {
  @override
  Future<Database> get database async => MockDatabase();
}

class MockDatabase extends Mock implements Database {
  @override
  Future<List<Map<String, dynamic>>> query(String table,
      {bool? distinct,
      List<String>? columns,
      String? where,
      List<Object?>? whereArgs,
      String? groupBy,
      String? having,
      String? orderBy,
      int? limit,
      int? offset}) async =>
      [];
}

void main() {
  late MockDatabaseHelper mockDb;

  setUpAll(() {
    mockDb = MockDatabaseHelper();
    DatabaseHelper.instance = mockDb;

    // Stub default profile methods
    when(() => mockDb.getWorkoutConsistencyStats()).thenAnswer((_) async => {'total': 5, 'thisMonth': 2});
    when(() => mockDb.getMuscleGroupDistribution(any())).thenAnswer((_) async => {'Chest': 10});
    when(() => mockDb.getExercises()).thenAnswer((_) async => []);
    when(() => mockDb.getWeightLogs()).thenAnswer((_) async => []);
    when(() => mockDb.getWorkoutDatesLast7Days()).thenAnswer((_) async => []);
    when(() => mockDb.getWorkoutDatesCurrentMonth()).thenAnswer((_) async => []);
    when(() => mockDb.getAllWorkoutsOrderedByDate()).thenAnswer((_) async => []);
    when(() => mockDb.getRawWorkoutSetsHistory()).thenAnswer((_) async => []);
    when(() => mockDb.exportToMap()).thenAnswer((_) async => {'workouts': []});
    when(() => mockDb.restoreFromMap(any())).thenAnswer((_) async => {});

    // Setup MethodChannel mocks to bypass platform calls
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/share'),
      (MethodCall methodCall) async {
        return null;
      },
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('miguelruivo.flutter.plugins/filepicker'),
      (MethodCall methodCall) async {
        return null;
      },
    );
  });

  Widget createTestableWidget() {
    return const MaterialApp(
      home: ProfileScreen(),
    );
  }

  testWidgets('ProfileScreen renders Backup & Data section and buttons', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    await TranslationManager.instance.setLanguage('pt');

    await tester.pumpWidget(createTestableWidget());
    await tester.pumpAndSettle();

    // Verify backup section title and button labels
    expect(find.text('Dados e Backup'), findsOneWidget);
    expect(find.text('Exportar CSV'), findsOneWidget);
    expect(find.text('Backup JSON'), findsOneWidget);
    expect(find.text('Restaurar'), findsOneWidget);
  });

  testWidgets('Tapping Export CSV displays warning if history is empty', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    await TranslationManager.instance.setLanguage('pt');
    when(() => mockDb.getRawWorkoutSetsHistory()).thenAnswer((_) async => []);

    await tester.pumpWidget(createTestableWidget());
    await tester.pumpAndSettle();

    final btn = find.text('Exportar CSV');
    await tester.tap(btn);
    await tester.pumpAndSettle();

    // Should display SnackBar because history is empty
    expect(find.text('Nenhum histórico de treino para exportar.'), findsOneWidget);
  });

  testWidgets('Tapping Restore prompts a confirmation dialog', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    await TranslationManager.instance.setLanguage('pt');

    await tester.pumpWidget(createTestableWidget());
    await tester.pumpAndSettle();

    final btn = find.text('Restaurar');
    await tester.tap(btn);
    await tester.pumpAndSettle();

    // Dialog title and text should be visible
    expect(find.text('Aviso Importante!'), findsOneWidget);
    expect(find.textContaining('Restaurar um backup substituirá todos os seus dados atuais'), findsOneWidget);

    // Tap Cancel should close dialog
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('Aviso Importante!'), findsNothing);
  });
}

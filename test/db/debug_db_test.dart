import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:gymbuddy/db/database_helper.dart';
import 'package:gymbuddy/models/exercise.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Debug DB', () {
    test('Print Exercises', () async {
      final dbHelper = DatabaseHelper.instance;
      await dbHelper.initTestDatabase();
      final exercises = await dbHelper.getExercises();
      print('FOUND EXERCISES: ${exercises.length}');
      for (var e in exercises) {
        print('EX_DEBUG: ${e.id} | ${e.name}');
      }
      await dbHelper.close();
    });
  });
}

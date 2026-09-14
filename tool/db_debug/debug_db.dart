// Manual debug script — not a test (no assertions). Run with:
//   dart tool/db_debug/debug_db.dart
// Moved out of test/ because it was being counted as a passing test
// without verifying any behavior.
// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:gymbuddy/db/database_helper.dart';

Future<void> main() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final dbHelper = DatabaseHelper.instance;
  await dbHelper.initTestDatabase();
  final exercises = await dbHelper.getExercises();
  print('FOUND EXERCISES: ${exercises.length}');
  for (var e in exercises) {
    print('EX_DEBUG: ${e.id} | ${e.name}');
  }
  await dbHelper.close();
}

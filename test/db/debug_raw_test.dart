import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:gymbuddy/db/database_helper.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  test('Debug Raw Map', () async {
    final dbHelper = DatabaseHelper.instance;
    await dbHelper.initTestDatabase();
    final db = await dbHelper.database;
    final result = await db.query('exercises');
    if (result.isNotEmpty) {
      print('FIRST ROW: ' + result.first.toString());
    }
    await dbHelper.close();
  });
}

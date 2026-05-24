import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:gymbuddy/db/database_helper.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  test('Debug Table Info', () async {
    final dbHelper = DatabaseHelper.instance;
    await dbHelper.initTestDatabase();
    final db = await dbHelper.database;
    final result = await db.rawQuery('PRAGMA table_info(exercises)');
    print('TABLE INFO: ' + result.toString());
    await dbHelper.close();
  });
}

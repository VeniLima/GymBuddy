// One-off diagnostic script (not a test) to measure how many exercise names
// in assets/exercises.json ExerciseTranslator.translateName() actually
// changes vs. leaves in English. Run with:
//   dart tool/db_debug/translation_coverage_check.dart
import 'dart:convert';
import 'dart:io';
import 'package:gymbuddy/managers/exercise_translator.dart';

void main() {
  final raw = File('assets/exercises.json').readAsStringSync();
  final List<dynamic> data = json.decode(raw);
  int translated = 0;
  int untouched = 0;
  final sampleUntouched = <String>[];

  for (final ex in data) {
    final name = ex['name'] as String;
    final result = ExerciseTranslator.translateName(name, 'pt');
    if (result == name) {
      untouched++;
      if (sampleUntouched.length < 15) sampleUntouched.add(name);
    } else {
      translated++;
    }
  }

  print('Total: ${data.length}');
  print('Translated (changed): $translated');
  print('Untouched (stayed in English): $untouched');
  print('Sample untouched: $sampleUntouched');
}

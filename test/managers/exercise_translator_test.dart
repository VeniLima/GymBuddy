import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymbuddy/managers/exercise_translator.dart';

void main() {
  group('ExerciseTranslator.translateName', () {
    test('returns the English name unchanged when language is not pt', () {
      expect(ExerciseTranslator.translateName('Bench Press (Barbell)', 'en'), 'Bench Press (Barbell)');
    });

    test('uses the exact-match dictionary when available', () {
      expect(ExerciseTranslator.translateName('Squat', 'pt'), 'Agachamento Livre');
    });

    test('does not leave empty parentheses behind when the equipment is parenthesized', () {
      final result = ExerciseTranslator.translateName('Bench Press (Barbell)', 'pt');
      expect(result, isNot(contains('()')));
      expect(result, 'Supino com Barra');
    });

    test('drops parentheses around other qualifiers too', () {
      final result = ExerciseTranslator.translateName('Shoulder Press (Dumbbell)', 'pt');
      expect(result, isNot(contains('()')));
      expect(result, 'Desenvolvimento com Halteres');
    });

    test('translates a niche exercise via the content-match dictionary (not the term builder)', () {
      expect(ExerciseTranslator.translateName('Russian Twist', 'pt'), 'Torção Russa');
      expect(ExerciseTranslator.translateName('Hamstring-SMR', 'pt'), 'Liberação Miofascial - Isquiotibiais');
    });
  });

  test('covers almost the entire exercise library (regression guard for content coverage)', () {
    final raw = File('assets/exercises.json').readAsStringSync();
    final List<dynamic> data = json.decode(raw);
    expect(data, isNotEmpty);

    int translated = 0;
    for (final ex in data) {
      final name = ex['name'] as String;
      if (ExerciseTranslator.translateName(name, 'pt') != name) translated++;
    }

    // 865/873 as of the Onda-5 translation-coverage pass; the remainder are
    // legitimate English loanwords (Power Clean, Leg Press...) that Brazilian
    // gyms use as-is. Guard against regressing below that, not a moving target.
    expect(translated / data.length, greaterThanOrEqualTo(0.98));
  });
}

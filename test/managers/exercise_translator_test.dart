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
  });
}

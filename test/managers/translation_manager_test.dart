import 'package:flutter_test/flutter_test.dart';
import 'package:gymbuddy/managers/translation_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TranslationManager Unit Tests', () {
    late TranslationManager tm;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      tm = TranslationManager.instance;
    });

    test('Initial language should be pt by default', () {
      expect(tm.currentLanguage, 'pt');
    });

    test('translate() should return correct string for PT', () async {
      await tm.setLanguage('pt');
      expect(tm.translate('nav_exercises'), 'Exercícios');
    });

    test('translate() should return correct string for EN', () async {
      await tm.setLanguage('en');
      expect(tm.translate('nav_exercises'), 'Exercises');
    });

    test('translate() with arguments should replace placeholders', () async {
      await tm.setLanguage('pt');
      expect(tm.translate('wk_sets_count', args: ['3', 's']), '3 séries');
      
      await tm.setLanguage('en');
      expect(tm.translate('wk_sets_count', args: ['3', 's']), '3 sets');
    });

    test('toggleLanguage() should switch between pt and en', () async {
      await tm.setLanguage('pt');
      tm.toggleLanguage();
      expect(tm.currentLanguage, 'en');
      tm.toggleLanguage();
      expect(tm.currentLanguage, 'pt');
    });

    test('translateMuscleGroup() translates known muscle groups in pt and passes through in en', () async {
      await tm.setLanguage('pt');
      expect(tm.translateMuscleGroup('Chest'), 'Peito');
      expect(tm.translateMuscleGroup('Triceps'), 'Tríceps'); // regression: used to be the typo "Trícep" in one screen
      expect(tm.translateMuscleGroup('Abs'), 'Abdômen');
      expect(tm.translateMuscleGroup('Core'), 'Abdômen');

      await tm.setLanguage('en');
      expect(tm.translateMuscleGroup('Chest'), 'Chest');
    });

    test('translateMuscleGroup() knows Abductors, distinct from Adductors', () async {
      await tm.setLanguage('pt');
      expect(tm.translateMuscleGroup('Abductors'), 'Abdutores');
      expect(tm.translateMuscleGroup('Adductors'), 'Adutores');
    });

    test('translateMuscleGroup() falls back to the original string for an unknown muscle', () async {
      await tm.setLanguage('pt');
      expect(tm.translateMuscleGroup('Forearms'), 'Forearms');
    });

    test('getWeekdayAbbrev() is 1-indexed Monday..Sunday, matching DateTime.weekday', () async {
      await tm.setLanguage('pt');
      expect(tm.getWeekdayAbbrev(DateTime.monday), 'Seg');
      expect(tm.getWeekdayAbbrev(DateTime.sunday), 'Dom');

      await tm.setLanguage('en');
      expect(tm.getWeekdayAbbrev(DateTime.monday), 'Mon');
      expect(tm.getWeekdayAbbrev(DateTime.sunday), 'Sun');
    });

    test('weekdayInitialsSundayFirst starts on Sunday, for calendar grid headers', () async {
      await tm.setLanguage('pt');
      expect(tm.weekdayInitialsSundayFirst.first, 'D');
      expect(tm.weekdayInitialsSundayFirst.length, 7);

      await tm.setLanguage('en');
      expect(tm.weekdayInitialsSundayFirst.first, 'S');
    });

    test('getMonthName() is 1-indexed January..December', () async {
      await tm.setLanguage('pt');
      expect(tm.getMonthName(1), 'Janeiro');
      expect(tm.getMonthName(12), 'Dezembro');

      await tm.setLanguage('en');
      expect(tm.getMonthName(1), 'January');
      expect(tm.getMonthName(12), 'December');
    });
  });
}

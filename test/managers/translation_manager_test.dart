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
  });
}

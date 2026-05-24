import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymbuddy/screens/onboarding_screen.dart';
import 'package:gymbuddy/managers/translation_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async => throw UnimplementedError();

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (key == 'assets/exercises.json') {
      return json.encode([]);
    }
    return '';
  }
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({'app_language': 'pt'});
    await TranslationManager.instance.init();
    await TranslationManager.instance.setLanguage('pt');
  });

  testWidgets('OnboardingScreen displays slides and navigates to MainNavigation', (WidgetTester tester) async {
    final tm = TranslationManager.instance;
    
    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: MockAssetBundle(),
        child: const MaterialApp(home: OnboardingScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Slide 1
    expect(find.text(tm.translate('onb_welcome_title')), findsOneWidget);
    
    // Tap Next
    await tester.tap(find.text(tm.translate('onb_next')));
    await tester.pumpAndSettle();

    // Slide 2
    expect(find.text(tm.translate('onb_library_title')), findsOneWidget);

    // Tap Next
    await tester.tap(find.text(tm.translate('onb_next')));
    await tester.pumpAndSettle();

    // Slide 3
    expect(find.text(tm.translate('onb_workout_title')), findsOneWidget);

    // Tap Next
    await tester.tap(find.text(tm.translate('onb_next')));
    await tester.pumpAndSettle();

    // Slide 4
    expect(find.text(tm.translate('onb_progress_title')), findsOneWidget);
    expect(find.text(tm.translate('onb_start')), findsOneWidget);

    // Tap Start
    await tester.tap(find.text(tm.translate('onb_start')));
    // Use pump with duration here to avoid timeout if MainNavigation has ongoing frames
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    // Verify transition to MainNavigation
    expect(find.byType(BottomNavigationBar), findsOneWidget);

    // Verify SharedPreferences flag
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('is_first_run'), false);
  });
}

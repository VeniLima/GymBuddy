import 'package:flutter_test/flutter_test.dart';
import 'package:gymbuddy/managers/cardio_utils.dart';

void main() {
  group('CardioUtils.estimateCalories', () {
    test('returns 0 for a non-cardio category', () {
      final result = CardioUtils.estimateCalories(
        category: 'Chest',
        userWeight: 80,
        durationSeconds: 1800,
        exerciseName: 'Running',
      );
      expect(result, 0);
    });

    test('uses the default MET (5.0) when the exercise name matches no known activity', () {
      final result = CardioUtils.estimateCalories(
        category: 'Cardio',
        userWeight: 80,
        durationSeconds: 3600,
        exerciseName: 'Some Unknown Machine',
      );
      expect(result, 5.0 * 80 * 1.0);
    });

    final metByKeyword = {
      'Running': 8.0,
      'Cycling': 7.5,
      'Mountain Bike': 7.5,
      'Spinning Class': 7.5,
      'Walking': 3.5,
      'Swimming': 7.0,
      'Rowing Machine': 7.0,
      'Jump Rope': 11.0,
      'Elliptical Trainer': 5.0,
      'Stair Climber': 9.0,
    };

    metByKeyword.forEach((exerciseName, expectedMet) {
      test('uses MET $expectedMet for "$exerciseName"', () {
        final result = CardioUtils.estimateCalories(
          category: 'cardio', // lowercase to also prove the category check is case-insensitive
          userWeight: 70,
          durationSeconds: 1800, // 0.5h
          exerciseName: exerciseName,
        );
        expect(result, expectedMet * 70 * 0.5);
      });
    });

    test('matching is case-insensitive on the exercise name', () {
      final result = CardioUtils.estimateCalories(
        category: 'Cardio',
        userWeight: 60,
        durationSeconds: 3600,
        exerciseName: 'RUNNING on treadmill',
      );
      expect(result, 8.0 * 60 * 1.0);
    });

    test('handles a null exercise name by falling back to the default MET', () {
      final result = CardioUtils.estimateCalories(
        category: 'Cardio',
        userWeight: 80,
        durationSeconds: 3600,
      );
      expect(result, 5.0 * 80 * 1.0);
    });
  });

  group('CardioUtils.formatDuration', () {
    test('formats seconds under an hour as MM:SS', () {
      expect(CardioUtils.formatDuration(0), '00:00');
      expect(CardioUtils.formatDuration(65), '01:05');
      expect(CardioUtils.formatDuration(3599), '59:59');
    });

    test('formats an hour or more as HH:MM:SS', () {
      expect(CardioUtils.formatDuration(3600), '01:00:00');
      expect(CardioUtils.formatDuration(3665), '01:01:05');
      expect(CardioUtils.formatDuration(7325), '02:02:05');
    });
  });

  group('CardioUtils.parseDuration', () {
    test('parses MM:SS', () {
      expect(CardioUtils.parseDuration('01:05'), 65);
      expect(CardioUtils.parseDuration('59:59'), 3599);
    });

    test('parses HH:MM:SS', () {
      expect(CardioUtils.parseDuration('01:00:00'), 3600);
      expect(CardioUtils.parseDuration('02:02:05'), 7325);
    });

    test('parses a bare number of seconds', () {
      expect(CardioUtils.parseDuration('45'), 45);
    });

    test('treats an unparsable segment as 0 instead of throwing', () {
      expect(CardioUtils.parseDuration('ab:cd'), 0);
      expect(CardioUtils.parseDuration(''), 0);
    });

    test('round-trips through formatDuration', () {
      for (final seconds in [0, 5, 65, 3599, 3600, 7325]) {
        expect(CardioUtils.parseDuration(CardioUtils.formatDuration(seconds)), seconds);
      }
    });
  });
}

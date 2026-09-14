import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymbuddy/managers/bmi_calculator.dart';

void main() {
  group('BmiCalculator.calculate', () {
    test('returns an unavailable result when height or weight is missing', () {
      final noHeight = BmiCalculator.calculate(heightCm: 0, weightKg: 70, isPt: true);
      expect(noHeight.isAvailable, false);
      expect(noHeight.value, 0);
      expect(noHeight.category, '-');

      final noWeight = BmiCalculator.calculate(heightCm: 175, weightKg: 0, isPt: true);
      expect(noWeight.isAvailable, false);
    });

    test('computes BMI as weight / height(m)^2', () {
      final result = BmiCalculator.calculate(heightCm: 175, weightKg: 75, isPt: true);
      expect(result.value, closeTo(24.49, 0.01));
    });

    test('categorizes underweight (pt/en)', () {
      final pt = BmiCalculator.calculate(heightCm: 175, weightKg: 50, isPt: true);
      expect(pt.category, 'Abaixo do Peso');
      expect(pt.color, Colors.blue);

      final en = BmiCalculator.calculate(heightCm: 175, weightKg: 50, isPt: false);
      expect(en.category, 'Underweight');
    });

    test('categorizes normal weight at the lower boundary (18.5 inclusive)', () {
      // height 1.70m -> weight for BMI exactly 18.5 is 18.5 * 1.7^2 = 53.465
      final result = BmiCalculator.calculate(heightCm: 170, weightKg: 53.465, isPt: true);
      expect(result.category, 'Peso Normal');
    });

    test('categorizes normal weight just under the overweight boundary (25 exclusive)', () {
      final result = BmiCalculator.calculate(heightCm: 170, weightKg: 72.0, isPt: true);
      expect(result.value, lessThan(25));
      expect(result.category, 'Peso Normal');
    });

    test('categorizes overweight (pt/en)', () {
      final pt = BmiCalculator.calculate(heightCm: 170, weightKg: 80, isPt: true);
      expect(pt.category, 'Sobrepeso');
      expect(pt.color, Colors.orange);

      final en = BmiCalculator.calculate(heightCm: 170, weightKg: 80, isPt: false);
      expect(en.category, 'Overweight');
    });

    test('categorizes obese (pt/en)', () {
      final pt = BmiCalculator.calculate(heightCm: 170, weightKg: 100, isPt: true);
      expect(pt.category, 'Obesidade');
      expect(pt.color, Colors.red);

      final en = BmiCalculator.calculate(heightCm: 170, weightKg: 100, isPt: false);
      expect(en.category, 'Obese');
    });
  });
}

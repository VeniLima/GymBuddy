import 'package:flutter/material.dart';

class BmiResult {
  /// 0 when height/weight aren't available yet.
  final double value;
  final String category;
  final Color color;

  const BmiResult({required this.value, required this.category, required this.color});

  bool get isAvailable => value > 0;
}

class BmiCalculator {
  static BmiResult calculate({
    required double heightCm,
    required double weightKg,
    required bool isPt,
  }) {
    if (heightCm <= 0 || weightKg <= 0) {
      return const BmiResult(value: 0, category: '-', color: Colors.grey);
    }

    final heightMeters = heightCm / 100;
    final bmi = weightKg / (heightMeters * heightMeters);

    if (bmi < 18.5) {
      return BmiResult(value: bmi, category: isPt ? 'Abaixo do Peso' : 'Underweight', color: Colors.blue);
    }
    if (bmi < 25) {
      return BmiResult(value: bmi, category: isPt ? 'Peso Normal' : 'Normal Weight', color: Colors.green);
    }
    if (bmi < 30) {
      return BmiResult(value: bmi, category: isPt ? 'Sobrepeso' : 'Overweight', color: Colors.orange);
    }
    return BmiResult(value: bmi, category: isPt ? 'Obesidade' : 'Obese', color: Colors.red);
  }
}

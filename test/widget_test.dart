import 'package:flutter_test/flutter_test.dart';
import 'package:gymbuddy/models/exercise.dart';

void main() {
  test('Exercise model serialization test', () {
    final exercise = Exercise(
      id: 1,
      name: 'Bench Press',
      muscleGroup: 'Chest',
      restTimeSeconds: 90,
    );

    final map = exercise.toMap();
    expect(map['id'], 1);
    expect(map['name'], 'Bench Press');
    expect(map['muscleGroup'], 'Chest');
    expect(map['restTimeSeconds'], 90);

    final fromMap = Exercise.fromMap(map);
    expect(fromMap.id, 1);
    expect(fromMap.name, 'Bench Press');
    expect(fromMap.muscleGroup, 'Chest');
    expect(fromMap.restTimeSeconds, 90);
  });
}


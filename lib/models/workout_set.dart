class WorkoutSet {
  final int? id;
  final int? workoutId; // Pode ser nulo se for um template
  final int exerciseId;
  final int reps;
  final double weight;
  final int? durationSeconds;
  final double? distance;
  final String setType; // 'Warmup', 'Normal', 'Drop'
  final bool isCompleted;
  final int? previousReps;
  final double? previousWeight;
  final int? previousDurationSeconds;
  final double? previousDistance;
  final double? rpe;
  final String? superSetId;

  WorkoutSet({
    this.id,
    this.workoutId,
    required this.exerciseId,
    required this.reps,
    required this.weight,
    this.durationSeconds,
    this.distance,
    this.setType = 'Normal',
    this.isCompleted = false,
    this.previousReps,
    this.previousWeight,
    this.previousDurationSeconds,
    this.previousDistance,
    this.rpe,
    this.superSetId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workoutId': workoutId,
      'exerciseId': exerciseId,
      'reps': reps,
      'weight': weight,
      'durationSeconds': durationSeconds,
      'distance': distance,
      'setType': setType,
      'isCompleted': isCompleted ? 1 : 0,
      'previousReps': previousReps,
      'previousWeight': previousWeight,
      'previousDurationSeconds': previousDurationSeconds,
      'previousDistance': previousDistance,
      'rpe': rpe,
      'superSetId': superSetId,
    };
  }

  factory WorkoutSet.fromMap(Map<String, dynamic> map) {
    return WorkoutSet(
      id: map['id'],
      workoutId: map['workoutId'],
      exerciseId: map['exerciseId'],
      reps: map['reps'] ?? 0,
      weight: (map['weight'] as num?)?.toDouble() ?? 0.0,
      durationSeconds: map['durationSeconds'],
      distance: (map['distance'] as num?)?.toDouble(),
      setType: map['setType'] ?? 'Normal',
      isCompleted: map['isCompleted'] == 1,
      previousReps: map['previousReps'],
      previousWeight: (map['previousWeight'] as num?)?.toDouble(),
      previousDurationSeconds: map['previousDurationSeconds'],
      previousDistance: (map['previousDistance'] as num?)?.toDouble(),
      rpe: (map['rpe'] as num?)?.toDouble(),
      superSetId: map['superSetId'],
    );
  }
}

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

  static const Object _unset = Object();

  /// [rpe] accepts null explicitly (to clear it) — pass it or leave it out
  /// entirely to keep the current value; every other field just keeps the
  /// usual "omit to keep, pass a value to change it" copyWith behavior,
  /// since none of them are ever cleared back to null in practice.
  WorkoutSet copyWith({
    int? id,
    int? workoutId,
    int? exerciseId,
    int? reps,
    double? weight,
    int? durationSeconds,
    double? distance,
    String? setType,
    bool? isCompleted,
    int? previousReps,
    double? previousWeight,
    int? previousDurationSeconds,
    double? previousDistance,
    Object? rpe = _unset,
    String? superSetId,
  }) {
    return WorkoutSet(
      id: id ?? this.id,
      workoutId: workoutId ?? this.workoutId,
      exerciseId: exerciseId ?? this.exerciseId,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      distance: distance ?? this.distance,
      setType: setType ?? this.setType,
      isCompleted: isCompleted ?? this.isCompleted,
      previousReps: previousReps ?? this.previousReps,
      previousWeight: previousWeight ?? this.previousWeight,
      previousDurationSeconds: previousDurationSeconds ?? this.previousDurationSeconds,
      previousDistance: previousDistance ?? this.previousDistance,
      rpe: identical(rpe, _unset) ? this.rpe : rpe as double?,
      superSetId: superSetId ?? this.superSetId,
    );
  }

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

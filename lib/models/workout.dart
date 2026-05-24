class Workout {
  final int? id;
  final String name;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationSeconds;
  final double totalVolume;
  final String notes;
  final int recordsBroken;

  Workout({
    this.id,
    required this.name,
    required this.startTime,
    this.endTime,
    this.durationSeconds = 0,
    this.totalVolume = 0.0,
    this.notes = '',
    this.recordsBroken = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'durationSeconds': durationSeconds,
      'totalVolume': totalVolume,
      'notes': notes,
      'recordsBroken': recordsBroken,
    };
  }

  factory Workout.fromMap(Map<String, dynamic> map) {
    return Workout(
      id: map['id'],
      name: map['name'],
      startTime: DateTime.parse(map['startTime']),
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
      durationSeconds: map['durationSeconds'] ?? 0,
      totalVolume: (map['totalVolume'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'] ?? '',
      recordsBroken: map['recordsBroken'] ?? 0,
    );
  }
}

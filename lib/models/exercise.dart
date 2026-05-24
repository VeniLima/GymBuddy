import '../managers/translation_manager.dart';

class Exercise {
  final int? id;
  final String name;
  final String muscleGroup;
  final int? restTimeSeconds;
  String? notes;
  
  // Library-specific fields
  final String? libraryId;
  final String? category;
  final String? level;
  final String? equipment;
  final String? mechanic;
  final String? force;
  final String? imagePath; // Path of the first image or main image
  final String? instructionsJson; // Instructions stored as JSON string

  Exercise({
    this.id,
    required this.name,
    required this.muscleGroup,
    this.restTimeSeconds,
    this.notes,
    this.libraryId,
    this.category,
    this.level,
    this.equipment,
    this.mechanic,
    this.force,
    this.imagePath,
    this.instructionsJson,
  });

  String get translatedName => TranslationManager.instance.translate(name);

  bool get isMultiArticular {
    final lower = name.toLowerCase();
    return lower.contains('bench press') ||
        lower.contains('squat') ||
        lower.contains('deadlift') ||
        lower.contains('row') ||
        lower.contains('pull-up') ||
        lower.contains('pulldown') ||
        lower.contains('lunge') ||
        lower.contains('push-up') ||
        lower.contains('press');
  }

  int getAutoRestSeconds() {
    return isMultiArticular ? 120 : 60;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'muscleGroup': muscleGroup,
      'restTimeSeconds': restTimeSeconds,
      'notes': notes,
      'libraryId': libraryId,
      'category': category,
      'level': level,
      'equipment': equipment,
      'mechanic': mechanic,
      'force': force,
      'imagePath': imagePath,
      'instructionsJson': instructionsJson,
    };
  }

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'],
      name: map['name'],
      muscleGroup: map['muscleGroup'],
      restTimeSeconds: map['restTimeSeconds'],
      notes: map['notes'],
      libraryId: map['libraryId'],
      category: map['category'],
      level: map['level'],
      equipment: map['equipment'],
      mechanic: map['mechanic'],
      force: map['force'],
      imagePath: map['imagePath'],
      instructionsJson: map['instructionsJson'],
    );
  }
}

import 'package:flutter/material.dart';

class Achievement {
  final String id;
  final String titleKey;
  final String descKey;
  final IconData icon;
  final Color color;
  final DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.titleKey,
    required this.descKey,
    required this.icon,
    required this.color,
    this.unlockedAt,
  });

  bool get isUnlocked => unlockedAt != null;

  factory Achievement.fromMap(Map<String, dynamic> map, Achievement definition) {
    return Achievement(
      id: definition.id,
      titleKey: definition.titleKey,
      descKey: definition.descKey,
      icon: definition.icon,
      color: definition.color,
      unlockedAt: map['unlockedAt'] != null ? DateTime.parse(map['unlockedAt']) : null,
    );
  }
}

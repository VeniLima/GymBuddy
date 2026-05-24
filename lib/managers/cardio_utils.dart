class CardioUtils {
  /// Estimates calories burned using MET formula:
  /// Calories = MET * Weight(kg) * Time(hours)
  static double estimateCalories({
    required String category,
    required double userWeight,
    required int durationSeconds,
    String? exerciseName,
  }) {
    if (category.toLowerCase() != 'cardio') return 0;

    double met = 5.0; // Default MET
    final name = (exerciseName ?? '').toLowerCase();

    // Standard MET values
    if (name.contains('running')) met = 8.0;
    else if (name.contains('cycling') || name.contains('bike') || name.contains('spinning')) met = 7.5;
    else if (name.contains('walking')) met = 3.5;
    else if (name.contains('swimming')) met = 7.0;
    else if (name.contains('rowing')) met = 7.0;
    else if (name.contains('jump rope')) met = 11.0;
    else if (name.contains('elliptical')) met = 5.0;
    else if (name.contains('stair')) met = 9.0;

    final durationHours = durationSeconds / 3600.0;
    return met * userWeight * durationHours;
  }

  static String formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  static int parseDuration(String input) {
    // HH:MM:SS or MM:SS
    final parts = input.split(':');
    if (parts.length == 3) {
      return (int.tryParse(parts[0]) ?? 0) * 3600 + (int.tryParse(parts[1]) ?? 0) * 60 + (int.tryParse(parts[2]) ?? 0);
    } else if (parts.length == 2) {
      return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
    } else {
      return int.tryParse(input) ?? 0;
    }
  }
}

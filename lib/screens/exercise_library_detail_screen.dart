import 'dart:convert';
import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/exercise.dart';
import '../managers/translation_manager.dart';
import '../managers/exercise_translator.dart';

import 'exercise_detail_screen.dart';

class ExerciseLibraryDetailScreen extends StatelessWidget {
  final Map<String, dynamic> exerciseData;
  final bool isAlreadyImported;
  final VoidCallback onImportSuccess;

  const ExerciseLibraryDetailScreen({
    super.key,
    required this.exerciseData,
    required this.isAlreadyImported,
    required this.onImportSuccess,
  });

  @override
  Widget build(BuildContext context) {
    final tm = TranslationManager.instance;
    final isPt = tm.currentLanguage == 'pt';

    final String rawName = exerciseData['name'] ?? '';
    final String translatedName = ExerciseTranslator.translateName(rawName, tm.currentLanguage);
    final String category = exerciseData['category'] ?? '';
    final String level = exerciseData['level'] ?? '';
    final String equipment = exerciseData['equipment'] ?? '';
    final String mechanic = exerciseData['mechanic'] ?? '';
    final String force = exerciseData['force'] ?? '';
    final List<dynamic> primaryMuscles = exerciseData['primaryMuscles'] ?? [];
    final List<dynamic> secondaryMuscles = exerciseData['secondaryMuscles'] ?? [];
    final List<dynamic> instructionsEn = exerciseData['instructions'] ?? [];
    final List<dynamic> instructionsPt = exerciseData['instructions_pt'] ?? [];
    
    final List<dynamic> instructions = (isPt && instructionsPt.isNotEmpty) 
        ? instructionsPt 
        : instructionsEn;
        
    final List<dynamic> images = exerciseData['images'] ?? [];

    // Map free-exercise-db muscle to our app's muscleGroup
    String muscleGroup = 'Core';
    if (primaryMuscles.isNotEmpty) {
      final firstMuscle = primaryMuscles[0].toString().toLowerCase();
      if (firstMuscle.contains('biceps')) {
        muscleGroup = 'Biceps';
      } else if (firstMuscle.contains('triceps')) {
        muscleGroup = 'Triceps';
      } else if (firstMuscle.contains('chest')) {
        muscleGroup = 'Chest';
      } else if (firstMuscle.contains('back') || firstMuscle.contains('lats') || firstMuscle.contains('middle back') || firstMuscle.contains('lower back') || firstMuscle.contains('traps')) {
        muscleGroup = 'Back';
      } else if (firstMuscle.contains('shoulders')) {
        muscleGroup = 'Shoulders';
      } else if (firstMuscle.contains('quadriceps')) {
        muscleGroup = 'Quadriceps';
      } else if (firstMuscle.contains('hamstrings')) {
        muscleGroup = 'Hamstrings';
      } else if (firstMuscle.contains('adductors')) {
        muscleGroup = 'Adductors';
      } else if (firstMuscle.contains('glutes')) {
        muscleGroup = 'Glutes';
      } else if (firstMuscle.contains('calves')) {
        muscleGroup = 'Calves';
      } else if (firstMuscle.contains('abdominals')) {
        muscleGroup = 'Core';
      }
    }

    const Map<String, String> muscleTranslationPt = {
      'Chest': 'Peito',
      'Back': 'Costas',
      'Shoulders': 'Ombros',
      'Biceps': 'Bíceps',
      'Triceps': 'Trícep',
      'Quadriceps': 'Quadríceps',
      'Hamstrings': 'Isquiotibiais',
      'Adductors': 'Adutores',
      'Glutes': 'Glúteos',
      'Calves': 'Panturrilha',
      'Core': 'Abdômen',
    };

    final displayMuscle = (isPt ? (muscleTranslationPt[muscleGroup] ?? muscleGroup) : muscleGroup).toUpperCase();
    final displayForce = force.isNotEmpty ? tm.translate('ex_$force') : 'N/A';

    Future<void> importExercise() async {
      final localExercise = Exercise(
        name: translatedName,
        muscleGroup: muscleGroup,
        libraryId: exerciseData['id'],
        category: category,
        level: level,
        equipment: equipment,
        mechanic: mechanic,
        force: force,
        imagePath: images.isNotEmpty ? images[0].toString() : null,
        instructionsJson: json.encode(instructions),
      );
      await DatabaseHelper.instance.insertExercise(localExercise);
      onImportSuccess();
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isPt ? '$translatedName importado com sucesso!' : '$translatedName imported successfully!'),
        backgroundColor: Colors.green,
      ));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(translatedName),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exercise Images (Horizontal View)
            if (images.isNotEmpty) ...[
              SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    final imgPath = images[index].toString();
                    final imgUrl = 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/$imgPath';
                    return Container(
                      margin: const EdgeInsets.only(right: 12),
                      width: 220,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24),
                        color: Colors.grey[900],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.network(
                          imgUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(child: CircularProgressIndicator(color: Colors.blue));
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(Icons.image_not_supported, color: Colors.white24, size: 40),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Quick Info Cards
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    context,
                    tm.translate('ex_muscle'),
                    displayMuscle,
                    Icons.fitness_center,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoCard(
                    context,
                    tm.translate('ex_equipment'),
                    equipment.isNotEmpty ? equipment.toUpperCase() : tm.translate('ex_none').toUpperCase(),
                    Icons.construction,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    context,
                    tm.translate('ex_level'),
                    level.toUpperCase(),
                    Icons.grade,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoCard(
                    context,
                    tm.translate('ex_force'),
                    displayForce.toUpperCase(),
                    Icons.bolt,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    context,
                    tm.translate('ex_mechanic'),
                    mechanic.isNotEmpty ? mechanic.toUpperCase() : 'N/A',
                    Icons.settings_suggest,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoCard(
                    context,
                    isPt ? 'Categoria' : 'Category',
                    category.toUpperCase(),
                    Icons.category,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Muscles Detail
            Text(
              tm.translate('ex_muscle_details'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...primaryMuscles.map((m) => _buildMuscleTag(m.toString(), true)),
                ...secondaryMuscles.map((m) => _buildMuscleTag(m.toString(), false)),
              ],
            ),
            const SizedBox(height: 24),

            // Instructions
            if (instructions.isNotEmpty) ...[
              Text(
                tm.translate('ex_instructions'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 12),
              ...instructions.asMap().entries.map((entry) {
                final index = entry.key + 1;
                final text = entry.value.toString();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.blue.withOpacity(0.15),
                        child: Text(
                          '$index',
                          style: const TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          text,
                          style: const TextStyle(color: Colors.white70, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: 32),

            // Import or View History Button
            if (isAlreadyImported) ...[
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final exercises = await DatabaseHelper.instance.getExercises();
                    final localEx = exercises.firstWhere(
                      (e) => e.name.toLowerCase() == rawName.toLowerCase() || 
                             e.name.toLowerCase() == translatedName.toLowerCase(),
                    );
                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ExerciseDetailScreen(exercise: localEx),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.history),
                  label: Text(
                    isPt ? 'Ver Histórico e Estatísticas' : 'View History & Stats',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.withOpacity(0.2),
                    foregroundColor: Colors.blue,
                    side: const BorderSide(color: Colors.blue, width: 1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  tm.translate('ex_imported'),
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ),
            ] else
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: importExercise,
                  icon: const Icon(Icons.add),
                  label: Text(
                    tm.translate('ex_import'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMuscleTag(String name, bool isPrimary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPrimary ? Colors.blue.withOpacity(0.15) : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPrimary ? Colors.blue.withOpacity(0.3) : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Text(
        name,
        style: TextStyle(
          color: isPrimary ? Colors.blue : Colors.white70,
          fontSize: 11,
          fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

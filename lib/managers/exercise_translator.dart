class ExerciseTranslator {
  static const Map<String, String> _exactMatches = {
    'bench press': 'Supino Reto',
    'squat': 'Agachamento Livre',
    'deadlift': 'Levantamento Terra',
    'pull-up': 'Barra Fixa',
    'chin-up': 'Barra Fixa (Supinada)',
    'push-up': 'Flexão de Braços',
    'dip': 'Mergulho nas Paralelas',
    'muscle-up': 'Muscle-up',
    'front squat': 'Agachamento Frontal',
  };

  static const Map<String, String> _termTranslations = {
    // Base movements
    'bench press': 'Supino',
    'chest press': 'Supino',
    'shoulder press': 'Desenvolvimento',
    'overhead press': 'Desenvolvimento',
    'military press': 'Desenvolvimento Militar',
    'leg press': 'Leg Press',
    'press': 'Press',
    'squat': 'Agachamento',
    'deadlift': 'Levantamento Terra',
    'romanian deadlift': 'Stiff',
    'bicep curl': 'Rosca Bíceps',
    'preacher curl': 'Rosca Scott',
    'hammer curl': 'Rosca Martelo',
    'curl': 'Rosca',
    'leg extension': 'Cadeira Extensora',
    'triceps extension': 'Tríceps Extensão',
    'extension': 'Extensão',
    'pushdown': 'Tríceps Pulley',
    'pulldown': 'Puxada',
    'lat pulldown': 'Puxada Frente',
    'row': 'Remada',
    'fly': 'Crucifixo',
    'lateral raise': 'Elevação Lateral',
    'front raise': 'Elevação Frontal',
    'raise': 'Elevação',
    'crunch': 'Abdominal',
    'sit-up': 'Abdominal',
    'lunge': 'Avanço',
    'split squat': 'Agachamento Búlgaro',
    'calf raise': 'Elevação de Panturrilhas',
    'shrug': 'Encolhimento',
    'pull-up': 'Barra Fixa',
    'push-up': 'Flexão',
    'dip': 'Mergulho',
    'kickback': 'Coice',
    'pullover': 'Pullover',
    
    // Qualifiers
    'incline': 'Inclinado',
    'decline': 'Declinado',
    'seated': 'Sentado',
    'standing': 'em Pé',
    'lying': 'Deitado',
    'reverse': 'Inverso',
    'close-grip': 'Pegada Fechada',
    'wide-grip': 'Pegada Aberta',
    'single-arm': 'Unilateral',
    'single-leg': 'Unilateral',
    'one-arm': 'Unilateral',
    'alternating': 'Alternado',

    // Equipment
    'barbell': 'com Barra',
    'dumbbell': 'com Halteres',
    'kettlebell': 'com Kettlebell',
    'cable': 'no Cabo',
    'smith machine': 'no Smith',
    'machine': 'na Máquina',
    'lever': 'Articulado',
    'band': 'com Elástico',
    'bodyweight': 'com Peso Corporal',
    'ez bar': 'com Barra W',
  };

  static String translateName(String englishName, String languageCode) {
    if (languageCode != 'pt') return englishName;

    final lowerName = englishName.toLowerCase().trim();

    // 1. Exact matches
    if (_exactMatches.containsKey(lowerName)) {
      return _exactMatches[lowerName]!;
    }

    // 2. Pattern building
    String workingName = lowerName;

    // Remove parenthesis content or treat it specially if needed, but for now just process.
    
    // Extract Equipment
    String equipmentSuffix = '';
    final equipments = ['barbell', 'dumbbell', 'kettlebell', 'cable', 'smith machine', 'machine', 'lever', 'band', 'bodyweight', 'ez bar'];
    for (final eq in equipments) {
      if (workingName.contains(eq)) {
        equipmentSuffix = _termTranslations[eq]!;
        workingName = workingName.replaceAll(eq, '').trim();
        break; // take the first one found
      }
    }

    // Extract Positions
    String positionSuffix = '';
    final positions = ['seated', 'standing', 'lying', 'incline', 'decline'];
    for (final pos in positions) {
      if (workingName.contains(pos)) {
        positionSuffix = _termTranslations[pos]!;
        workingName = workingName.replaceAll(pos, '').trim();
      }
    }

    // Extract Variations
    String variationSuffix = '';
    final variations = ['reverse', 'close-grip', 'wide-grip', 'single-arm', 'single-leg', 'one-arm', 'alternating'];
    for (final varStr in variations) {
      if (workingName.contains(varStr)) {
        variationSuffix = _termTranslations[varStr]!;
        workingName = workingName.replaceAll(varStr, '').trim();
      }
    }

    // Remaining core movement
    String coreMovement = workingName;
    // Replace terms from longest to shortest to avoid partial match bugs
    final sortedTerms = _termTranslations.keys.toList()
      ..removeWhere((k) => equipments.contains(k) || positions.contains(k) || variations.contains(k))
      ..sort((a, b) => b.length.compareTo(a.length));

    bool translatedCore = false;
    for (final term in sortedTerms) {
      if (coreMovement.contains(term)) {
        coreMovement = coreMovement.replaceAll(term, _termTranslations[term]!);
        translatedCore = true;
      }
    }

    // If we didn't translate the core movement at all and there's no modifiers, just return original
    if (!translatedCore && equipmentSuffix.isEmpty && positionSuffix.isEmpty && variationSuffix.isEmpty) {
      return englishName;
    }

    // Capitalize words properly
    coreMovement = _capitalizeWords(coreMovement.trim());

    // Assemble final name
    List<String> parts = [];
    if (coreMovement.isNotEmpty) parts.add(coreMovement);
    if (positionSuffix.isNotEmpty) parts.add(positionSuffix);
    if (variationSuffix.isNotEmpty) parts.add(variationSuffix);
    if (equipmentSuffix.isNotEmpty) parts.add(equipmentSuffix);

    String finalName = parts.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    
    // Cleanup any duplicate hyphens or awkward spaces
    finalName = finalName.replaceAll(' - ', ' ').replaceAll('  ', ' ');

    if (finalName.isEmpty) return englishName;
    return finalName;
  }

  static String _capitalizeWords(String input) {
    if (input.isEmpty) return input;
    return input.split(' ').map((word) {
      if (word.isEmpty) return '';
      final lower = word.toLowerCase();
      if (lower == 'com' || lower == 'de' || lower == 'na' || lower == 'no' || lower == 'em') {
        return lower;
      }
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}

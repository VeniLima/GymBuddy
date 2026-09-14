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

  // Exact matches for exercises that don't compose well with the algorithmic
  // pattern-builder below (named/eponymous movements, stretches, SMR/foam
  // rolling, Olympic lifting, plyometrics, cardio machines...). Checked
  // right after `_exactMatches`. Keys are lowercase, punctuation preserved
  // exactly as it appears in assets/exercises.json.
  static const Map<String, String> _contentMatches = {
    '90/90 hamstring': 'Isquiotibiais 90/90',
    'ab roller': 'Roda Abdominal',
    'adductor': 'Cadeira Adutora',
    'adductor/groin': 'Alongamento de Adutores/Virilha',
    'air bike': 'Bicicleta Ergométrica (Air Bike)',
    'all fours quad stretch': 'Alongamento de Quadríceps de Quatro Apoios',
    'alternate heel touchers': 'Toque Alternado no Calcanhar',
    'alternate leg diagonal bound': 'Salto Diagonal Alternado',
    'ankle circles': 'Círculos de Tornozelo',
    'ankle on the knee': 'Tornozelo Sobre o Joelho',
    'anterior tibialis-smr': 'Liberação Miofascial - Tibial Anterior',
    'arm circles': 'Círculos com os Braços',
    'around the worlds': 'Círculo Completo com Halteres',
    'atlas stone trainer': 'Treino com Pedra de Atlas',
    'atlas stones': 'Pedras de Atlas',
    'backward drag': 'Arrasto para Trás',
    'balance board': 'Prancha de Equilíbrio',
    'battling ropes': 'Corda Naval',
    'bear crawl sled drags': 'Arrasto de Trenó Engatinhando',
    'behind head chest stretch': 'Alongamento de Peito Atrás da Cabeça',
    'bench jump': 'Salto no Banco',
    'bench sprint': 'Sprint no Banco',
    'bent over low-pulley side lateral': 'Elevação Lateral Inclinado no Cabo Baixo',
    'bent press': 'Bent Press (Press Lateral Inclinado)',
    'bicycling': 'Ciclismo',
    'bicycling, stationary': 'Ciclismo Estacionário',
    'board press': 'Supino com Prancha',
    'body tricep press': 'Press de Tríceps com o Corpo',
    'body-up': 'Elevação do Corpo',
    'bottoms up': 'Kettlebell Invertido (Bottoms Up)',
    'bottoms-up clean from the hang position': 'Clean Invertido a Partir da Posição Pendurada',
    'box jump (multiple response)': 'Salto na Caixa (Repetido)',
    'box skip': 'Salto Alternado na Caixa',
    'brachialis-smr': 'Liberação Miofascial - Braquial',
    'butt lift (bridge)': 'Elevação de Quadril (Ponte)',
    'butt-ups': 'Elevação de Quadril',
    'calf press': 'Panturrilha no Leg Press',
    'calf stretch elbows against wall': 'Alongamento de Panturrilha com Cotovelos na Parede',
    'calf stretch hands against wall': 'Alongamento de Panturrilha com Mãos na Parede',
    'calves-smr': 'Liberação Miofascial - Panturrilhas',
    'car drivers': 'Simulação de Direção',
    'carioca quick step': 'Passada Carioca Rápida',
    'cat stretch': 'Alongamento do Gato',
    'chain press': 'Supino com Correntes',
    'chair leg extended stretch': 'Alongamento de Perna Estendida na Cadeira',
    'chair lower back stretch': 'Alongamento Lombar na Cadeira',
    'chair upper body stretch': 'Alongamento de Tronco na Cadeira',
    'chest and front of shoulder stretch': 'Alongamento de Peito e Ombro Anterior',
    'chest push (multiple response)': 'Empurrão de Peito (Repetido)',
    'chest push (single response)': 'Empurrão de Peito (Único)',
    'chest push from 3 point stance': 'Empurrão de Peito a Partir de 3 Apoios',
    'chest push with run release': 'Empurrão de Peito com Saída em Corrida',
    'chest stretch on stability ball': 'Alongamento de Peito na Bola Suíça',
    "child's pose": 'Postura da Criança',
    'chin to chest stretch': 'Alongamento de Queixo ao Peito',
    'circus bell': 'Sino de Circo',
    'clean': 'Clean (Levantamento ao Ombro)',
    'clean pull': 'Puxada do Clean',
    'clean and jerk': 'Arremesso (Clean and Jerk)',
    'clean from blocks': 'Clean a Partir de Blocos',
    'cocoons': 'Cocoons (Abdominal em Bloco)',
    "conan's wheel": 'Roda de Conan',
    'crucifix': 'Crucifixo Isométrico',
    'cuban press': 'Press Cubano',
    "dancer's stretch": 'Alongamento do Bailarino',
    'dead bug': 'Inseto Morto (Dead Bug)',
    'depth jump leap': 'Salto em Profundidade',
    'double leg butt kick': 'Chute de Calcanhar Duplo',
    'downward facing balance': 'Equilíbrio de Frente para o Chão',
    'drop push': 'Flexão com Queda',
    'dynamic back stretch': 'Alongamento Dinâmico de Costas',
    'dynamic chest stretch': 'Alongamento Dinâmico de Peito',
    'ez-bar skullcrusher': 'Tríceps Testa com Barra W',
    'elbow circles': 'Círculos de Cotovelo',
    'elbow to knee': 'Cotovelo ao Joelho',
    'elbows back': 'Cotovelos para Trás',
    'elliptical trainer': 'Elíptico',
    'exercise ball pull-in': 'Encolhimento na Bola Suíça',
    'external rotation': 'Rotação Externa',
    'face pull': 'Face Pull (Puxada para o Rosto)',
    "farmer's walk": 'Caminhada do Fazendeiro',
    'fast skipping': 'Corrida Rápida no Lugar',
    'flat bench leg pull-in': 'Encolhimento de Pernas no Banco',
    'floor press': 'Supino no Chão',
    'flutter kicks': 'Tesoura de Pernas',
    'foot-smr': 'Liberação Miofascial - Pé',
    'frog hops': 'Salto do Sapo',
    'front box jump': 'Salto Frontal na Caixa',
    'front cone hops (or hurdle hops)': 'Saltos Frontais sobre Cones (ou Barreiras)',
    'gironda sternum chins': 'Barra Fixa Gironda (ao Esterno)',
    'good morning': 'Bom Dia (Good Morning)',
    'good morning off pins': 'Bom Dia a Partir dos Pinos',
    'groin and back stretch': 'Alongamento de Virilha e Costas',
    'groiners': 'Agachamento com Rotação de Quadril',
    'hamstring stretch': 'Alongamento de Isquiotibiais',
    'hamstring-smr': 'Liberação Miofascial - Isquiotibiais',
    'hang clean': 'Clean Pendurado (Hang Clean)',
    'hang clean - below the knees': 'Hang Clean Abaixo dos Joelhos',
    'hang snatch': 'Arranco Pendurado (Hang Snatch)',
    'hang snatch - below knees': 'Hang Snatch Abaixo dos Joelhos',
    'hanging bar good morning': 'Bom Dia na Barra',
    'hanging pike': 'Pike na Barra',
    'heaving snatch balance': 'Equilíbrio de Arranco (Heaving Snatch Balance)',
    'heavy bag thrust': 'Empurrão no Saco de Pancada',
    'hip circles (prone)': 'Círculos de Quadril (Decúbito Ventral)',
    'hug a ball': 'Abraçar a Bola',
    'hug knees to chest': 'Abraçar Joelhos ao Peito',
    'hurdle hops': 'Saltos sobre Barreiras',
    'iliotibial tract-smr': 'Liberação Miofascial - Trato Iliotibial',
    'inchworm': 'Lagartinha (Inchworm)',
    'intermediate groin stretch': 'Alongamento de Virilha Intermediário',
    'intermediate hip flexor and quad stretch': 'Alongamento Intermediário de Flexor de Quadril e Quadríceps',
    'iron cross': 'Crucifixo de Ferro (Iron Cross)',
    'iron crosses (stretch)': 'Alongamento Crucifixo de Ferro',
    'isometric chest squeezes': 'Contração Isométrica de Peito',
    'isometric neck exercise - front and back': 'Exercício Isométrico de Pescoço - Frente e Trás',
    'isometric neck exercise - sides': 'Exercício Isométrico de Pescoço - Laterais',
    'isometric wipers': 'Limpador de Para-brisa Isométrico',
    'jerk balance': 'Equilíbrio de Arremesso (Jerk Balance)',
    'jogging, treadmill': 'Corrida Leve na Esteira',
    'keg load': 'Levantamento de Barril',
    'kipping muscle up': 'Muscle Up com Impulso (Kipping)',
    'knee across the body': 'Joelho Cruzado ao Corpo',
    'knee circles': 'Círculos de Joelho',
    'knee tuck jump': 'Salto com Joelhos ao Peito',
    'kneeling arm drill': 'Exercício de Braços Ajoelhado',
    'kneeling forearm stretch': 'Alongamento de Antebraço Ajoelhado',
    'kneeling hip flexor': 'Alongamento de Flexor de Quadril Ajoelhado',
    "landmine 180's": 'Landmine 180 Graus',
    'landmine linear jammer': 'Landmine Linear (Jammer)',
    'lateral bound': 'Salto Lateral',
    'lateral box jump': 'Salto Lateral na Caixa',
    'lateral cone hops': 'Saltos Laterais sobre Cones',
    'latissimus dorsi-smr': 'Liberação Miofascial - Grande Dorsal',
    'leg lift': 'Elevação de Pernas',
    'leg pull-in': 'Encolhimento de Pernas',
    'leg-up hamstring stretch': 'Alongamento de Isquiotibiais com Perna Elevada',
    'linear 3-part start technique': 'Técnica de Saída Linear em 3 Partes',
    'linear acceleration wall drill': 'Exercício de Aceleração Linear na Parede',
    'linear depth jump': 'Salto em Profundidade Linear',
    'log lift': 'Levantamento de Tora (Log Lift)',
    'london bridges': 'London Bridges (Escalada Lateral)',
    'looking at ceiling': 'Olhando para o Teto',
    'lower back-smr': 'Liberação Miofascial - Lombar',
    'medicine ball chest pass': 'Arremesso de Peito com Bola Medicinal',
    'medicine ball full twist': 'Torção Completa com Bola Medicinal',
    'middle back stretch': 'Alongamento de Meio das Costas',
    'mixed grip chin': 'Barra Fixa com Pegada Mista',
    'monster walk': 'Caminhada do Monstro',
    'mountain climbers': 'Escalador (Mountain Climbers)',
    'moving claw series': 'Série de Garra em Movimento',
    'muscle snatch': 'Arranco com Força de Braços (Muscle Snatch)',
    'muscle up': 'Muscle-up',
    'neck press': 'Press no Pescoço',
    'neck-smr': 'Liberação Miofascial - Pescoço',
    'on your side quad stretch': 'Alongamento de Quadríceps Deitado de Lado',
    'on-your-back quad stretch': 'Alongamento de Quadríceps Deitado de Costas',
    'one arm against wall': 'Um Braço Apoiado na Parede',
    'one arm chin-up': 'Barra Fixa com Um Braço',
    'one arm floor press': 'Supino no Chão com Um Braço',
    'one half locust': 'Meio Gafanhoto (Yoga)',
    'one handed hang': 'Suspensão com Uma Mão',
    'one knee to chest': 'Um Joelho ao Peito',
    'otis-up': 'Otis-Up (Abdominal em Banco Declinado)',
    'overhead lat': 'Alongamento de Dorsal Sobre a Cabeça',
    'overhead slam': 'Arremesso Acima da Cabeça (Slam Ball)',
    'overhead stretch': 'Alongamento Acima da Cabeça',
    'overhead triceps': 'Alongamento de Tríceps Acima da Cabeça',
    'pallof press': 'Pallof Press (Anti-rotação)',
    'pallof press with rotation': 'Pallof Press com Rotação',
    'pelvic tilt into bridge': 'Báscula Pélvica até a Ponte',
    'peroneals stretch': 'Alongamento dos Fibulares',
    'peroneals-smr': 'Liberação Miofascial - Fibulares',
    'physioball hip bridge': 'Ponte de Quadril na Bola Suíça',
    'pin presses': 'Supino nos Pinos',
    'piriformis-smr': 'Liberação Miofascial - Piriforme',
    'plank': 'Prancha',
    'plate pinch': 'Pinça com Anilha',
    'plate twist': 'Torção com Anilha',
    'platform hamstring slides': 'Deslize de Isquiotibiais na Plataforma',
    'posterior tibialis stretch': 'Alongamento do Tibial Posterior',
    'power clean': 'Power Clean',
    'power clean from blocks': 'Power Clean a Partir de Blocos',
    'power jerk': 'Power Jerk',
    'power partials': 'Parciais de Força (Power Partials)',
    'power snatch': 'Power Snatch',
    'power snatch from blocks': 'Power Snatch a Partir de Blocos',
    'power stairs': 'Escada de Potência',
    'prone manual hamstring': 'Isquiotibiais Manual em Decúbito Ventral',
    'pull through': 'Pull Through (Puxada entre as Pernas)',
    'pullups': 'Barra Fixa',
    'push press': 'Push Press (Desenvolvimento com Impulso)',
    'push up to side plank': 'Flexão com Prancha Lateral',
    'pushups': 'Flexão de Braços',
    'pushups (close and wide hand positions)': 'Flexão (Pegada Fechada e Aberta)',
    'pyramid': 'Pirâmide (Alongamento)',
    'quad stretch': 'Alongamento de Quadríceps',
    'quadriceps-smr': 'Liberação Miofascial - Quadríceps',
    'quick leap': 'Salto Rápido',
    'rack delivery': 'Entrega no Rack',
    'rack pulls': 'Rack Pull (Terra Parcial)',
    'recumbent bike': 'Bicicleta Reclinada',
    'return push from stance': 'Empurrão de Retorno a Partir da Posição',
    'rhomboids-smr': 'Liberação Miofascial - Romboides',
    'rickshaw carry': 'Carry com Rickshaw',
    'rocket jump': 'Salto Foguete',
    'rope climb': 'Subida em Corda',
    'rope jumping': 'Pular Corda',
    'round the world shoulder stretch': 'Alongamento de Ombro Volta ao Mundo',
    "runner's stretch": 'Alongamento do Corredor',
    'running, treadmill': 'Corrida na Esteira',
    'russian twist': 'Torção Russa',
    'sandbag load': 'Levantamento de Saco de Areia',
    'scissor kick': 'Tesoura de Pernas',
    'scissors jump': 'Salto Tesoura',
    'shoulder circles': 'Círculos de Ombro',
    'shoulder stretch': 'Alongamento de Ombro',
    'side bridge': 'Prancha Lateral',
    'side hop-sprint': 'Salto Lateral com Sprint',
    'side jackknife': 'Canivete Lateral',
    'side neck stretch': 'Alongamento Lateral de Pescoço',
    'side to side chins': 'Barra Fixa Lado a Lado',
    'side wrist pull': 'Puxada Lateral de Punho',
    'side to side box shuffle': 'Deslocamento Lateral na Caixa',
    'single leg butt kick': 'Chute de Calcanhar Unilateral',
    'single leg glute bridge': 'Ponte de Glúteo Unilateral',
    'single leg push-off': 'Impulso Unilateral',
    'single-cone sprint drill': 'Sprint com Cone Único',
    'skating': 'Patinação',
    'sled drag - harness': 'Arrasto de Trenó com Arnês',
    'sled overhead backward walk': 'Caminhada para Trás com Trenó Acima da Cabeça',
    'sled push': 'Empurrão de Trenó',
    'sledgehammer swings': 'Marretadas (Sledgehammer)',
    'snatch': 'Arranco (Snatch)',
    'snatch balance': 'Equilíbrio de Arranco',
    'snatch pull': 'Puxada do Arranco',
    'snatch from blocks': 'Arranco a Partir de Blocos',
    'spell caster': 'Spell Caster (Rotação com Peso)',
    'spider crawl': 'Rastejar de Aranha',
    'spinal stretch': 'Alongamento da Coluna',
    'split clean': 'Split Clean',
    'split jerk': 'Split Jerk',
    'split jump': 'Salto Tesoura (Split Jump)',
    'split snatch': 'Split Snatch',
    'stairmaster': 'Escada Ergométrica (Stairmaster)',
    'star jump': 'Polichinelo em Salto (Star Jump)',
    'step mill': 'Escada Rolante Ergométrica',
    'stomach vacuum': 'Vácuo Abdominal',
    'stride jump crossover': 'Salto Cruzado com Passada',
    'superman': 'Super-Homem',
    'suspended fallout': 'Fallout Suspenso (TRX)',
    'svend press': 'Svend Press (Press com Anilhas)',
    'tate press': 'Tate Press',
    'the straddle': 'Afastamento (Straddle)',
    'thigh abductor': 'Cadeira Abdutora',
    'thigh adductor': 'Cadeira Adutora',
    'tire flip': 'Giro de Pneu',
    'toe touchers': 'Toque nos Pés',
    'torso rotation': 'Rotação de Tronco',
    'trail running/walking': 'Corrida/Caminhada em Trilha',
    'tricep side stretch': 'Alongamento Lateral de Tríceps',
    'triceps stretch': 'Alongamento de Tríceps',
    'upper back stretch': 'Alongamento da Parte Superior das Costas',
    'upper back-leg grab': 'Alongamento de Costas Segurando a Perna',
    'upward stretch': 'Alongamento para Cima',
    'v-bar pullup': 'Barra Fixa com Pegada V',
    'vertical swing': 'Balanço Vertical (Kettlebell)',
    'walking, treadmill': 'Caminhada na Esteira',
    'weighted ball side bend': 'Flexão Lateral com Bola com Peso',
    'weighted pull ups': 'Barra Fixa com Peso',
    'wide stance stiff legs': 'Stiff com Pernas Afastadas',
    'wind sprints': 'Sprints de Velocidade',
    'windmills': 'Moinho de Vento (Windmill)',
    "world's greatest stretch": 'Alongamento World\'s Greatest',
    'wrist circles': 'Círculos de Punho',
    'wrist roller': 'Rolo de Punho',
    'wrist rotations with straight bar': 'Rotação de Punho com Barra Reta',
    'yoke walk': 'Caminhada com Yoke',
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
    if (_contentMatches.containsKey(lowerName)) {
      return _contentMatches[lowerName]!;
    }

    // 2. Pattern building
    // Drop the parentheses themselves (keeping their content, e.g. the
    // equipment word) so extracting a term from inside them doesn't leave
    // behind an empty "()" in the translated name.
    String workingName = lowerName.replaceAll('(', ' ').replaceAll(')', ' ');

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

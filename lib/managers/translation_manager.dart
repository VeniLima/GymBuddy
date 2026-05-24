import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TranslationManager extends ChangeNotifier {
  static final TranslationManager instance = TranslationManager._();

  TranslationManager._();

  String _currentLanguage = 'pt';
  bool _isInitialized = false;

  String get currentLanguage => _currentLanguage;

  Future<void> init() async {
    if (_isInitialized) return;
    
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString('app_language');
    
    if (savedLang != null) {
      _currentLanguage = savedLang;
    } else {
      // Tenta detectar o locale do sistema
      final systemLocale = PlatformDispatcher.instance.locale.languageCode;
      if (systemLocale == 'en' || systemLocale == 'pt') {
        _currentLanguage = systemLocale;
      } else {
        _currentLanguage = 'en'; // Default
      }
    }
    
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    if (lang != 'en' && lang != 'pt') return;
    _currentLanguage = lang;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', lang);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void toggleLanguage() {
    setLanguage(_currentLanguage == 'pt' ? 'en' : 'pt');
  }

  String translate(String key, {List<String>? args}) {
    final translation = _dictionary[_currentLanguage]?[key] ?? _dictionary['en']?[key] ?? key;
    
    if (args != null && args.isNotEmpty) {
      String result = translation;
      for (int i = 0; i < args.length; i++) {
        result = result.replaceAll('{$i}', args[i]);
      }
      return result;
    }
    return translation;
  }

  static const Map<String, Map<String, String>> _dictionary = {
    'pt': {
      // Bottom Navigation
      'nav_exercises': 'Exercícios',
      'nav_workout': 'Treino',
      'nav_profile': 'Perfil',

      // Exercises Screen
      'ex_title': 'Exercícios',
      'ex_search': 'Buscar exercícios...',
      'ex_all_muscles': 'Todos os Músculos',
      'ex_custom': 'Personalizados',
      'ex_add_custom': 'Criar Exercício',
      'ex_name': 'Nome do Exercício',
      'ex_muscle_group': 'Grupo Muscular',
      'ex_cancel': 'Cancelar',
      'ex_add': 'Adicionar',
      'ex_please_enter_name': 'Por favor, insira o nome do exercício',

      // Exercise Library
      'ex_library_title': 'Biblioteca de Exercícios',
      'ex_search_library': 'Buscar na biblioteca...',
      'ex_import': 'Importar',
      'ex_imported': 'Importado',
      'ex_equipment': 'Equipamento',
      'ex_level': 'Nível',
      'ex_instructions': 'Instruções',
      'ex_muscle': 'Músculo',
      'ex_mechanic': 'Mecânica',
      'ex_muscle_details': 'Detalhe Muscular',
      'ex_force': 'Força',
      'ex_all_equipment': 'Todos Equipamentos',
      'ex_pull': 'Puxar',
      'ex_push': 'Empurrar',
      'ex_static': 'Estático',
      'ex_none': 'Nenhum',

      // Onboarding
      'onb_welcome_title': 'Bem-vindo ao GymBuddy',
      'onb_welcome_desc': 'Seu parceiro definitivo para musculação. Simples, offline e focado em resultados.',
      'onb_library_title': 'Biblioteca Completa',
      'onb_library_desc': 'Explore mais de 800 exercícios com imagens e instruções. Importe os seus favoritos!',
      'onb_workout_title': 'Treine com Inteligência',
      'onb_workout_desc': 'Crie rotinas personalizadas e acompanhe seus sets, carga e descanso em tempo real.',
      'onb_progress_title': 'Evolução Visual',
      'onb_progress_desc': 'Veja seu progresso através de gráficos de 1RM e histórico detalhado de recordes.',
      'onb_start': 'Começar',
      'onb_next': 'Próximo',

      // Cardio
      'act_time': 'TEMPO',
      'act_dist_cal': 'VALOR',
      'act_duration': 'Duração',
      'sum_calories_burned': '{0} kcal',
      'prof_cardio_section': 'Atividade Cardiovascular',
      'prof_weekly_cardio': 'Cardio nesta Semana',
      'prof_total_time': 'Tempo Total',
      'prof_total_calories': 'Calorias Totais',

      // Supersets
      'cr_group_superset': 'Criar Supersérie',
      'cr_ungroup': 'Desagrupar',
      'act_superset_label': 'SUPERSÉRIE',

      // Achievements
      'ach_title': 'Conquistas',
      'ach_unlocked_at': 'Desbloqueado em {0}',
      'ach_how_to_unlock': 'Como desbloquear:',
      'ach_new_unlock': 'Nova Conquista Desbloqueada!',
      'ach_first_workout_title': 'Iniciante de Ferro',
      'ach_first_workout_desc': 'Complete o seu primeiro treino no app.',
      'ach_squat_100_title': 'Clube dos 100kg',
      'ach_squat_100_desc': 'Alcance uma carga de pelo menos 100kg no Agachamento.',
      'ach_cardio_5h_title': 'Coração de Aço',
      'ach_cardio_5h_desc': 'Complete um total de 5 horas de cardio.',
      'ach_streak_4_title': 'Inabalável',
      'ach_streak_4_desc': 'Treine por 4 dias consecutivos.',
      'ach_early_bird_title': 'Madrugador',
      'ach_early_bird_desc': 'Finalize um treino antes das 8:00 da manhã.',

      // Workout Screen
      'wk_title': 'Treino',
      'wk_routines': 'Rotinas',
      'wk_new_routine': 'Nova Rotina',
      'wk_start_empty': 'Iniciar Treino Vazio',
      'wk_start': 'Iniciar',
      'wk_sets_count': '{0} série{1}',

      // Create Routine Screen
      'cr_title': 'Criar Rotina',
      'cr_name_placeholder': 'Nome da Rotina',
      'cr_add_exercise': 'Adicionar Exercício',
      'cr_save': 'Salvar Rotina',
      'cr_please_enter_name': 'Por favor, insira o nome da rotina',
      'cr_please_add_exercises': 'Por favor, adicione pelo menos um exercício',

      // Active Workout Screen
      'act_workout_in_progress': 'Treino em andamento',
      'act_cancel': 'Cancelar',
      'act_finish': 'Concluir',
      'act_set': 'SÉRIE',
      'act_previous': 'ANTERIOR',
      'act_weight': 'KG',
      'act_reps': 'REPS',
      'act_add_set': 'Adicionar Série',
      'act_rest_timer': 'Tempo de Descanso: {0}',
      'act_exercise_notes': 'Anotações do exercício...',
      'act_congrats_pr': 'Parabéns! Novo Recorde Pessoal!',
      'act_confirm_cancel_title': 'Cancelar Treino?',
      'act_confirm_cancel_body': 'Tem certeza que deseja cancelar o treino atual? Todo o progresso será perdido.',
      'act_confirm_cancel_btn': 'Cancelar Treino',
      'act_resume': 'Retomar',
      'act_type_title': 'Tipo de Série',
      'act_type_normal': 'Série Normal',
      'act_type_normal_sub': 'Série comum do seu treino',
      'act_type_warmup': 'Aquecimento (Warm Up)',
      'act_type_warmup_sub': 'Série leve para preparar a musculatura',
      'act_type_failure': 'Série até a Falha (Failure)',
      'act_type_failure_sub': 'Série levada até a falha concêntrica total',
      'act_type_drop': 'Série Drop Set',
      'act_type_drop_sub': 'Redução de peso sem descanso após a falha',

      // Profile Screen
      'prof_title': 'Perfil',
      'prof_height': 'Altura',
      'prof_weight': 'Peso',
      'prof_bmi': 'IMC',
      'prof_consistency': 'Consistência',
      'prof_monthly_calendar': 'Histórico Mensal de Treinos',
      'prof_weight_history': 'Histórico de Peso',
      'prof_language': 'Idioma',
      'prof_workouts_this_month': '{0} treino{1} este mês',
      'prof_edit_metrics': 'Editar Métricas',
      'prof_save': 'Salvar',
      'prof_add_weight_entry': 'Registrar Peso',
      'prof_last_7_days': 'Últimos 7 Dias',

      // History Screen
      'hist_title': 'Histórico de Treinos',
      'hist_no_workouts': 'Nenhum treino concluído ainda.',
      'hist_no_workouts_sub': 'Seus treinos finalizados aparecerão aqui!',
      'hist_duration': 'Duração',
      'hist_volume': 'Volume',
      'hist_sets': 'Séries',
      'hist_delete_title': 'Excluir Treino',
      'hist_delete_body': 'Deseja mesmo excluir este treino do seu histórico? Esta ação é irreversível.',
      'hist_delete_btn': 'Excluir',
      'hist_deleted_success': 'Treino excluído com sucesso.',
      'hist_copied_success': 'Treino copiado com sucesso!',
      'hist_share_title': 'Compartilhar Treino',
      'hist_share_subtitle': 'O texto abaixo será copiado formatado para você colar onde preferir:',
      'hist_copy_btn': 'Copiar',
      'hist_cancel_btn': 'Cancelar',
      'hist_records': '{0} Recorde{1}',
      'hist_ver_mais': 'Ver mais',
      'hist_ver_menos': 'Ver menos',
      'hist_exercicios_restantes': '(+{0} exercício{1})',

      // Summary Screen
      'sum_title': 'Resumo do Treino',
      'sum_records_broken': '{0} Novo{1} Recorde{2}!',
      'sum_workout_completed': 'Treino Concluído!',
      'sum_radar_title': 'Músculos Trabalhados',
      'sum_evolution_title': 'Evolução de Volume',
      'sum_finish_btn': 'Concluir',
      'sum_this_week': 'Esta Semana',
      'sum_workouts': 'Treinos',
      'sum_records': 'Recordes',

      // Set Types & Sharing Extenso
      'st_warmup': 'Aquecimento',
      'st_failure': 'Falha',
      'st_drop': 'Drop Set',
      'st_serie': 'Série',

      // RPE / RIR Selection & Settings
      'prof_enable_rpe': 'Habilitar RPE / RIR',
      'prof_enable_rpe_desc': 'Registrar esforço percebido e repetições na reserva para cada série',
      'rpe_select_title': 'Selecione o RPE / RIR',
      'rpe_clear': 'Limpar RPE',
      'rpe_10': '10 - Falha Máxima / 0 RIR',
      'rpe_9_5': '9.5 - Quase Falha, sem reps extras',
      'rpe_9': '9 - 1 Repetição Restante / 1 RIR',
      'rpe_8_5': '8.5 - Definitivamente 1 rep, talvez 2',
      'rpe_8': '8 - 2 Repetições Restantes / 2 RIR',
      'rpe_7_5': '7.5 - Definitivamente 2 reps, talvez 3',
      'rpe_7': '7 - 3 Repetições Restantes / 3 RIR',
      'rpe_6_5': '6.5 - Definitivamente 3 reps, talvez 4',
      'rpe_6': '6 - 4 Repetições Restantes / 4 RIR',
      'rpe_5': '5 - Aquecimento Leve / Recuperação',

      // Nomes de Exercícios Padrão
      'Bench Press (Barbell)': 'Supino Reto (Barra)',
      'Chest Fly (Machine)': 'Crucifixo (Máquina)',
      'Dumbbell Row': 'Remada Unilateral (Halter)',
      'Squat (Barbell)': 'Agachamento Livre (Barra)',
      'Incline Bench Press (Barbell)': 'Supino Inclinado (Barra)',
      'Incline Dumbbell Press': 'Supino Inclinado (Halter)',
      'Dumbbell Bench Press': 'Supino Reto (Halter)',
      'Cable Crossover': 'Cross Over (Cabo)',
      'Push-Up': 'Flexão de Braço',
      'Pull-Up': 'Barra Fixa',
      'Lat Pulldown (Cable)': 'Puxada Alta (Polia)',
      'Barbell Row': 'Remada Curvada (Barra)',
      'Seated Cable Row': 'Remada Baixa (Cabo)',
      'Deadlift (Barbell)': 'Levantamento Terra (Barra)',
      'Overhead Press (Barbell)': 'Desenvolvimento Militar (Barra)',
      'Dumbbell Shoulder Press': 'Desenvolvimento (Halter)',
      'Lateral Raise (Dumbbell)': 'Elevação Lateral (Halter)',
      'Front Raise (Dumbbell)': 'Elevação Frontal (Halter)',
      'Rear Delt Fly (Dumbbell)': 'Crucifixo Invertido (Halter)',
      'Bicep Curl (Barbell)': 'Rosca Direta (Barra)',
      'Bicep Curl (Dumbbell)': 'Rosca Direta (Halter)',
      'Hammer Curl (Dumbbell)': 'Rosca Martelo (Halter)',
      'Preacher Curl (Barbell)': 'Rosca Scott (Barra)',
      'Tricep Pushdown (Cable)': 'Tríceps Pulley (Cabo)',
      'Overhead Tricep Extension': 'Tríceps Testa / Francês (Halter)',
      'Skull Crusher (Barbell)': 'Tríceps Testa (Barra)',
      'Leg Press': 'Leg Press 45°',
      'Leg Extension (Machine)': 'Cadeira Extensora (Máquina)',
      'Leg Curl (Machine)': 'Mesa Flexora (Máquina)',
      'Lunge (Dumbbell)': 'Passada / Avanço (Halter)',
      'Romanian Deadlift (Barbell)': 'Levantamento Stiff (Barra)',
      'Standing Calf Raise': 'Gêmeos em Pé (Panturrilha)',
      'Hip Adductor (Machine)': 'Cadeira Adutora (Máquina)',
      'Crunch': 'Abdominal Crunch',
      'Plank': 'Prancha Abdominal',
      'Hanging Leg Raise': 'Elevação de Pernas na Barra',

      // Exercise Stats/PRs Dashboard (Portuguese)
      'stats_tab_records': 'Recordes',
      'stats_tab_chart': 'Evolução',
      'stats_tab_history': 'Histórico',
      'stats_est_1rm': '1RM Estimado',
      'stats_max_weight': 'Carga Máxima',
      'stats_max_volume': 'Volume Máximo',
      'stats_max_reps': 'Mais Repetições',
      'stats_no_data': 'Nenhum dado registrado para este exercício.',
      'stats_no_data_sub': 'Complete um treino com este exercício para ver as estatísticas!',
      'stats_chart_title': 'Evolução de 1RM Estimado',
      'stats_history_pr': 'Recorde Pessoal!',
      'stats_history_set_format': 'Série {0}: {1} kg x {2} reps',

      // Rest Timer Settings (Portuguese)
      'prof_timer_settings': 'Configurações de Descanso',
      'prof_enable_timer': 'Timer de Descanso Automático',
      'prof_enable_timer_desc': 'Inicia o timer ao concluir uma série',
      'prof_default_rest': 'Tempo de Descanso Padrão',
      'prof_rest_auto': 'Auto (Diferenciado)',

      // Exercise Detail Rest Info (Portuguese)
      'stats_rest_time': 'Tempo de Descanso',
      'stats_rest_default': 'Auto ({0})',
      'stats_rest_custom': 'Personalizado ({0})',
      'stats_rest_edit_title': 'Definir Tempo de Descanso',
      'stats_rest_reset': 'Restaurar Padrão',

      // Backup e Exportação (Portuguese)
      'prof_backup_section': 'Dados e Backup',
      'prof_backup_csv': 'Exportar CSV',
      'prof_backup_json': 'Backup JSON',
      'prof_backup_restore': 'Restaurar',
    },
    'en': {
      // Bottom Navigation
      'nav_exercises': 'Exercises',
      'nav_workout': 'Workout',
      'nav_profile': 'Profile',

      // Exercises Screen
      'ex_title': 'Exercises',
      'ex_search': 'Search exercises...',
      'ex_all_muscles': 'All Muscles',
      'ex_custom': 'Custom',
      'ex_add_custom': 'Create Exercise',
      'ex_name': 'Exercise Name',
      'ex_muscle_group': 'Muscle Group',
      'ex_cancel': 'Cancel',
      'ex_add': 'Add',
      'ex_please_enter_name': 'Please enter an exercise name',

      // Exercise Library
      'ex_library_title': 'Exercise Library',
      'ex_search_library': 'Search library...',
      'ex_import': 'Import',
      'ex_imported': 'Imported',
      'ex_equipment': 'Equipment',
      'ex_level': 'Level',
      'ex_instructions': 'Instructions',
      'ex_muscle': 'Muscle',
      'ex_mechanic': 'Mechanic',
      'ex_muscle_details': 'Muscle Details',
      'ex_force': 'Force',
      'ex_all_equipment': 'All Equipment',
      'ex_pull': 'Pull',
      'ex_push': 'Push',
      'ex_static': 'Static',
      'ex_none': 'None',

      // Onboarding
      'onb_welcome_title': 'Welcome to GymBuddy',
      'onb_welcome_desc': 'Your ultimate bodybuilding partner. Simple, offline, and focused on results.',
      'onb_library_title': 'Complete Library',
      'onb_library_desc': 'Explore over 800 exercises with images and instructions. Import your favorites!',
      'onb_workout_title': 'Train Smart',
      'onb_workout_desc': 'Create custom routines and track your sets, load, and rest in real-time.',
      'onb_progress_title': 'Visual Evolution',
      'onb_progress_desc': 'See your progress through 1RM charts and detailed record history.',
      'onb_start': 'Get Started',
      'onb_next': 'Next',

      // Cardio
      'act_time': 'TIME',
      'act_dist_cal': 'VALUE',
      'act_duration': 'Duration',
      'sum_calories_burned': '{0} kcal',
      'prof_cardio_section': 'Cardiovascular Activity',
      'prof_weekly_cardio': 'Weekly Cardio',
      'prof_total_time': 'Total Time',
      'prof_total_calories': 'Total Calories',

      // Supersets
      'cr_group_superset': 'Create Superset',
      'cr_ungroup': 'Ungroup',
      'act_superset_label': 'SUPERSET',

      // Achievements
      'ach_title': 'Achievements',
      'ach_unlocked_at': 'Unlocked on {0}',
      'ach_how_to_unlock': 'How to unlock:',
      'ach_new_unlock': 'New Achievement Unlocked!',
      'ach_first_workout_title': 'Iron Beginner',
      'ach_first_workout_desc': 'Complete your first workout in the app.',
      'ach_squat_100_title': '100kg Club',
      'ach_squat_100_desc': 'Reach a load of at least 100kg in the Squat.',
      'ach_cardio_5h_title': 'Heart of Steel',
      'ach_cardio_5h_desc': 'Complete a total of 5 hours of cardio.',
      'ach_streak_4_title': 'Unstoppable',
      'ach_streak_4_desc': 'Work out for 4 consecutive days.',
      'ach_early_bird_title': 'Early Bird',
      'ach_early_bird_desc': 'Finish a workout before 8:00 AM.',

      // Workout Screen
      'wk_title': 'Workout',
      'wk_routines': 'Routines',
      'wk_new_routine': 'New Routine',
      'wk_start_empty': 'Start an Empty Workout',
      'wk_start': 'Start',
      'wk_sets_count': '{0} set{1}',

      // Create Routine Screen
      'cr_title': 'Create Routine',
      'cr_name_placeholder': 'Routine Name',
      'cr_add_exercise': 'Add Exercise',
      'cr_save': 'Save Routine',
      'cr_please_enter_name': 'Please enter a routine name',
      'cr_please_add_exercises': 'Please add at least one exercise',

      // Active Workout Screen
      'act_workout_in_progress': 'Workout in progress',
      'act_cancel': 'Cancel',
      'act_finish': 'Finish',
      'act_set': 'SET',
      'act_previous': 'PREVIOUS',
      'act_weight': 'KG',
      'act_reps': 'REPS',
      'act_add_set': 'Add Set',
      'act_rest_timer': 'Rest Timer: {0}',
      'act_exercise_notes': 'Exercise notes...',
      'act_congrats_pr': 'Congratulations! New Personal Record!',
      'act_confirm_cancel_title': 'Cancel Workout?',
      'act_confirm_cancel_body': 'Are you sure you want to cancel the current workout? All progress will be lost.',
      'act_confirm_cancel_btn': 'Cancel Workout',
      'act_resume': 'Resume',
      'act_type_title': 'Set Type',
      'act_type_normal': 'Normal Set',
      'act_type_normal_sub': 'Regular set of your workout',
      'act_type_warmup': 'Warm Up Set',
      'act_type_warmup_sub': 'Light set to prepare muscles',
      'act_type_failure': 'Failure Set',
      'act_type_failure_sub': 'Set pushed to complete concentric failure',
      'act_type_drop': 'Drop Set',
      'act_type_drop_sub': 'Reduced weight with no rest after failure',

      // Profile Screen
      'prof_title': 'Profile',
      'prof_height': 'Height',
      'prof_weight': 'Weight',
      'prof_bmi': 'BMI',
      'prof_consistency': 'Consistency',
      'prof_monthly_calendar': 'Monthly Workout History',
      'prof_weight_history': 'Weight History',
      'prof_language': 'Language',
      'prof_workouts_this_month': '{0} workout{1} this month',
      'prof_edit_metrics': 'Edit Metrics',
      'prof_save': 'Save',
      'prof_add_weight_entry': 'Add Weight Entry',
      'prof_last_7_days': 'Last 7 Days',

      // History Screen
      'hist_title': 'Workout History',
      'hist_no_workouts': 'No workouts completed yet.',
      'hist_no_workouts_sub': 'Your finished workouts will appear here!',
      'hist_duration': 'Duration',
      'hist_volume': 'Volume',
      'hist_sets': 'Sets',
      'hist_delete_title': 'Delete Workout',
      'hist_delete_body': 'Are you sure you want to delete this workout from your history? This action cannot be undone.',
      'hist_delete_btn': 'Delete',
      'hist_deleted_success': 'Workout deleted successfully.',
      'hist_copied_success': 'Workout copied to clipboard!',
      'hist_share_title': 'Share Workout',
      'hist_share_subtitle': 'The text below will be copied formatted for you to paste:',
      'hist_copy_btn': 'Copy',
      'hist_cancel_btn': 'Cancel',
      'hist_records': '{0} Record{1}',
      'hist_ver_mais': 'See more',
      'hist_ver_menos': 'See less',
      'hist_exercicios_restantes': '(+{0} exercise{1})',

      // Summary Screen
      'sum_title': 'Workout Summary',
      'sum_records_broken': '{0} New PR{1}!',
      'sum_workout_completed': 'Workout Completed!',
      'sum_radar_title': 'Muscles Worked',
      'sum_evolution_title': 'Volume Evolution',
      'sum_finish_btn': 'Finish',
      'sum_this_week': 'This Week',
      'sum_workouts': 'Workouts',
      'sum_records': 'Records',

      // Set Types & Sharing Extenso
      'st_warmup': 'Warm Up',
      'st_failure': 'Failure',
      'st_drop': 'Drop Set',
      'st_serie': 'Set',

      // RPE / RIR Selection & Settings
      'prof_enable_rpe': 'Enable RPE / RIR',
      'prof_enable_rpe_desc': 'Track perceived exertion and reps in reserve for each set',
      'rpe_select_title': 'Select RPE / RIR',
      'rpe_clear': 'Clear RPE',
      'rpe_10': '10 - Max Effort / 0 RIR',
      'rpe_9_5': '9.5 - Almost Failure, no extra reps',
      'rpe_9': '9 - 1 Rep Remaining / 1 RIR',
      'rpe_8_5': '8.5 - Def. 1 rep, maybe 2',
      'rpe_8': '8 - 2 Reps Remaining / 2 RIR',
      'rpe_7_5': '7.5 - Def. 2 reps, maybe 3',
      'rpe_7': '7 - 3 Reps Remaining / 3 RIR',
      'rpe_6_5': '6.5 - Def. 3 reps, maybe 4',
      'rpe_6': '6 - 4 Reps Remaining / 4 RIR',
      'rpe_5': '5 - Light Warm Up / Active Recovery',

      // Built-in Exercise Names
      'Bench Press (Barbell)': 'Bench Press (Barbell)',
      'Chest Fly (Machine)': 'Chest Fly (Machine)',
      'Dumbbell Row': 'Dumbbell Row',
      'Squat (Barbell)': 'Squat (Barbell)',
      'Incline Bench Press (Barbell)': 'Incline Bench Press (Barbell)',
      'Incline Dumbbell Press': 'Incline Dumbbell Press',
      'Dumbbell Bench Press': 'Dumbbell Bench Press',
      'Cable Crossover': 'Cable Crossover',
      'Push-Up': 'Push-Up',
      'Pull-Up': 'Pull-Up',
      'Lat Pulldown (Cable)': 'Lat Pulldown (Cable)',
      'Barbell Row': 'Barbell Row',
      'Seated Cable Row': 'Seated Cable Row',
      'Deadlift (Barbell)': 'Deadlift (Barbell)',
      'Overhead Press (Barbell)': 'Overhead Press (Barbell)',
      'Dumbbell Shoulder Press': 'Dumbbell Shoulder Press',
      'Lateral Raise (Dumbbell)': 'Lateral Raise (Dumbbell)',
      'Front Raise (Dumbbell)': 'Front Raise (Dumbbell)',
      'Rear Delt Fly (Dumbbell)': 'Rear Delt Fly (Dumbbell)',
      'Bicep Curl (Barbell)': 'Bicep Curl (Barbell)',
      'Bicep Curl (Dumbbell)': 'Bicep Curl (Dumbbell)',
      'Hammer Curl (Dumbbell)': 'Hammer Curl (Dumbbell)',
      'Preacher Curl (Barbell)': 'Preacher Curl (Barbell)',
      'Tricep Pushdown (Cable)': 'Tricep Pushdown (Cable)',
      'Overhead Tricep Extension': 'Overhead Tricep Extension',
      'Skull Crusher (Barbell)': 'Skull Crusher (Barbell)',
      'Leg Press': 'Leg Press',
      'Leg Extension (Machine)': 'Leg Extension (Machine)',
      'Leg Curl (Machine)': 'Leg Curl (Machine)',
      'Lunge (Dumbbell)': 'Lunge (Dumbbell)',
      'Romanian Deadlift (Barbell)': 'Romanian Deadlift (Barbell)',
      'Standing Calf Raise': 'Standing Calf Raise',
      'Hip Adductor (Machine)': 'Hip Adductor (Machine)',
      'Crunch': 'Crunch',
      'Plank': 'Plank',
      'Hanging Leg Raise': 'Hanging Leg Raise',

      // Exercise Stats/PRs Dashboard (English)
      'stats_tab_records': 'PRs',
      'stats_tab_chart': 'Progress',
      'stats_tab_history': 'History',
      'stats_est_1rm': 'Estimated 1RM',
      'stats_max_weight': 'Max Weight',
      'stats_max_volume': 'Max Volume',
      'stats_max_reps': 'Max Reps',
      'stats_no_data': 'No data recorded for this exercise.',
      'stats_no_data_sub': 'Complete a workout containing this exercise to see stats!',
      'stats_chart_title': 'Estimated 1RM Evolution',
      'stats_history_pr': 'PR!',
      'stats_history_set_format': 'Set {0}: {1} kg x {2} reps',

      // Rest Timer Settings (English)
      'prof_timer_settings': 'Rest Timer Settings',
      'prof_enable_timer': 'Auto Rest Timer',
      'prof_enable_timer_desc': 'Starts the timer when a set is completed',
      'prof_default_rest': 'Default Rest Time',
      'prof_rest_auto': 'Auto (Differentiated)',

      // Exercise Detail Rest Info (English)
      'stats_rest_time': 'Rest Time',
      'stats_rest_default': 'Auto ({0})',
      'stats_rest_custom': 'Custom ({0})',
      'stats_rest_edit_title': 'Set Rest Time',
      'stats_rest_reset': 'Restore Default',

      // Backup and Export (English)
      'prof_backup_section': 'Data & Backup',
      'prof_backup_csv': 'Export CSV',
      'prof_backup_json': 'Backup JSON',
      'prof_backup_restore': 'Restore',
    }
  };
}

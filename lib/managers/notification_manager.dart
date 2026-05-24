import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

class NotificationManager {
  static NotificationManager _instance = NotificationManager._();
  static NotificationManager get instance => _instance;

  @visibleForTesting
  static set instance(NotificationManager mock) => _instance = mock;

  NotificationManager._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _plugin.initialize(settings: initializationSettings);

    // Solicitar permissão no Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()      
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  Future<void> showWorkoutNotification(
    String workoutName,
    int secondsElapsed, {
    int? restTime,
  }) async {
    // Para que o Android conte o tempo sozinho na notificação (como um cronômetro),       
    // usamos usesChronometer: true e ajustamos o 'when'.
    final int when = DateTime.now().millisecondsSinceEpoch - (secondsElapsed * 1000);

    String body = workoutName;
    if (restTime != null && restTime > 0) {
       final m = restTime ~/ 60;
       final s = restTime % 60;
       body += ' | Descanso: ${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'workout_channel',
      'Treino Ativo',
      channelDescription: 'Mostra o tempo do treino ativo em segundo plano',
      importance: Importance.low, 
      priority: Priority.low,
      ongoing: true, 
      autoCancel: false,
      usesChronometer: restTime == null,
      when: when,
      color: const Color(0xFF1E88E5), 
    );

    final NotificationDetails details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      id: 0,
      title: 'Treino em Andamento',
      body: body,
      notificationDetails: details,
    );
  }

  Future<void> hideWorkoutNotification() async {
    await _plugin.cancel(id: 0);
  }

  Future<void> showRestCompleteNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'rest_channel',
      'Temporizador de Descanso',
      channelDescription: 'Notifica quando o tempo de descanso termina',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      id: 1, 
      title: title,
      body: body,
      notificationDetails: details,
    );
  }
}

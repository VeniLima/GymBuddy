import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Entry point for the foreground task's isolate. Must be a top-level or
/// static function annotated with @pragma('vm:entry-point') so the Flutter
/// engine can find it when the service (re)starts, including after Android
/// restarts it following a process kill.
@pragma('vm:entry-point')
void workoutForegroundCallback() {
  FlutterForegroundTask.setTaskHandler(_WorkoutTaskHandler());
}

/// Deliberately does nothing on its own. The foreground service exists
/// purely so Android doesn't kill the app process while a workout is
/// active — WorkoutManager (in the main isolate) already owns the timer,
/// the autosave and the notification content; this task handler has no
/// independent work to do.
class _WorkoutTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onReceiveData(Object data) {}

  @override
  void onNotificationButtonPressed(String id) {}

  @override
  void onNotificationPressed() {}

  @override
  void onNotificationDismissed() {}
}

/// Thin wrapper around flutter_foreground_task, scoped to the one thing
/// this app uses it for: keeping the process alive (and showing the
/// "workout in progress" notification) while a workout is active.
class WorkoutForegroundService {
  static const int _serviceId = 256;

  /// Call once at app startup, before starting/restoring any workout.
  static void initialize() {
    FlutterForegroundTask.initCommunicationPort();
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'workout_channel',
        channelName: 'Treino Ativo',
        channelDescription: 'Mostra o tempo do treino ativo em segundo plano',
        priority: NotificationPriority.LOW,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        allowWakeLock: false,
        allowWifiLock: false,
      ),
    );
  }

  /// Best-effort permission requests. A denied notification permission
  /// just means the OS may not let the service show a visible notification
  /// (Android still requires the app to try starting a foreground service
  /// to get the process-priority benefit), so this never blocks starting
  /// the workout itself.
  static Future<void> requestPermissions() async {
    final permission = await FlutterForegroundTask.checkNotificationPermission();
    if (permission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
  }

  static Future<void> start({required String title, required String body}) async {
    if (await FlutterForegroundTask.isRunningService) {
      await update(title: title, body: body);
      return;
    }
    await FlutterForegroundTask.startService(
      serviceId: _serviceId,
      notificationTitle: title,
      notificationText: body,
      callback: workoutForegroundCallback,
    );
  }

  static Future<void> update({required String title, required String body}) async {
    if (!await FlutterForegroundTask.isRunningService) return;
    await FlutterForegroundTask.updateService(notificationTitle: title, notificationText: body);
  }

  static Future<void> stop() async {
    await FlutterForegroundTask.stopService();
  }
}

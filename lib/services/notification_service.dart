import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import '../utils/constants.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initSettings);

    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          AppConstants.notificationChannelId,
          AppConstants.notificationChannelName,
          description: AppConstants.notificationChannelDescription,
          importance: Importance.high,
        ),
      );
    }

    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.requestNotificationsPermission();
      await android.requestExactAlarmsPermission();
    }

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    return true;
  }

  NotificationDetails get _details {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        AppConstants.notificationChannelId,
        AppConstants.notificationChannelName,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  Future<void> scheduleOneTime({
    required int id,
    required String title,
    required String body,
    required DateTime date,
  }) async {
    final now = DateTime.now();
    final delay = date.difference(now);
    if (delay.isNegative || delay > const Duration(days: 365)) return;

    await Workmanager().registerOneOffTask(
      'notif_$id',
      'showNotification',
      inputData: {
        'id': id,
        'title': title,
        'body': body,
      },
      initialDelay: delay,
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }

  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required DateTime time,
  }) async {
    final now = DateTime.now();
    final scheduledToday = DateTime(
      now.year, now.month, now.day,
      time.hour, time.minute, time.second,
    );
    final firstDelay = scheduledToday.isAfter(now)
        ? scheduledToday.difference(now)
        : scheduledToday.add(const Duration(days: 1)).difference(now);

    if (firstDelay > const Duration(days: 365)) return;

    await Workmanager().registerPeriodicTask(
      'notif_${id}_daily',
      'showNotification',
      inputData: {
        'id': id,
        'title': title,
        'body': body,
      },
      initialDelay: firstDelay,
      frequency: const Duration(hours: 24),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await _plugin.show(id, title, body, _details);
  }

  Future<void> cancel(int id) async {
    await _plugin.cancel(id);
    await cancelScheduled(id);
  }

  Future<void> cancelScheduled(int id) async {
    await Workmanager().cancelByUniqueName('notif_$id');
    await Workmanager().cancelByUniqueName('notif_${id}_daily');
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
    await Workmanager().cancelAll();
  }
}

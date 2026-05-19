import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import '../utils/constants.dart';

@pragma('vm:entry-point')
void notificationCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (inputData == null) return Future.value(false);

    try {
      final plugin = FlutterLocalNotificationsPlugin();
      await plugin.initialize(const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ));

      final android = plugin.resolvePlatformSpecificImplementation<
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

      await plugin.show(
        inputData['id'] as int,
        inputData['title'] as String? ?? '',
        inputData['body'] as String? ?? '',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            AppConstants.notificationChannelId,
            AppConstants.notificationChannelName,
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );

      return Future.value(true);
    } catch (_) {
      return Future.value(false);
    }
  });
}

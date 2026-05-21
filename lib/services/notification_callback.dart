import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import '../utils/constants.dart';

@pragma('vm:entry-point')
void notificationCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (inputData == null) {
      print('[NotifCB] No input data');
      return false;
    }

    try {
      final rawId = inputData['id'];
      if (rawId == null) {
        print('[NotifCB] No id in inputData');
        return false;
      }
      final id = (rawId is int) ? rawId : (rawId as num).toInt();
      final title = inputData['title'] as String? ?? '';
      final body = inputData['body'] as String? ?? '';

      print('[NotifCB] Firing: id=$id title=$title');

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
        id,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            AppConstants.notificationChannelId,
            AppConstants.notificationChannelName,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );

      print('[NotifCB] Success: id=$id');
      return true;
    } catch (e) {
      print('[NotifCB] Error: $e');
      return false;
    }
  });
}

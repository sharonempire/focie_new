import 'dart:developer';
import 'package:app_usage/app_usage.dart';
import 'package:focie/alarm_services/alarm_services.dart';
import 'package:permission_handler/permission_handler.dart';

class UsageStatService {
  static Future<void> requestPermissions() async {
    if (await Permission.audio.isDenied) {
      await Permission.audio.request();
    }
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  Future<bool> requestUsagePermission() async {
    try {
      await AppUsage().getAppUsage(DateTime.now(), DateTime.now());
      return true;
    } catch (e) {
      log('Usage permission required: $e');
      return false;
    }
  }

  static Future<void> checkAndPlayAlarm() async {
    try {
      BackgroundUsageService.initializeNotifications();
      BackgroundUsageService.showNotificationWithAction();
      DateTime endDate = DateTime.now();
      DateTime startDate = endDate.subtract(Duration(minutes: 30));
      List<AppUsageInfo> infoList = await AppUsage().getAppUsage(
        startDate,
        endDate,
      );

      for (var info in infoList) {
        if ((info.packageName == 'com.instagram.android' ||
                info.packageName == 'com.google.android.youtube') &&
            info.usage.inMilliseconds > 60000) {
          await AlarmService.playMotivationAlarm();
          return;
        }
      }
    } catch (e) {
      log('Error fetching usage: $e');
    }
  }
}

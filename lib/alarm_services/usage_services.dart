import 'dart:developer';
import 'package:app_usage/app_usage.dart';
import 'package:focie/alarm_services/alarm_services.dart';
import 'package:permission_handler/permission_handler.dart';

class UsageStat {
  Future<void> audioPermission() async {
    if (await Permission.audio.isGranted) {
      return;
    } else {
      try {
        await Permission.audio.request();
      } catch (e) {
        log('Permission required: $e');
      }
    }
  }

  Future<bool> requestUsagePermission() async {
    try {
      await AppUsage().getAppUsage(DateTime.now(), DateTime.now());
      return true; // Permission granted
    } catch (e) {
      log('Permission required: $e');
      return false; // Permission denied
    }
  }

  Future<void> checkAndPlayAlarm() async {
    try {
      DateTime endDate = DateTime.now();
      DateTime startDate = endDate.subtract(Duration(minutes: 30));
      List<AppUsageInfo> infoList = await AppUsage().getAppUsage(
        startDate,
        endDate,
      );

      for (var info in infoList) {
        log(info.packageName);
        if (info.packageName == 'com.instagram.android' ||
            info.packageName == 'com.google.android.youtube') {
          if (info.usage.inMilliseconds > 60000) {
            await AlarmService.playMotivationAlarm();
          }
        }
      }
    } catch (e) {
      log('Error fetching usage: $e');
    }
  }
}

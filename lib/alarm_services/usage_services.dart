import 'package:usage_stats/usage_stats.dart';
import 'package:permission_handler/permission_handler.dart';

class UsageStatService {
  /// Request notification + audio permissions
  static Future<void> requestPermissions() async {
    if (await Permission.audio.isDenied) {
      await Permission.audio.request();
    }
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  /// Request system Usage Access permission (this opens the settings screen)
  static Future<bool> requestUsagePermission() async {
    bool? granted = await UsageStats.checkUsagePermission();
    if (!granted!) {
      UsageStats.grantUsagePermission(); // Opens settings screen
    }
    return granted;
  }
}

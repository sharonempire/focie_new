import 'dart:async';
import 'dart:developer';
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:usage_stats/usage_stats.dart';

class AlarmService {
  static final AudioPlayer _audioPlayer = AudioPlayer();

  static Future<void> playMotivationAlarm() async {
    try {
      log('🚀 Playing Motivation Alarm...');
      await _audioPlayer.play(AssetSource('audio/audio1.mp3'));
    } catch (e, stack) {
      log('❌ Error playing alarm: $e', stackTrace: stack);
    }
  }

  static Future<void> stopAlarm() async {
    try {
      await _audioPlayer.stop();
      log('✅ Alarm Stopped');
    } catch (e, stack) {
      log('❌ Error stopping alarm: $e', stackTrace: stack);
    }
  }
}

class BackgroundUsageService {
  static final FlutterBackgroundService _service = FlutterBackgroundService();
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initializeNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) async {
        if (response.actionId == 'stop_action') {
          await stopService();
        }
      },
    );
  }

  static Future<void> showNotificationWithAction() async {
    const androidDetails = AndroidNotificationDetails(
      'focus_channel',
      'Focus Monitor',
      channelDescription: 'Monitors social media usage',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'Focus Alert',
      actions: [
        AndroidNotificationAction('stop_action', 'Stop Alarm'),
      ],
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      0,
      'Monitoring in Background',
      'Watching your social media usage...',
      notificationDetails,
    );
  }

  static Future<void> stopService() async {
    try {
      _service.invoke('stopService');
      await AlarmService.stopAlarm();
      await _notificationsPlugin.cancelAll();
      log('🛑 Monitoring stopped via notification');
    } catch (e, stack) {
      log('❌ Error stopping service: $e', stackTrace: stack);
    }
  }

  /// Background entrypoint
  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();

    log('🔁 Background Service Started');

    service.on('stopService').listen((_) async {
      await stopService();
    });

    Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (service is AndroidServiceInstance &&
          await service.isForegroundService()) {
        log('⏱ Background usage check running...');
        await _checkAndPlayAlarm();
      }
    });
  }

  static Future<void> initializeService() async {
    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        autoStart: true,
        isForegroundMode: true,
        foregroundServiceTypes: [AndroidForegroundType.mediaPlayback],
        onStart: onStart,
      ),
      iosConfiguration: IosConfiguration(), // not needed here
    );

    await _service.startService();
    log('✅ Background usage service initialized');
  }

  /// Main usage check logic (inside service)
  static Future<void> _checkAndPlayAlarm() async {
    try {
      DateTime endDate = DateTime.now();
      DateTime startDate = endDate.subtract(Duration(minutes: 30));
      List<UsageInfo> usageStats =
          await UsageStats.queryUsageStats(startDate, endDate);

      for (var info in usageStats) {
        final pkg = info.packageName ?? '';
        final usageMs = int.tryParse(info.totalTimeInForeground ?? '0') ?? 0;

        if ((pkg == 'com.instagram.android' ||
                pkg == 'com.google.android.youtube') &&
            usageMs > 60000) {
          await AlarmService.playMotivationAlarm();
          await showNotificationWithAction();
          return;
        }
      }
    } catch (e) {
      log('❌ Error fetching usage: $e');
    }
  }
}

// alarm_service.dart
import 'dart:async';
import 'dart:developer';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:focie/alarm_services/usage_services.dart';

class AlarmService {
  static final AudioPlayer _audioPlayer = AudioPlayer();

  static Future<void> playMotivationAlarm() async {
    try {
      log('🚀 Playing Motivation Alarm...');
      await _audioPlayer.play(AssetSource('audio1.mp3'));
    } catch (e) {
      log('❌ Error playing alarm: $e');
    }
  }

  static Future<void> stopAlarm() async {
    await _audioPlayer.stop();
    log('✅ Alarm Stopped');
  }
}


@pragma('vm:entry-point')
class BackgroundUsageService {
  static final FlutterBackgroundService _service = FlutterBackgroundService();
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    service.on('stopService').listen((event) {
      stopService();
    });

    Timer.periodic(Duration(seconds: 10), (timer) async {
      log('⏱ Background service check...');
      if (service is AndroidServiceInstance && await service.isForegroundService()) {
        await UsageStatService.checkAndPlayAlarm();
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
      iosConfiguration: IosConfiguration(),
    );
    await _service.startService();
    log('✅ Background service started');
  }

  static Future<void> stopService() async {
    _service.invoke('stopService');
    await AlarmService.stopAlarm();
    log('🛑 Background service stopped');
  }

  static Future<void> initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) async {
        if (details.actionId == 'stop_action') {
          await stopService();
        }
      },
    );
  }

  static Future<void> showNotificationWithAction() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'focus_channel',
      'Focus Mode',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      actions: [
        AndroidNotificationAction(
          'stop_action',
          'Stop Alarm',
        ),
      ],
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _notificationsPlugin.show(
      0,
      'Focie',
      'Monitoring social media usage...',
      platformChannelSpecifics,
    );
  }
}

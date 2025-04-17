import 'dart:async';
import 'dart:developer';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:focie/alarm_services/usage_services.dart';
import 'package:on_audio_query/on_audio_query.dart';

class AlarmService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
    final OnAudioQuery _audioQuery = OnAudioQuery();


  static Future<void> playMotivationAlarm() async {
    try {
      log('🚀 Playing Motivation Alarm...');
      await _audioPlayer.play(AssetSource('audio1.mp3')); // Play from assets
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

   @pragma('vm:entry-point')
   static void onStart(ServiceInstance service) async {
    service.on('stopService').listen((event) {
      service.stopSelf();
    });
    Timer.periodic(Duration(seconds: 2), (timer) async {
      log('Background service running...');
      if (service is AndroidServiceInstance &&
          await service.isForegroundService()) {
        await UsageStat().checkAndPlayAlarm();
      }
    });
  }

  static Future<void> initializeService() async {
    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        autoStart: true,
        isForegroundMode: true,
        foregroundServiceTypes: [AndroidForegroundType.mediaPlayback],
        initialNotificationTitle: 'Focie',
        initialNotificationContent: 'Monitoring social media usage...',
        onStart: onStart,
      ),
      iosConfiguration: IosConfiguration(),
    );
    final serviceInstance = await _service.startService();
    log('Service started: $serviceInstance');
  }

  static Future<void> stopService() async {
    _service.invoke('stopService');
    log('Background service stopped');
  }
}

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:focie/alarm_services/usage_services.dart';
import 'package:focie/helpers/global_snackbar.dart';
import 'package:permission_handler/permission_handler.dart';
import '../alarm_services/alarm_services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  bool running = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  showSnackbar(String message) {
    globalSnackbar(context: context, content: message);
  }

  @override
  void initState() {
    super.initState();
    UsageStatService.requestPermissions();
    requestPermissions();
    WidgetsBinding.instance.addObserver(this);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    BackgroundUsageService.stopService();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      BackgroundUsageService.stopService();
    }
  }

  bool isRequesting = false;

  Future<void> requestPermissions() async {
    if (isRequesting) return;
    isRequesting = true;
    try {
      await Permission.notification.request();
    } catch (e) {
      log("Permission error: $e");
    } finally {
      isRequesting = false;
    }
  }

  Future<void> handleButtonPress() async {
    if (!running) {
      final permited = await UsageStatService.requestUsagePermission();
      if (permited) {
        setState(() {
          running = true;
        });
        _controller.stop(); // Stop bounce
        await showSnackbar("Focus Mode On🚀 Tracking started.");
      }
    } else {
      await BackgroundUsageService.stopService();
      setState(() {
        running = false;
      });
      _controller.repeat(reverse: true); // Resume bounce
      await showSnackbar("Focus Mode Off ❌, Tracking stopped.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: [
                  Color(0xFF0D0D2B),
                  Color(0xFF1B1B5F),
                  Color(0xFF12003D),
                  Colors.black,
                ],
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale:
                      running ? AlwaysStoppedAnimation(1.0) : _scaleAnimation,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 20,
                      ),
                      backgroundColor:
                          running ? Colors.redAccent : Colors.deepPurpleAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 10,
                      textStyle: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: handleButtonPress,
                    child: Text(running ? "Stop" : "Run"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

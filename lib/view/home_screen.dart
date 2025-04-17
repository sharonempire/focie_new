import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'package:focie/alarm_services/usage_services.dart';
import '../alarm_services/alarm_services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  bool runnnig = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    UsageStat().audioPermission();
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

  Future<void> handleButtonPress() async {
    if (!runnnig) {
      final permited = await UsageStat().requestUsagePermission();
      if (permited) {
        await BackgroundUsageService.initializeService();
        setState(() => runnnig = true);
        _controller.stop();
      }
    } else {
      await BackgroundUsageService.stopService();
      setState(() => runnnig = false);
      _controller.repeat(reverse: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// 🌌 Fullscreen Rive animation as background
          const Positioned.fill(
            child: RiveAnimation.asset(
              'assets/revolve.riv',
              fit: BoxFit.cover,
            ),
          ),

          /// 🚀 Animated Bouncing Button
          Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  backgroundColor:
                      runnnig ? Colors.redAccent : Colors.deepPurpleAccent,
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
                child: Text(runnnig ? "Stop" : "Run"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:focie/alarm_services/usage_services.dart';
import '../alarm_services/alarm_services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
    BackgroundUsageService.stopService(); // Stop service when widget is disposed
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      // 🔥 Stop service when app is closed (not just minimized)
      BackgroundUsageService.stopService();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home Screen')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
          final permited =  await UsageStat().requestUsagePermission();
          if(permited){
            await BackgroundUsageService.initializeService();
          }
            
          },
          child: const Text("Check my time"),
        ),
      ),
    );
  }
}

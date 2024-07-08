import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_call/select_screen.dart';
import 'package:video_call/signalling.services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';

void main() async {
  // start videoCall app
  WidgetsFlutterBinding.ensureInitialized();

  await initializeService();
  runApp(VideoCallApp());
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();
  try {
    await service.configure(
        iosConfiguration: IosConfiguration(),
        androidConfiguration: AndroidConfiguration(
            onStart: onStart,
            autoStart: true,
            autoStartOnBoot: true,
            isForegroundMode: true));

    await service.startService();
  } catch (err) {
    print(err);
  }
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  service.invoke('setAsForeground');
}

class VideoCallApp extends StatelessWidget {
  VideoCallApp({super.key});

  // signalling server url
  final String websocketUrl = "http://192.168.1.12:5000";

  @override
  Widget build(BuildContext context) {
    // init signalling service

    // return material app
    return MaterialApp(
      darkTheme: ThemeData.dark().copyWith(
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(),
      ),
      themeMode: ThemeMode.dark,
      home: SelectScreen(),
    );
  }
}

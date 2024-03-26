import 'package:visual_impaired_assistance/init.dart' as init;
import 'package:flutter/material.dart';
import 'package:wakelock/wakelock.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Wakelock.enable();
  await init.init();
  runApp(const MainApp());
}

/// MainApp is the Main Application.

class MainApp extends StatefulWidget {
  /// Default Constructor
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: init.cameraApp,
    );
  }
}

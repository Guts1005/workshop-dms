import 'package:flutter/material.dart';
import 'camera_spike_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CameraSpikeApp());
}

class CameraSpikeApp extends StatelessWidget {
  const CameraSpikeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Camera Capture Spike',
      debugShowCheckedModeBanner: false,
      home: CameraSpikeScreen(),
    );
  }
}

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'package:kinecue/features/squat_coach/presentation/squat_coach_page.dart';

class KineCueApp extends StatelessWidget {
  const KineCueApp({super.key, required this.cameras});

  final List<CameraDescription> cameras;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KineCue',
      theme: ThemeData.dark(),
      home: SquatCoachPage(cameras: cameras),
    );
  }
}

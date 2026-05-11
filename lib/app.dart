import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'package:kinecue/core/theme/app_theme.dart';
import 'package:kinecue/features/exercise_selection/presentation/exercise_selection_page.dart';

class KineCueApp extends StatelessWidget {
  const KineCueApp({super.key, required this.cameras});

  final List<CameraDescription> cameras;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KineCue',
      theme: AppTheme.darkTheme,
      home: ExerciseSelectionPage(cameras: cameras),
    );
  }
}

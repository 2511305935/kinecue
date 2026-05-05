import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'package:kinecue/app.dart';
import 'package:kinecue/core/services/workout_db_service.dart';
import 'package:kinecue/core/utils/logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  List<CameraDescription> cameras;
  try {
    cameras = await availableCameras();
  } catch (e) {
    Log.e('Failed to get cameras: $e', tag: 'Main');
    cameras = [];
  }

  try {
    await WorkoutDbService.instance.init();
  } catch (e) {
    Log.e('Failed to init database: $e', tag: 'Main');
  }

  runApp(KineCueApp(cameras: cameras));
}

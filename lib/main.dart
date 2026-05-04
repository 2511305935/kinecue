import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'package:kinecue/app.dart';
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

  runApp(KineCueApp(cameras: cameras));
}

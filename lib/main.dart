import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'package:kinecue/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(KineCueApp(cameras: cameras));
}

import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// 封装 ML Kit 姿态检测器，负责生命周期管理与图像推理。
///
/// 调用方在 dispose 时必须调用 [close] 释放资源。
class PoseDetectorService {
  final PoseDetector _detector = PoseDetector(
    options: PoseDetectorOptions(mode: PoseDetectionMode.stream),
  );

  /// 对单帧图像执行姿态检测，返回识别到的姿态列表。
  Future<List<Pose>> processImage(InputImage image) =>
      _detector.processImage(image);

  /// 释放 ML Kit 检测器资源，应在 State.dispose 时调用。
  Future<void> close() => _detector.close();
}

import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import 'package:kinecue/core/constants/copy.dart';
import 'package:kinecue/core/constants/pose_thresholds.dart';
import 'package:kinecue/core/theme/app_theme.dart';
import 'package:kinecue/core/utils/angle_calculator.dart';
import 'package:kinecue/features/pose_detection/data/pose_detector_service.dart';
import 'package:kinecue/shared/widgets/pose_painter.dart';

class PoseDetectionPage extends StatefulWidget {
  const PoseDetectionPage({super.key, required this.cameras});

  final List<CameraDescription> cameras;

  @override
  State<PoseDetectionPage> createState() => _PoseDetectionPageState();
}

class _PoseDetectionPageState extends State<PoseDetectionPage> {
  CameraController? _cameraController;
  final PoseDetectorService _detectorService = PoseDetectorService();

  List<Pose> _poses = [];
  bool _isProcessing = false;
  Size _imageSize = Size.zero;
  InputImageRotation _rotation = InputImageRotation.rotation270deg;

  double? _kneeAngle;
  double? _hipAngle;
  double? _ankleAngle;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final camera = widget.cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => widget.cameras.first,
    );

    _rotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation)
        ?? InputImageRotation.rotation270deg;

    _cameraController = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.bgra8888,
    );

    await _cameraController!.initialize();
    if (!mounted) return;
    setState(() {});

    _cameraController!.startImageStream(_processFrame);
  }

  Future<void> _processFrame(CameraImage image) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      _imageSize = Size(image.width.toDouble(), image.height.toDouble());

      final inputImage = InputImage.fromBytes(
        bytes: image.planes[0].bytes,
        metadata: InputImageMetadata(
          size: _imageSize,
          rotation: _rotation,
          format: InputImageFormat.bgra8888,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );

      final poses = await _detectorService.processImage(inputImage);
      if (mounted) {
        setState(() {
          _poses = poses;
          if (poses.isNotEmpty) _updateAngles(poses.first);
        });
      }
    } finally {
      _isProcessing = false;
    }
  }

  /// 从单帧姿态计算左侧三关节角度。
  ///
  /// 任一关键点置信度 < kLandmarkConfidence 时对应角度置 null。
  void _updateAngles(Pose pose) {
    PoseLandmark? lm(PoseLandmarkType t) {
      final l = pose.landmarks[t];
      return (l != null && l.likelihood >= PoseThresholds.kLandmarkConfidence)
          ? l
          : null;
    }

    final shoulder = lm(PoseLandmarkType.leftShoulder);
    final hip = lm(PoseLandmarkType.leftHip);
    final knee = lm(PoseLandmarkType.leftKnee);
    final ankle = lm(PoseLandmarkType.leftAnkle);
    final foot = lm(PoseLandmarkType.leftFootIndex);

    _kneeAngle = (hip != null && knee != null && ankle != null)
        ? AngleCalculator.calculate(hip, knee, ankle)
        : null;
    _hipAngle = (shoulder != null && hip != null && knee != null)
        ? AngleCalculator.calculate(shoulder, hip, knee)
        : null;
    _ankleAngle = (knee != null && ankle != null && foot != null)
        ? AngleCalculator.calculate(knee, ankle, foot)
        : null;
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _detectorService.close();
    super.dispose();
  }

  // 计算预览的正确显示尺寸（portrait）。
  // controller.value.previewSize 返回横向（landscape）尺寸，
  // 竖屏时需要对调宽高得到 portrait 逻辑尺寸。
  Size get _portraitPreviewSize {
    final ps = _cameraController!.value.previewSize!;
    final swap = _rotation == InputImageRotation.rotation90deg ||
        _rotation == InputImageRotation.rotation270deg;
    return swap ? Size(ps.height, ps.width) : ps;
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final screen = MediaQuery.of(context).size;
    final portrait = _portraitPreviewSize;

    final double scale =
        math.max(screen.width / portrait.width, screen.height / portrait.height);
    final double scaledW = portrait.width * scale;
    final double scaledH = portrait.height * scale;
    final double offsetX = (scaledW - screen.width) / 2;
    final double offsetY = (scaledH - screen.height) / 2;

    return Scaffold(
      body: Stack(
        children: [
          // ① 预览：FittedBox.cover 保持比例填满屏幕，不变形
          Positioned.fill(
            child: ClipRect(
              child: FittedBox(
                fit: BoxFit.cover,
                alignment: Alignment.center,
                child: SizedBox(
                  width: portrait.width,
                  height: portrait.height,
                  child: CameraPreview(_cameraController!),
                ),
              ),
            ),
          ),

          // ② 骨骼叠加层（坐标计算不变）
          if (_imageSize != Size.zero)
            Positioned.fill(
              child: CustomPaint(
                painter: PosePainter(
                  poses: _poses,
                  imageSize: _imageSize,
                  rotation: _rotation,
                  portraitSize: portrait,
                  coverScale: scale,
                  coverOffsetX: offsetX,
                  coverOffsetY: offsetY,
                  monitoredConnections: const [],
                  monitoredLandmarks: const {},
                  angleLabels: [
                    (PoseLandmarkType.leftKnee, _kneeAngle),
                    (PoseLandmarkType.leftHip, _hipAngle),
                    (PoseLandmarkType.leftAnkle, _ankleAngle),
                  ],
                ),
              ),
            ),

          // ③ 调试信息
          Positioned(
            top: 60,
            left: 12,
            child: Container(
              padding: const EdgeInsets.all(6),
              color: AppColors.overlayLight,
              child: Text(
                'img: ${_imageSize.width.toInt()}×${_imageSize.height.toInt()}'
                '\nrot: $_rotation'
                '\nportrait: ${portrait.width.toInt()}×${portrait.height.toInt()}'
                '\nscale: ${scale.toStringAsFixed(2)}'
                '\noffX: ${offsetX.toInt()} offY: ${offsetY.toInt()}',
                style: const TextStyle(color: AppColors.primary, fontSize: 11),
              ),
            ),
          ),

          // ④ 状态提示
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.overlayLight,
                  borderRadius: BorderRadius.circular(AppSpacing.bubbleRadius),
                ),
                child: Text(
                  _poses.isEmpty ? AppCopy.standInFront : AppCopy.poseDetected,
                  style: const TextStyle(color: AppColors.onSurface),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

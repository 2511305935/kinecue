import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import 'package:kinecue/core/constants/copy.dart';
import 'package:kinecue/core/constants/debug_flags.dart';
import 'package:kinecue/core/constants/pose_thresholds.dart';
import 'package:kinecue/core/utils/angle_calculator.dart';
import 'package:kinecue/features/pose_detection/data/pose_detector_service.dart';
import 'package:kinecue/features/bicep_curl_coach/domain/curl_angle_model.dart';
import 'package:kinecue/features/bicep_curl_coach/domain/curl_form_checker.dart';
import 'package:kinecue/features/bicep_curl_coach/domain/curl_phase_detector.dart';
import 'package:kinecue/features/bicep_curl_coach/presentation/curl_feedback_widget.dart';
import 'package:kinecue/shared/widgets/pose_painter.dart';

class CurlCoachPage extends StatefulWidget {
  const CurlCoachPage({super.key, required this.cameras});

  final List<CameraDescription> cameras;

  @override
  State<CurlCoachPage> createState() => _CurlCoachPageState();
}

class _CurlCoachPageState extends State<CurlCoachPage> {
  // ── 弯举监控区配置 ─────────────────────────────────────
  static const _kCurlMonitoredConnections = [
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
    [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
    [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
    [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
  ];

  static const _kCurlMonitoredLandmarks = {
    PoseLandmarkType.leftShoulder,
    PoseLandmarkType.rightShoulder,
    PoseLandmarkType.leftElbow,
    PoseLandmarkType.rightElbow,
    PoseLandmarkType.leftWrist,
    PoseLandmarkType.rightWrist,
  };

  // ── 摄像头 / 检测 ────────────────────────────────────────
  CameraController? _cameraController;
  CameraLensDirection _lensDirection = CameraLensDirection.front;
  bool _isSwitching = false;
  final PoseDetectorService _detectorService = PoseDetectorService();
  List<Pose> _poses = [];
  bool _isProcessing = false;
  Size _imageSize = Size.zero;
  InputImageRotation _rotation = InputImageRotation.rotation270deg;

  // ── 弯举状态 ───────────────────────────────────────────
  CurlAngleModel _angles = const CurlAngleModel(
    elbowAngle: null,
    shoulderAngle: null,
  );
  CurlError _error = CurlError.good;
  final CurlPhaseDetector _phaseDetector = CurlPhaseDetector();
  int _repCount = 0;
  // 顶峰阶段累计达标帧数
  int _peakGoodFrames = 0;
  // 顶峰质量是否达标
  bool _peakQualityMet = false;
  static const int _kPeakQualityMinFrames = 3;
  // curling 阶段 bodySwing 坏帧累计
  int _curlingBadFrames = 0;
  static const int _kCurlingBadMinFrames = 3;
  static const int _kCurlingBadVoiceMinFrames = 15;

  // ── TTS ──────────────────────────────────────────────────
  final FlutterTts _tts = FlutterTts();
  CurlError _lastSpokenError = CurlError.good;
  int _lastSpokenRep = 0;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _initTts();
  }

  Future<void> _initCamera() async {
    final camera = widget.cameras.firstWhere(
      (c) => c.lensDirection == _lensDirection,
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

  Future<void> _switchCamera() async {
    if (_isSwitching) return;
    setState(() {
      _isSwitching = true;
      _poses = [];
      _imageSize = Size.zero;
    });

    await _cameraController?.dispose();
    _cameraController = null;

    _lensDirection = _lensDirection == CameraLensDirection.front
        ? CameraLensDirection.back
        : CameraLensDirection.front;

    await _initCamera();
    if (mounted) setState(() => _isSwitching = false);
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('zh-CN');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
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
      if (!mounted) return;

      final detectedPose = poses.isNotEmpty && _isPoseRealistic(poses.first)
          ? poses.first
          : null;

      final angles =
          detectedPose != null ? _computeAngles(detectedPose) : _angles;
      final newError = CurlFormChecker.check(angles);

      int newRepCount = _repCount;
      CurlPhase currentPhase = _phaseDetector.phase;

      if (angles.isFullyValid) {
        final prevPhase = _phaseDetector.phase;
        final (phase, cycleCompleted) = _phaseDetector.update(angles.elbowAngle!);
        currentPhase = phase;

        // 从伸展开始新一轮时重置顶峰质量标志
        if (prevPhase == CurlPhase.extended && phase == CurlPhase.curling) {
          _peakQualityMet = false;
          _peakGoodFrames = 0;
        }

        // curling 阶段：累计 bodySwing 坏帧
        if (phase == CurlPhase.curling && newError == CurlError.bodySwing) {
          if (_curlingBadFrames < _kCurlingBadVoiceMinFrames) {
            _curlingBadFrames++;
          }
        } else {
          _curlingBadFrames = 0;
        }

        // 顶峰阶段：累计达标帧数
        if (phase == CurlPhase.peak && newError == CurlError.good) {
          _peakGoodFrames++;
          if (_peakGoodFrames >= _kPeakQualityMinFrames) {
            _peakQualityMet = true;
          }
        }

        // 循环完成：仅当顶峰质量达标才计为有效弯举
        if (cycleCompleted) {
          if (_peakQualityMet) newRepCount = _repCount + 1;
          _peakQualityMet = false;
          _peakGoodFrames = 0;
        }
      }

      final displayError = _effectiveError(newError, currentPhase);
      final voiceError = _effectiveVoiceError(newError, currentPhase);

      setState(() {
        _poses = detectedPose != null ? [detectedPose] : [];
        _angles = angles;
        _error = displayError;
        _repCount = newRepCount;
      });

      _triggerTts(voiceError, newRepCount, currentPhase);
    } finally {
      _isProcessing = false;
    }
  }

  bool _isPoseRealistic(Pose pose) {
    double? minY, maxY;
    for (final t in [
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftAnkle,
      PoseLandmarkType.rightAnkle,
    ]) {
      final lm = pose.landmarks[t];
      if (lm == null) continue;
      if (minY == null || lm.y < minY) minY = lm.y;
      if (maxY == null || lm.y > maxY) maxY = lm.y;
    }
    if (minY == null || maxY == null) return false;
    return (maxY - minY) >= _imageSize.height * PoseThresholds.kPoseMinSpanRatio;
  }

  /// 视觉错误过滤。
  /// extended 阶段静默；bodySwing 需超过帧阈值。
  CurlError _effectiveError(CurlError raw, CurlPhase phase) {
    if (phase == CurlPhase.extended) return CurlError.good;
    if (raw == CurlError.bodySwing) {
      return _curlingBadFrames >= _kCurlingBadMinFrames
          ? CurlError.bodySwing
          : CurlError.good;
    }
    return raw;
  }

  /// 语音错误过滤：bodySwing 使用更长帧阈值。
  CurlError _effectiveVoiceError(CurlError raw, CurlPhase phase) {
    if (phase == CurlPhase.extended) return CurlError.good;
    if (raw == CurlError.bodySwing) {
      return _curlingBadFrames >= _kCurlingBadVoiceMinFrames
          ? CurlError.bodySwing
          : CurlError.good;
    }
    return raw;
  }

  void _triggerTts(CurlError newError, int newRepCount, CurlPhase phase) {
    if (newRepCount > _lastSpokenRep) {
      _lastSpokenRep = newRepCount;
      _lastSpokenError = newError;
      unawaited(_tts.stop().then((_) => _tts.speak(AppCopy.repAnnouncement(newRepCount))));
      return;
    }

    if (phase == CurlPhase.extended) {
      _lastSpokenError = newError;
      return;
    }

    // 纠错语音正在播放但动作已达标：立即打断
    if (newError == CurlError.good && _lastSpokenError != CurlError.good) {
      unawaited(_tts.stop());
      _lastSpokenError = newError;
      return;
    }

    if (newError != CurlError.good && newError != _lastSpokenError) {
      _lastSpokenError = newError;
      unawaited(_tts.speak(_textForError(newError)));
    } else {
      _lastSpokenError = newError;
    }
  }

  String _textForError(CurlError error) => switch (error) {
        CurlError.good => AppCopy.feedbackCurlGood,
        CurlError.bodySwing => AppCopy.feedbackBodySwing,
        CurlError.incompleteExtension => AppCopy.feedbackIncompleteExtension,
        CurlError.incompleteCurl => AppCopy.feedbackIncompleteCurl,
      };

  Set<PoseLandmarkType> _highlightedJoints(CurlError error) =>
      switch (error) {
        CurlError.bodySwing => {
            PoseLandmarkType.leftShoulder,
            PoseLandmarkType.rightShoulder,
            PoseLandmarkType.leftElbow,
            PoseLandmarkType.rightElbow,
          },
        _ => const {},
      };

  /// 从单帧姿态计算左臂肘角和肩角。
  CurlAngleModel _computeAngles(Pose pose) {
    PoseLandmark? lm(PoseLandmarkType t) {
      final l = pose.landmarks[t];
      return (l != null && l.likelihood >= PoseThresholds.kLandmarkConfidence)
          ? l
          : null;
    }

    final hip = lm(PoseLandmarkType.leftHip);
    final shoulder = lm(PoseLandmarkType.leftShoulder);
    final elbow = lm(PoseLandmarkType.leftElbow);
    final wrist = lm(PoseLandmarkType.leftWrist);

    return CurlAngleModel(
      elbowAngle: (shoulder != null && elbow != null && wrist != null)
          ? AngleCalculator.calculate(shoulder, elbow, wrist)
          : null,
      shoulderAngle: (hip != null && shoulder != null && elbow != null)
          ? AngleCalculator.calculate(hip, shoulder, elbow)
          : null,
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _detectorService.close();
    _tts.stop();
    super.dispose();
  }

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

    final bool isLandscape = screen.width > screen.height;
    final double scale = isLandscape
        ? math.min(screen.width / portrait.width, screen.height / portrait.height)
        : math.max(screen.width / portrait.width, screen.height / portrait.height);

    final double scaledW = portrait.width * scale;
    final double scaledH = portrait.height * scale;
    final double offsetX = (scaledW - screen.width) / 2;
    final double offsetY = (scaledH - screen.height) / 2;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ① 摄像头预览
          Positioned.fill(
            child: ClipRect(
              child: FittedBox(
                fit: isLandscape ? BoxFit.contain : BoxFit.cover,
                alignment: Alignment.center,
                child: SizedBox(
                  width: portrait.width,
                  height: portrait.height,
                  child: CameraPreview(_cameraController!),
                ),
              ),
            ),
          ),

          // ② 蒙版
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black.withValues(alpha: 0.10),
            ),
          ),

          // ③ 骨骼叠加
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
                  monitoredConnections: _kCurlMonitoredConnections,
                  monitoredLandmarks: _kCurlMonitoredLandmarks,
                  angleLabels: [
                    (PoseLandmarkType.leftElbow, _angles.elbowAngle),
                    (PoseLandmarkType.leftShoulder, _angles.shoulderAngle),
                  ],
                  highlightedJoints: _highlightedJoints(_error),
                  isGood: _error == CurlError.good && _phaseDetector.phase != CurlPhase.extended,
                ),
              ),
            ),

          // ④ 反馈气泡
          Positioned(
            right: 10,
            top: MediaQuery.of(context).padding.top + 60,
            bottom: MediaQuery.of(context).padding.bottom + 20,
            child: Center(
              child: CurlFeedbackWidget(
                angles: _angles,
                error: _error,
                repCount: _repCount,
              ),
            ),
          ),

          // ⑤ 调试信息
          if (kShowDebugOverlay)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.all(6),
                color: Colors.black54,
                child: Text(
                  'img: ${_imageSize.width.toInt()}×${_imageSize.height.toInt()}'
                  '\nrot: $_rotation'
                  '\nportrait: ${portrait.width.toInt()}×${portrait.height.toInt()}'
                  '\nscale: ${scale.toStringAsFixed(2)}'
                  '\noffX: ${offsetX.toInt()} offY: ${offsetY.toInt()}',
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 11,
                  ),
                ),
              ),
            ),

          // ⑥ 切换摄像头按钮
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: IconButton(
              onPressed: _isSwitching ? null : _switchCamera,
              icon: const Icon(Icons.cameraswitch_rounded),
              color: Colors.white,
              iconSize: 28,
              style: IconButton.styleFrom(
                backgroundColor: Colors.black45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

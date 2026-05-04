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
import 'package:kinecue/features/squat_coach/domain/squat_angle_model.dart';
import 'package:kinecue/features/squat_coach/domain/squat_form_checker.dart';
import 'package:kinecue/features/squat_coach/domain/squat_phase_detector.dart';
import 'package:kinecue/features/squat_coach/presentation/squat_feedback_widget.dart';
import 'package:kinecue/shared/widgets/pose_painter.dart';

class SquatCoachPage extends StatefulWidget {
  const SquatCoachPage({super.key, required this.cameras});

  final List<CameraDescription> cameras;

  @override
  State<SquatCoachPage> createState() => _SquatCoachPageState();
}

class _SquatCoachPageState extends State<SquatCoachPage> {
  // ── 摄像头 / 检测 ────────────────────────────────────────
  CameraController? _cameraController;
  CameraLensDirection _lensDirection = CameraLensDirection.front;
  bool _isSwitching = false;
  final PoseDetectorService _detectorService = PoseDetectorService();
  List<Pose> _poses = [];
  bool _isProcessing = false;
  Size _imageSize = Size.zero;
  InputImageRotation _rotation = InputImageRotation.rotation270deg;

  // ── 深蹲状态 ─────────────────────────────────────────────
  SquatAngleModel _angles = const SquatAngleModel(
    kneeAngle: null,
    hipAngle: null,
    ankleAngle: null,
  );
  SquatError _error = SquatError.good;
  final SquatPhaseDetector _phaseDetector = SquatPhaseDetector();
  int _repCount = 0;
  // 当前循环底部累计达标帧数；达到阈值才视为蹲够深
  int _bottomGoodFrames = 0;
  // 底部质量是否达标（_bottomGoodFrames >= _kBottomQualityMinFrames）
  bool _bottomQualityMet = false;
  // 底部质量最低帧数：防止 ML Kit 单帧抖动误触发
  static const int _kBottomQualityMinFrames = 3;
  // 下蹲阶段保持不合格深度的帧计数
  int _descendingBadFrames = 0;
  // 下蹲阶段触发视觉反馈（红色线条）所需最低帧数（≈100ms @ 30fps）
  static const int _kDescendingBadMinFrames = 3;
  // 下蹲阶段触发语音纠错所需最低帧数（≈500ms @ 30fps）
  // 快速下蹲可在 0.3-0.5s 内通过不合格区间，不应触发语音
  static const int _kDescendingBadVoiceMinFrames = 15;

  // ── TTS ──────────────────────────────────────────────────
  final FlutterTts _tts = FlutterTts();
  SquatError _lastSpokenError = SquatError.good;
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

      // 过滤误检测：肩→踝纵向跨度不足帧高 kPoseMinSpanRatio 时视为衣物/家具误识别
      final detectedPose = poses.isNotEmpty &&
              _isPoseRealistic(poses.first)
          ? poses.first
          : null;

      final angles =
          detectedPose != null ? _computeAngles(detectedPose) : _angles;
      final newError = SquatFormChecker.check(angles);

      int newRepCount = _repCount;
      SquatPhase currentPhase = _phaseDetector.phase;
      // 仅在三个角度全部可信（肩/髋/膝/踝/脚趾均置信度 > 0.5）时才更新状态机，
      // 防止 ML Kit 推算不可见的下半身关键点导致误计次。
      if (angles.isFullyValid) {
        final prevPhase = _phaseDetector.phase;
        final (phase, cycleCompleted) = _phaseDetector.update(angles.kneeAngle!);
        currentPhase = phase;

        // 从站立开始新一轮时重置底部质量标志
        if (prevPhase == SquatPhase.standing &&
            phase == SquatPhase.descending) {
          _bottomQualityMet = false;
          _bottomGoodFrames = 0;
        }

        // 下蹲阶段：累计不合格深度帧数（超阈值才启用"继续蹲低"反馈）
        if (phase == SquatPhase.descending &&
            newError == SquatError.notDeepEnough) {
          if (_descendingBadFrames < _kDescendingBadMinFrames) {
            _descendingBadFrames++;
          }
        } else {
          _descendingBadFrames = 0;
        }

        // 底部阶段：累计达标帧数，达到阈值才认为蹲够深
        // 用原始 error 判断，防止单帧 ML Kit 抖动误触发
        if (phase == SquatPhase.bottom && newError == SquatError.good) {
          _bottomGoodFrames++;
          if (_bottomGoodFrames >= _kBottomQualityMinFrames) {
            _bottomQualityMet = true;
          }
        }

        // 循环完成：仅当底部质量达标才计为有效深蹲
        if (cycleCompleted) {
          if (_bottomQualityMet) newRepCount = _repCount + 1;
          _bottomQualityMet = false;
          _bottomGoodFrames = 0;
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

  /// 判断检测到的姿态是否可能是真实人体（过滤衣物、家具等误识别）。
  ///
  /// 要求左/右肩与左/右踝的纵向跨度 ≥ 帧高 × [PoseThresholds.kPoseMinSpanRatio]。
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

  /// 根据当前阶段过滤原始错误，返回应展示给用户的有效错误。
  ///
  /// - 站立阶段静默（膝角 >150° 时 notDeepEnough 属正常值，不提示）。
  /// - notDeepEnough 仅在 ascending 且底部质量未达标时提示（即蹲而不够深再起身）。
  /// - 其余错误（backTooForward）在任何非站立阶段均正常显示。
  SquatError _effectiveError(SquatError raw, SquatPhase phase) {
    if (phase == SquatPhase.standing) return SquatError.good;
    if (raw == SquatError.notDeepEnough) {
      // 下蹲中：保持不合格深度超过阈值帧数才提示（避免快速路过时误报）
      if (phase == SquatPhase.descending) {
        return _descendingBadFrames >= _kDescendingBadMinFrames
            ? SquatError.notDeepEnough
            : SquatError.good;
      }
      // 起身中：底部质量未达标才提示
      return (phase == SquatPhase.ascending && !_bottomQualityMet)
          ? SquatError.notDeepEnough
          : SquatError.good;
    }
    return raw;
  }

  /// 语音专用错误过滤：与视觉相同逻辑，但下蹲阶段使用更长的帧阈值（0.5s）。
  /// 快速下蹲通过不合格区间时红线会闪现（视觉灵敏），但不触发语音。
  SquatError _effectiveVoiceError(SquatError raw, SquatPhase phase) {
    if (phase == SquatPhase.standing) return SquatError.good;
    if (raw == SquatError.notDeepEnough) {
      if (phase == SquatPhase.descending) {
        return _descendingBadFrames >= _kDescendingBadVoiceMinFrames
            ? SquatError.notDeepEnough
            : SquatError.good;
      }
      return (phase == SquatPhase.ascending && !_bottomQualityMet)
          ? SquatError.notDeepEnough
          : SquatError.good;
    }
    return raw;
  }

  /// 语音触发规则：
  /// - 计次优先：完成一次播报"第N次"，打断正在播放的纠错语音
  /// - 动作从错误变为达标时，立即停止纠错语音（快速下蹲场景）
  /// - 站立阶段静默同步，不播报任何错误（避免站立膝角 >110° 误触发）
  /// - 蹲起过程（非站立）中播报实际错误，"动作标准"改为纯视觉反馈
  void _triggerTts(SquatError newError, int newRepCount, SquatPhase phase) {
    if (newRepCount > _lastSpokenRep) {
      _lastSpokenRep = newRepCount;
      _lastSpokenError = newError;
      unawaited(_tts.stop().then((_) => _tts.speak(AppCopy.repAnnouncement(newRepCount))));
      return;
    }

    // 站立阶段静默同步，不播报
    if (phase == SquatPhase.standing) {
      _lastSpokenError = newError;
      return;
    }

    // 纠错语音正在播放但动作已达标：立即打断
    if (newError == SquatError.good && _lastSpokenError != SquatError.good) {
      unawaited(_tts.stop());
      _lastSpokenError = newError;
      return;
    }

    // 蹲起过程中，仅播报错误（good 不播）
    if (newError != SquatError.good && newError != _lastSpokenError) {
      _lastSpokenError = newError;
      unawaited(_tts.speak(_textForError(newError)));
    } else {
      _lastSpokenError = newError;
    }
  }

  String _textForError(SquatError error) => switch (error) {
        SquatError.good => AppCopy.feedbackGood,
        SquatError.notDeepEnough => AppCopy.feedbackNotDeepEnough,
        SquatError.kneeOverToe => AppCopy.feedbackKneeOverToe,
        SquatError.backTooForward => AppCopy.feedbackBackTooForward,
      };

  /// 根据错误类型返回需要高亮（红色）的关节集合。
  Set<PoseLandmarkType> _highlightedJoints(SquatError error) =>
      switch (error) {
        SquatError.notDeepEnough => {
            PoseLandmarkType.leftHip,
            PoseLandmarkType.leftKnee,
            PoseLandmarkType.leftAnkle,
            PoseLandmarkType.rightHip,
            PoseLandmarkType.rightKnee,
            PoseLandmarkType.rightAnkle,
          },
        SquatError.backTooForward => {
            PoseLandmarkType.leftShoulder,
            PoseLandmarkType.rightShoulder,
            PoseLandmarkType.leftHip,
            PoseLandmarkType.rightHip,
          },
        _ => const {},
      };

  /// 从单帧姿态计算左侧三关节角度。
  SquatAngleModel _computeAngles(Pose pose) {
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

    return SquatAngleModel(
      kneeAngle: (hip != null && knee != null && ankle != null)
          ? AngleCalculator.calculate(hip, knee, ankle)
          : null,
      hipAngle: (shoulder != null && hip != null && knee != null)
          ? AngleCalculator.calculate(shoulder, hip, knee)
          : null,
      ankleAngle: (knee != null && ankle != null && foot != null)
          ? AngleCalculator.calculate(knee, ankle, foot)
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

    // 横屏（Mac / iPad landscape）：contain 完整显示竖向画面，两侧留黑边
    // 竖屏（iPhone）：cover 填满屏幕（与之前行为一致）
    final bool isLandscape = screen.width > screen.height;
    final double scale = isLandscape
        ? math.min(screen.width / portrait.width, screen.height / portrait.height)
        : math.max(screen.width / portrait.width, screen.height / portrait.height);

    final double scaledW = portrait.width * scale;
    final double scaledH = portrait.height * scale;
    // 横屏时 offsetX 为负值（黑边宽度），_toScreen 中减去负值即正确加上偏移
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

          // ② 极浅全屏蒙版（提升骨骼与气泡可读性，不遮挡姿态）
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black.withValues(alpha: 0.10),
            ),
          ),

          // ③ 骨骼叠加 + 角度文字 + 错误关节红色高亮
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
                  kneeAngle: _angles.kneeAngle,
                  hipAngle: _angles.hipAngle,
                  ankleAngle: _angles.ankleAngle,
                  highlightedJoints: _highlightedJoints(_error),
                  isGood: _error == SquatError.good && _phaseDetector.phase != SquatPhase.standing,
                ),
              ),
            ),

          // ④ 反馈气泡（右侧，垂直居中，避开顶部按钮区）
          Positioned(
            right: 10,
            top: MediaQuery.of(context).padding.top + 60,
            bottom: MediaQuery.of(context).padding.bottom + 20,
            child: Center(
              child: SquatFeedbackWidget(
                angles: _angles,
                error: _error,
                repCount: _repCount,
              ),
            ),
          ),

          // ⑤ 调试信息叠加层（编译开关 SHOW_DEBUG_OVERLAY 控制）
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

          // ⑥ 切换摄像头按钮（右上角）
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

import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import 'package:kinecue/core/theme/app_theme.dart';

/// 全部骨骼连线（14 条）。
const allConnections = [
  [PoseLandmarkType.nose, PoseLandmarkType.leftEar],
  [PoseLandmarkType.nose, PoseLandmarkType.rightEar],
  [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
  [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
  [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
  [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
  [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
  [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
  [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
  [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
  [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee],
  [PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],
  [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee],
  [PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle],
];

/// 将骨骼关键点和连线绘制到摄像头预览上方。
///
/// [monitoredConnections] 指定监控区连线（粗线，状态着色）。
/// [monitoredLandmarks] 指定监控区关节点（大点，状态着色）。
/// [angleLabels] 指定在哪个关节旁显示什么角度值。
/// [highlightedJoints] 两端点均在集合内的连线绘制为红色。
/// [isGood] 为 true 时监控区线条变绿。
class PosePainter extends CustomPainter {
  PosePainter({
    required this.poses,
    required this.imageSize,
    required this.rotation,
    required this.portraitSize,
    required this.coverScale,
    required this.coverOffsetX,
    required this.coverOffsetY,
    required this.monitoredConnections,
    required this.monitoredLandmarks,
    this.angleLabels = const [],
    this.highlightedJoints = const {},
    this.isGood = false,
  });

  final List<Pose> poses;
  final Size imageSize;
  final InputImageRotation rotation;
  final Size portraitSize;
  final double coverScale;
  final double coverOffsetX;
  final double coverOffsetY;

  /// 监控区连线（粗线，白/绿/红）。
  final List<List<PoseLandmarkType>> monitoredConnections;
  /// 监控区关键点（大点，白/绿）。
  final Set<PoseLandmarkType> monitoredLandmarks;
  /// 在指定关节旁显示角度值：(关节类型, 角度)。
  final List<(PoseLandmarkType, double?)> angleLabels;
  /// 两端点均在此集合内的监控区连线绘制为红色。
  final Set<PoseLandmarkType> highlightedJoints;
  /// 动作达标时监控区线条变绿。
  final bool isGood;

  // ── 监控区画笔 ──────────────────────────────────────────
  Paint get _monitoredPaint => Paint()
    ..color = isGood ? AppColors.primary : AppColors.onSurface
    ..strokeWidth = 5
    ..style = PaintingStyle.stroke;

  final _errorLinePaint = Paint()
    ..color = AppColors.error
    ..strokeWidth = 5
    ..style = PaintingStyle.stroke;

  Paint get _monitoredDotPaint => Paint()
    ..color = isGood ? AppColors.primary : AppColors.onSurface
    ..style = PaintingStyle.fill;

  // ── 非监控区画笔 ────────────────────────────────────────
  final _secondaryPaint = Paint()
    ..color = AppColors.onSurfaceLow
    ..strokeWidth = 2
    ..style = PaintingStyle.stroke;

  final _secondaryDotPaint = Paint()
    ..color = AppColors.onSurfaceLow
    ..style = PaintingStyle.fill;

  /// 非监控区连线 = 全部连线 - 监控区连线。
  late final List<List<PoseLandmarkType>> _secondaryConnections = () {
    final monSet = {
      for (final c in monitoredConnections) '${c[0]}|${c[1]}',
    };
    return [
      for (final c in allConnections)
        if (!monSet.contains('${c[0]}|${c[1]}')) c,
    ];
  }();

  @override
  void paint(Canvas canvas, Size size) {
    for (final pose in poses) {
      // ① 先画非监控区（底层）
      for (final conn in _secondaryConnections) {
        _drawConn(canvas, pose, conn, _secondaryPaint);
      }
      // ② 再画监控区（顶层）
      for (final conn in monitoredConnections) {
        final isError = highlightedJoints.contains(conn[0]) &&
            highlightedJoints.contains(conn[1]);
        _drawConn(canvas, pose, conn, isError ? _errorLinePaint : _monitoredPaint);
      }
      // ③ 关节点
      for (final entry in pose.landmarks.entries) {
        final lm = entry.value;
        if (lm.likelihood < 0.5) continue;
        final isMonitored = monitoredLandmarks.contains(entry.key);
        canvas.drawCircle(
          _toScreen(lm.x, lm.y),
          isMonitored ? 6 : 4,
          isMonitored ? _monitoredDotPaint : _secondaryDotPaint,
        );
      }
      // ④ 角度文字
      _drawAngles(canvas, pose);
    }
  }

  void _drawConn(Canvas canvas, Pose pose, List<PoseLandmarkType> conn, Paint paint) {
    final a = pose.landmarks[conn[0]];
    final b = pose.landmarks[conn[1]];
    if (a == null || b == null) return;
    if (a.likelihood < 0.5 || b.likelihood < 0.5) return;
    canvas.drawLine(_toScreen(a.x, a.y), _toScreen(b.x, b.y), paint);
  }

  void _drawAngles(Canvas canvas, Pose pose) {
    for (final (type, angle) in angleLabels) {
      if (angle == null) continue;
      final lm = pose.landmarks[type];
      if (lm == null || lm.likelihood < 0.5) continue;
      final pos = _toScreen(lm.x, lm.y);
      final tp = TextPainter(
        text: TextSpan(
          text: '${angle.toStringAsFixed(0)}°',
          style: const TextStyle(
            color: AppColors.onSurface,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos.translate(8, -8));
    }
  }

  Offset _toScreen(double lx, double ly) {
    double px, py;

    switch (rotation) {
      case InputImageRotation.rotation270deg:
        px = portraitSize.width - lx * portraitSize.width / imageSize.width;
        py = ly * portraitSize.height / imageSize.height;

      case InputImageRotation.rotation90deg:
        px = lx * portraitSize.width / imageSize.width;
        py = ly * portraitSize.height / imageSize.height;

      default:
        px = lx * portraitSize.width / imageSize.width;
        py = ly * portraitSize.height / imageSize.height;
    }

    return Offset(
      px * coverScale - coverOffsetX,
      py * coverScale - coverOffsetY,
    );
  }

  @override
  bool shouldRepaint(PosePainter old) =>
      old.poses != poses ||
      old.coverScale != coverScale ||
      old.angleLabels != angleLabels ||
      old.highlightedJoints != highlightedJoints ||
      old.isGood != isGood;
}

import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// 将骨骼关键点和连线绘制到摄像头预览上方。
///
/// [kneeAngle]、[hipAngle]、[ankleAngle] 不为 null 时，在对应关节旁叠加角度文字。
/// [highlightedJoints] 不为空时，两端点均在集合内的连线绘制为红色（错误提示）。
class PosePainter extends CustomPainter {
  PosePainter({
    required this.poses,
    required this.imageSize,
    required this.rotation,
    required this.portraitSize,
    required this.coverScale,
    required this.coverOffsetX,
    required this.coverOffsetY,
    this.kneeAngle,
    this.hipAngle,
    this.ankleAngle,
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
  final double? kneeAngle;
  final double? hipAngle;
  final double? ankleAngle;
  /// 两端点均在此集合内的连线将以红色绘制。
  final Set<PoseLandmarkType> highlightedJoints;
  /// 动作达标时监控区线条变绿。
  final bool isGood;

  /// 监控区连线：肩-髋（躯干）、髋-膝、膝-踝（下肢）
  static const _monitoredConnections = [
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
    [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
    [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee],
    [PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],
    [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee],
    [PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle],
  ];

  /// 非监控区连线：头、手臂、横杆
  static const _secondaryConnections = [
    [PoseLandmarkType.nose, PoseLandmarkType.leftEar],
    [PoseLandmarkType.nose, PoseLandmarkType.rightEar],
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
    [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
    [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
    [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
    [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
  ];

  /// 监控区关键点集合（用于区分关节点大小和颜色）
  static const _monitoredLandmarks = {
    PoseLandmarkType.leftShoulder,
    PoseLandmarkType.rightShoulder,
    PoseLandmarkType.leftHip,
    PoseLandmarkType.rightHip,
    PoseLandmarkType.leftKnee,
    PoseLandmarkType.rightKnee,
    PoseLandmarkType.leftAnkle,
    PoseLandmarkType.rightAnkle,
  };

  // ── 监控区画笔（根据状态动态选择） ─────────────────────────
  Paint get _monitoredPaint => Paint()
    ..color = isGood ? Colors.greenAccent : Colors.white
    ..strokeWidth = 5
    ..style = PaintingStyle.stroke;

  final _errorLinePaint = Paint()
    ..color = Colors.redAccent
    ..strokeWidth = 5
    ..style = PaintingStyle.stroke;

  Paint get _monitoredDotPaint => Paint()
    ..color = isGood ? Colors.greenAccent : Colors.white
    ..style = PaintingStyle.fill;

  // ── 非监控区画笔 ────────────────────────────────────────
  final _secondaryPaint = Paint()
    ..color = Colors.white38
    ..strokeWidth = 2
    ..style = PaintingStyle.stroke;

  final _secondaryDotPaint = Paint()
    ..color = Colors.white38
    ..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    for (final pose in poses) {
      // ① 先画非监控区（底层，不抢视觉）
      for (final conn in _secondaryConnections) {
        _drawConn(canvas, pose, conn, _secondaryPaint);
      }
      // ② 再画监控区（顶层，醒目）
      for (final conn in _monitoredConnections) {
        final isError = highlightedJoints.contains(conn[0]) &&
            highlightedJoints.contains(conn[1]);
        _drawConn(canvas, pose, conn, isError ? _errorLinePaint : _monitoredPaint);
      }
      // ③ 关节点：监控区大+青，非监控区小+灰
      for (final entry in pose.landmarks.entries) {
        final lm = entry.value;
        if (lm.likelihood < 0.5) continue;
        final isMonitored = _monitoredLandmarks.contains(entry.key);
        canvas.drawCircle(
          _toScreen(lm.x, lm.y),
          isMonitored ? 6 : 4,
          isMonitored ? _monitoredDotPaint : _secondaryDotPaint,
        );
      }
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
    void drawAt(PoseLandmarkType type, double? angle) {
      if (angle == null) return;
      final lm = pose.landmarks[type];
      if (lm == null || lm.likelihood < 0.5) return;
      final pos = _toScreen(lm.x, lm.y);
      final tp = TextPainter(
        text: TextSpan(
          text: '${angle.toStringAsFixed(0)}°',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos.translate(8, -8));
    }

    drawAt(PoseLandmarkType.leftKnee, kneeAngle);
    drawAt(PoseLandmarkType.leftHip, hipAngle);
    drawAt(PoseLandmarkType.leftAnkle, ankleAngle);
  }

  /// 坐标转换：ML Kit 图像坐标 → 屏幕坐标
  ///
  /// iOS 上 ML Kit 返回的 landmark 坐标已是修正后的 portrait 显示坐标。
  ///   rotation270（前置摄像头）：含内建镜像
  ///   rotation90（后置摄像头）：无镜像
  /// 再叠加 BoxFit.cover 的 scale + offset 与预览画面对齐。
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
      old.kneeAngle != kneeAngle ||
      old.hipAngle != hipAngle ||
      old.ankleAngle != ankleAngle ||
      old.highlightedJoints != highlightedJoints ||
      old.isGood != isGood;
}

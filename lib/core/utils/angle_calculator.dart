import 'dart:math' as math;

import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// 关节角度计算工具（纯函数，无副作用）。
abstract final class AngleCalculator {
  /// 计算三点构成的关节角度（向量点积法）。
  ///
  /// [a] 近端关节点（如髋部）
  /// [b] 中心关节点（如膝盖）— 角度顶点
  /// [c] 远端关节点（如踝部）
  ///
  /// 返回 0–180 度。若 BA 或 BC 向量长度为零（两点重合）返回 0。
  ///
  /// 公式：
  ///   BA = A - B，BC = C - B
  ///   θ = arccos( BA·BC / (|BA|·|BC|) ) × 180 / π
  static double calculate(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
    final bax = a.x - b.x;
    final bay = a.y - b.y;
    final bcx = c.x - b.x;
    final bcy = c.y - b.y;

    final dot = bax * bcx + bay * bcy;
    final magBA = math.sqrt(bax * bax + bay * bay);
    final magBC = math.sqrt(bcx * bcx + bcy * bcy);

    if (magBA == 0 || magBC == 0) return 0;

    // clamp 防止浮点误差超出 arccos 定义域 [-1, 1]
    final cosAngle = (dot / (magBA * magBC)).clamp(-1.0, 1.0);
    return math.acos(cosAngle) * 180 / math.pi;
  }
}

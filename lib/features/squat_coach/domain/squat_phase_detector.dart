import 'package:kinecue/core/constants/pose_thresholds.dart';

/// 深蹲阶段。
enum SquatPhase {
  /// 站立（膝角 > 150°）。
  standing,
  /// 下蹲中（95° < 膝角 ≤ 150°，来自站立）。
  descending,
  /// 最低点（膝角 ≤ 95°）。
  bottom,
  /// 起身中（95° < 膝角 ≤ 150°，来自最低点）。
  ascending,
}

/// 深蹲阶段检测器（有状态，不含计次逻辑）。
///
/// 每帧调用 [update]，返回当前阶段和本帧是否完成了一次完整循环。
/// 计次权由调用方持有：仅当 cycleCompleted = true 且底部质量达标时才算有效深蹲。
class SquatPhaseDetector {
  SquatPhase _phase = SquatPhase.standing;

  /// 当前深蹲阶段。
  SquatPhase get phase => _phase;

  /// 根据当前帧膝角更新状态机。
  ///
  /// 返回 (当前阶段, cycleCompleted)：
  /// - [cycleCompleted] = true 表示本帧从 ascending 回到 standing，
  ///   完成了一次完整的 standing→bottom→standing 循环。
  ///   调用方根据底部质量决定是否记为有效深蹲。
  (SquatPhase, bool) update(double kneeAngle) {
    final prev = _phase;
    bool cycleCompleted = false;

    if (kneeAngle > PoseThresholds.kKneeStanding) {
      if (prev == SquatPhase.ascending) {
        cycleCompleted = true;
      }
      _phase = SquatPhase.standing;
    } else if (kneeAngle <= PoseThresholds.kKneeMax) {
      _phase = SquatPhase.bottom;
    } else {
      // 95° < 膝角 ≤ 150°：由来源方向决定阶段
      if (prev == SquatPhase.standing || prev == SquatPhase.descending) {
        _phase = SquatPhase.descending;
      } else {
        _phase = SquatPhase.ascending;
      }
    }

    return (_phase, cycleCompleted);
  }

  /// 重置状态机。
  void reset() {
    _phase = SquatPhase.standing;
  }
}

import 'package:kinecue/core/constants/pose_thresholds.dart';

/// 弯举阶段。
enum CurlPhase {
  /// 手臂伸直（肘角 > 160°）。
  extended,
  /// 弯曲中（40° < 肘角 ≤ 160°，来自 extended）。
  curling,
  /// 顶峰收缩（肘角 ≤ 40°）。
  peak,
  /// 放下中（40° < 肘角 ≤ 160°，来自 peak）。
  lowering,
}

/// 弯举阶段检测器（有状态）。
///
/// 每帧调用 [update]，返回当前阶段和本帧是否完成了一次完整循环。
/// 完整循环：extended → curling → peak → lowering → extended。
class CurlPhaseDetector {
  CurlPhase _phase = CurlPhase.extended;

  /// 当前弯举阶段。
  CurlPhase get phase => _phase;

  /// 根据当前帧肘角更新状态机。
  ///
  /// 返回 (当前阶段, cycleCompleted)：
  /// - [cycleCompleted] = true 表示本帧从 lowering 回到 extended，
  ///   完成了一次完整循环。
  (CurlPhase, bool) update(double elbowAngle) {
    final prev = _phase;
    bool cycleCompleted = false;

    if (elbowAngle > PoseThresholds.kCurlElbowExtended) {
      if (prev == CurlPhase.lowering) {
        cycleCompleted = true;
      }
      _phase = CurlPhase.extended;
    } else if (elbowAngle <= PoseThresholds.kCurlElbowPeak) {
      _phase = CurlPhase.peak;
    } else {
      // 40° < 肘角 ≤ 160°：由来源方向决定阶段
      if (prev == CurlPhase.extended || prev == CurlPhase.curling) {
        _phase = CurlPhase.curling;
      } else {
        _phase = CurlPhase.lowering;
      }
    }

    return (_phase, cycleCompleted);
  }

  /// 重置状态机。
  void reset() {
    _phase = CurlPhase.extended;
  }
}

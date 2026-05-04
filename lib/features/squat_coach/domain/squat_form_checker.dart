import 'package:kinecue/core/constants/pose_thresholds.dart';
import 'package:kinecue/features/squat_coach/domain/squat_angle_model.dart';

/// 深蹲动作错误类型。
enum SquatError {
  /// 动作标准。
  good,
  /// 未蹲到位：膝角超过上限。
  notDeepEnough,
  /// 膝盖超过脚尖（当前版本暂不触发，需位置数据支持）。
  kneeOverToe,
  /// 躯干过度前倾：髋角低于下限。
  backTooForward,
}

/// 深蹲动作错误判定器（纯函数）。
///
/// 优先级：backTooForward > notDeepEnough > good
/// kneeOverToe 需关键点水平位置数据，当前版本暂不判定。
abstract final class SquatFormChecker {
  /// 根据当前帧角度判定动作错误类型。
  ///
  /// 若 [model] 中对应角度为 null（置信度不足），跳过该项检查。
  static SquatError check(SquatAngleModel model) {
    // 优先级 1：躯干前倾
    final hip = model.hipAngle;
    if (hip != null && hip < PoseThresholds.kHipMin) {
      return SquatError.backTooForward;
    }

    // 优先级 2：深度不足
    final knee = model.kneeAngle;
    if (knee != null && knee > PoseThresholds.kKneeMax) {
      return SquatError.notDeepEnough;
    }

    return SquatError.good;
  }
}

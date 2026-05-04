import 'package:kinecue/core/constants/pose_thresholds.dart';
import 'package:kinecue/features/bicep_curl_coach/domain/curl_angle_model.dart';

/// 弯举错误类型。
enum CurlError {
  /// 动作标准。
  good,
  /// 身体晃动（大臂不固定，借力摆动）。
  bodySwing,
  /// 不完全伸展（手臂未伸直就开始下一次）。
  incompleteExtension,
  /// 不完全弯曲（未到达顶峰就放下）。
  incompleteCurl,
}

/// 弯举帧级错误判定（纯函数）。
///
/// 仅判定每帧可观测的错误（bodySwing）。
/// incompleteExtension 和 incompleteCurl 由 coach page 在状态转换时判定。
abstract final class CurlFormChecker {
  static CurlError check(CurlAngleModel model) {
    final shoulder = model.shoulderAngle;
    if (shoulder != null &&
        (shoulder < PoseThresholds.kCurlShoulderMin ||
            shoulder > PoseThresholds.kCurlShoulderMax)) {
      return CurlError.bodySwing;
    }
    return CurlError.good;
  }
}

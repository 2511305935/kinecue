/// 关节角度阈值的唯一数据源。
///
/// 禁止在 widget 或 checker 内部硬编码角度数字，统一从此处引用。
/// 当前值为初始默认值，需在真实用户数据上标定后调整。
abstract final class PoseThresholds {
  // ── 膝关节（髋 - 膝 - 踝） ──────────────────────────────
  /// 深蹲到位判定：膝角下限
  static const double kKneeMin = 70.0;
  /// 深蹲到位判定：膝角上限（≤ 此值视为蹲到位）
  static const double kKneeMax = 95.0;
  /// 站立判定阈值（膝角 > 此值视为站立）
  static const double kKneeStanding = 150.0;

  // ── 髋关节（肩 - 髋 - 膝） ──────────────────────────────
  /// 躯干前倾角下限
  static const double kHipMin = 45.0;
  /// 躯干前倾角上限
  static const double kHipMax = 90.0;

  // ── 踝关节（膝 - 踝 - 脚趾） ────────────────────────────
  /// 踝背屈下限
  static const double kAnkleMin = 70.0;
  /// 踝背屈上限
  static const double kAnkleMax = 100.0;

  // ── 弯举 · 肘关节（肩 - 肘 - 腕） ──────────────────────
  /// 手臂伸直判定（> 此值 = 完全伸展）
  static const double kCurlElbowExtended = 160.0;
  /// 弯举顶峰判定（< 此值 = 到达顶峰）
  static const double kCurlElbowPeak = 40.0;

  // ── 弯举 · 肩关节（髋 - 肩 - 肘） ──────────────────────
  /// 大臂前倾下限（低于此值 = 身体晃动/借力）
  static const double kCurlShoulderMin = 5.0;
  /// 大臂后摆上限（高于此值 = 身体晃动/借力）
  static const double kCurlShoulderMax = 35.0;

  // ── 置信度 ───────────────────────────────────────────────
  /// 关键点置信度阈值，低于此值不参与角度计算
  static const double kLandmarkConfidence = 0.5;

  // ── 骨架现实性 ───────────────────────────────────────────
  /// 肩到踝纵向跨度占帧高度的最低比例；低于此值视为误检测（如衣物、家具）
  static const double kPoseMinSpanRatio = 0.20;
}

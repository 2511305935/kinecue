/// 单帧深蹲三关节角度快照。
///
/// 任一关节的三个关键点中只要有一个置信度 < 0.5，
/// 对应角度为 null，不参与规则判定，保持上一帧结果。
class SquatAngleModel {
  const SquatAngleModel({
    required this.kneeAngle,
    required this.hipAngle,
    required this.ankleAngle,
  });

  /// 膝关节角度（髋 - 膝 - 踝），null 表示本帧不可信。
  final double? kneeAngle;

  /// 髋关节角度（肩 - 髋 - 膝），null 表示本帧不可信。
  final double? hipAngle;

  /// 踝关节角度（膝 - 踝 - 脚趾），null 表示本帧不可信。
  final double? ankleAngle;

  /// 三个角度均可信时为 true。
  bool get isFullyValid =>
      kneeAngle != null && hipAngle != null && ankleAngle != null;
}

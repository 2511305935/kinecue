/// 弯举单帧角度数据。
class CurlAngleModel {
  const CurlAngleModel({
    required this.elbowAngle,
    required this.shoulderAngle,
  });

  /// 肘关节角度（肩 - 肘 - 腕）。
  final double? elbowAngle;

  /// 肩关节角度（髋 - 肩 - 肘），用于检测身体晃动。
  final double? shoulderAngle;

  /// 主判据（肘角）可信时为 true。
  bool get isFullyValid => elbowAngle != null && shoulderAngle != null;
}

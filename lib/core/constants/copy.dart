/// 所有用户可见文案的唯一数据源。
///
/// 禁止在 widget 内部直接硬编码中文字符串，统一从此处引用。
abstract final class AppCopy {
  // ── 摄像头状态 ───────────────────────────────────────────
  static const String standInFront = '请站在摄像头前';
  static const String poseDetected = '检测到姿态 ✓';

  // ── 深蹲反馈（界面文字 + TTS 播报） ─────────────────────
  static const String feedbackGood = '动作标准！';
  static const String feedbackNotDeepEnough = '继续蹲低，膝盖弯曲超过 90°';
  static const String feedbackKneeOverToe = '膝盖不要超过脚尖，重心向后';
  static const String feedbackBackTooForward = '收紧核心，躯干不要过度前倾';

  /// 计次播报文案，例如：第 3 次
  static String repAnnouncement(int n) => '第 $n 次';

  // ── 弯举反馈（界面文字 + TTS 播报） ─────────────────────
  static const String feedbackCurlGood = '动作标准！';
  static const String feedbackBodySwing = '大臂保持固定，不要借力晃动';
  static const String feedbackIncompleteExtension = '手臂完全伸直再弯曲';
  static const String feedbackIncompleteCurl = '再弯高一点，充分收缩';

  // ── 反馈面板标签 ─────────────────────────────────────────
  static const String labelKnee = '膝';
  static const String labelHip = '髋';
  static const String labelAnkle = '踝';
  static const String labelElbow = '肘';
  static const String labelShoulder = '肩';
  static const String labelReps = '计次';

  // ── 运动选择页 ─────────────────────────────────────────
  static const String selectExerciseTitle = '选择训练动作';
  static const String exerciseSquat = '深蹲';
  static const String exerciseSquatDesc = '膝关节 · 髋关节 · 踝关节';
  static const String exerciseBicepCurl = '哑铃弯举';
  static const String exerciseBicepCurlDesc = '肘关节';
}

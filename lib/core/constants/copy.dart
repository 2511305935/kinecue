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

  // ── 训练配置 ───────────────────────────────────────────
  static const String configReps = '每组次数';
  static const String configSets = '组数';
  static const String configRest = '休息(秒)';
  static const String startTraining = '开始训练';

  // ── 休息界面 ─────────────────────────────────────────
  static String setComplete(int n) => '第 $n 组完成！';
  static String setProgress(int done, int target) => '$done / $target 次';
  static const String restTime = '休息时间';
  static const String aiCoachTitle = 'AI 教练建议';
  static const String aiCoachLoading = '正在生成建议...';
  static const String aiCoachFallback = '休息一下，保持呼吸均匀。准备好了就开始下一组！';
  static const String nextSet = '开始下一组';
  static const String endWorkout = '结束训练';
  static const String workoutComplete = '训练完成！';
  static String workoutSummary(int sets, int totalReps) =>
      '共完成 $sets 组，$totalReps 次';

  // ── 训练记录 ───────────────────────────────────────────
  static const String historyTitle = '训练记录';
  static const String historyEmpty = '暂无训练记录';
  static String historyItemSummary(int sets, int reps, int seconds) {
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    return '$sets组 · $reps次 · $min分$sec秒';
  }

  static const Map<String, String> exerciseNames = {
    'squat': '深蹲',
    'bicepCurl': '哑铃弯举',
  };

  // ── 训练详情页 ─────────────────────────────────────────
  static const String detailTitle = '训练详情';
  static String detailSetLabel(int n) => '第 $n 组';
  static const String detailReps = '次数';
  static const String detailDuration = '用时';
  static const String detailAvgAngle = '平均关键角度';
  static const String detailErrors = '动作问题统计';
  static const String detailNoErrors = '本组动作标准 ✓';
  static const String detailNotFound = '训练记录未找到';
  static const String detailNoSets = '无详细组数据';
  static const String historyEmptyHint = '完成一次训练后记录将在此显示';

  static const Map<String, String> errorDisplayNames = {
    'notDeepEnough': '未蹲到位',
    'kneeOverToe': '膝盖超过脚尖',
    'backTooForward': '躯干前倾过度',
    'bodySwing': '身体晃动借力',
    'incompleteExtension': '未完全伸展',
    'incompleteCurl': '未完全弯曲',
  };

  static String formatDuration(int seconds) {
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    return '$min分$sec秒';
  }

  // ── 摄像头权限 ─────────────────────────────────────────
  static const String cameraPermissionDenied =
      '无法访问摄像头\n请在系统设置中允许 KineCue 使用摄像头';
  static const String goBack = '返回';
}

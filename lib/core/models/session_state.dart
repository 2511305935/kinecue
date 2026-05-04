/// 训练阶段。
enum SessionPhase {
  /// 正在训练（计次中）。
  exercising,

  /// 组间休息（倒计时 + AI 建议）。
  resting,

  /// 全部组数完成。
  completed,
}

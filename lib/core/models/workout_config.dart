/// 单次训练的配置参数。
class WorkoutConfig {
  const WorkoutConfig({
    required this.targetReps,
    required this.totalSets,
    required this.restSeconds,
  });

  /// 每组目标次数。
  final int targetReps;

  /// 总组数。
  final int totalSets;

  /// 组间休息秒数。
  final int restSeconds;

  static const defaultConfig = WorkoutConfig(
    targetReps: 12,
    totalSets: 3,
    restSeconds: 60,
  );
}

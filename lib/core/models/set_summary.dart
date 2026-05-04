/// 单组训练完成后的统计数据，用于传给 AI 教练生成建议。
class SetSummary {
  const SetSummary({
    required this.exerciseName,
    required this.setNumber,
    required this.totalSets,
    required this.repsCompleted,
    required this.targetReps,
    required this.durationSeconds,
    required this.errorCounts,
    this.avgKeyAngle,
  });

  /// 运动名称（如 "squat"、"bicep_curl"）。
  final String exerciseName;

  /// 当前组号（1-based）。
  final int setNumber;

  /// 总组数。
  final int totalSets;

  /// 实际完成次数。
  final int repsCompleted;

  /// 目标次数。
  final int targetReps;

  /// 该组用时（秒）。
  final int durationSeconds;

  /// 各错误类型出现次数。键为错误枚举名称。
  final Map<String, int> errorCounts;

  /// 关键相位的平均角度（深蹲取底部膝角，弯举取顶峰肘角）。
  final double? avgKeyAngle;

  /// 转为 JSON，用于 API 请求 body。
  Map<String, dynamic> toJson() => {
        'exercise': exerciseName,
        'set_number': setNumber,
        'total_sets': totalSets,
        'reps_completed': repsCompleted,
        'target_reps': targetReps,
        'set_duration_seconds': durationSeconds,
        'errors': errorCounts,
        if (avgKeyAngle != null)
          'avg_key_angle': double.parse(avgKeyAngle!.toStringAsFixed(1)),
      };
}

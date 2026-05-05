import 'dart:convert';

import 'package:kinecue/core/models/exercise_type.dart';
import 'package:kinecue/core/models/set_summary.dart';

/// 一次完整训练的持久化记录。
class WorkoutSession {
  const WorkoutSession({
    this.id,
    required this.exerciseType,
    required this.startedAt,
    required this.totalSets,
    required this.totalReps,
    required this.totalDurationSeconds,
    required this.errorCounts,
    required this.setSummaries,
  });

  final int? id;
  final ExerciseType exerciseType;
  final DateTime startedAt;
  final int totalSets;
  final int totalReps;
  final int totalDurationSeconds;
  final Map<String, int> errorCounts;
  final List<SetSummary> setSummaries;

  /// 序列化为数据库行。
  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'exercise_type': exerciseType.name,
        'started_at': startedAt.toIso8601String(),
        'total_sets': totalSets,
        'total_reps': totalReps,
        'total_duration_seconds': totalDurationSeconds,
        'error_counts': jsonEncode(errorCounts),
        'set_summaries': jsonEncode(
          setSummaries.map((s) => s.toJson()).toList(),
        ),
      };

  /// 从数据库行反序列化。
  factory WorkoutSession.fromMap(Map<String, dynamic> map) {
    final summariesJson = jsonDecode(map['set_summaries'] as String) as List;
    final errorsJson =
        jsonDecode(map['error_counts'] as String) as Map<String, dynamic>;

    return WorkoutSession(
      id: map['id'] as int?,
      exerciseType: ExerciseType.values.byName(map['exercise_type'] as String),
      startedAt: DateTime.parse(map['started_at'] as String),
      totalSets: map['total_sets'] as int,
      totalReps: map['total_reps'] as int,
      totalDurationSeconds: map['total_duration_seconds'] as int,
      errorCounts: Map<String, int>.from(
        errorsJson.map((k, v) => MapEntry(k, v as int)),
      ),
      setSummaries: summariesJson
          .map((e) => SetSummary.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  /// 从多个 SetSummary 聚合构建 WorkoutSession。
  factory WorkoutSession.fromSets({
    required ExerciseType exerciseType,
    required DateTime startedAt,
    required List<SetSummary> sets,
  }) {
    final totalReps =
        sets.fold<int>(0, (sum, s) => sum + s.repsCompleted);
    final totalDuration =
        sets.fold<int>(0, (sum, s) => sum + s.durationSeconds);

    final mergedErrors = <String, int>{};
    for (final s in sets) {
      for (final entry in s.errorCounts.entries) {
        mergedErrors[entry.key] = (mergedErrors[entry.key] ?? 0) + entry.value;
      }
    }

    return WorkoutSession(
      exerciseType: exerciseType,
      startedAt: startedAt,
      totalSets: sets.length,
      totalReps: totalReps,
      totalDurationSeconds: totalDuration,
      errorCounts: mergedErrors,
      setSummaries: sets,
    );
  }
}

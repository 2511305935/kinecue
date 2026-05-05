import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kinecue/core/models/exercise_type.dart';
import 'package:kinecue/core/models/set_summary.dart';
import 'package:kinecue/core/models/workout_session.dart';

void main() {
  const summary1 = SetSummary(
    exerciseName: 'squat',
    setNumber: 1,
    totalSets: 3,
    repsCompleted: 10,
    targetReps: 12,
    durationSeconds: 45,
    errorCounts: {'notDeepEnough': 2},
    avgKeyAngle: 88.5,
  );

  const summary2 = SetSummary(
    exerciseName: 'squat',
    setNumber: 2,
    totalSets: 3,
    repsCompleted: 12,
    targetReps: 12,
    durationSeconds: 50,
    errorCounts: {'backTooForward': 1},
    avgKeyAngle: 85.0,
  );

  final session = WorkoutSession(
    id: 1,
    exerciseType: ExerciseType.squat,
    startedAt: DateTime(2026, 5, 10, 14, 30),
    totalSets: 2,
    totalReps: 22,
    totalDurationSeconds: 95,
    errorCounts: {'notDeepEnough': 2, 'backTooForward': 1},
    setSummaries: [summary1, summary2],
  );

  group('WorkoutSession', () {
    test('toMap 序列化包含所有字段', () {
      final map = session.toMap();
      expect(map['id'], 1);
      expect(map['exercise_type'], 'squat');
      expect(map['started_at'], '2026-05-10T14:30:00.000');
      expect(map['total_sets'], 2);
      expect(map['total_reps'], 22);
      expect(map['total_duration_seconds'], 95);

      final errors = jsonDecode(map['error_counts'] as String);
      expect(errors['notDeepEnough'], 2);
      expect(errors['backTooForward'], 1);

      final summaries = jsonDecode(map['set_summaries'] as String) as List;
      expect(summaries.length, 2);
      expect(summaries[0]['reps_completed'], 10);
    });

    test('fromMap 反序列化还原所有字段', () {
      final map = session.toMap();
      final restored = WorkoutSession.fromMap(map);

      expect(restored.id, 1);
      expect(restored.exerciseType, ExerciseType.squat);
      expect(restored.startedAt, DateTime(2026, 5, 10, 14, 30));
      expect(restored.totalSets, 2);
      expect(restored.totalReps, 22);
      expect(restored.totalDurationSeconds, 95);
      expect(restored.errorCounts['notDeepEnough'], 2);
      expect(restored.setSummaries.length, 2);
      expect(restored.setSummaries[0].repsCompleted, 10);
      expect(restored.setSummaries[1].avgKeyAngle, 85.0);
    });

    test('fromSets 正确聚合多组数据', () {
      final aggregated = WorkoutSession.fromSets(
        exerciseType: ExerciseType.squat,
        startedAt: DateTime(2026, 5, 10),
        sets: [summary1, summary2],
      );

      expect(aggregated.totalSets, 2);
      expect(aggregated.totalReps, 22);
      expect(aggregated.totalDurationSeconds, 95);
      expect(aggregated.errorCounts['notDeepEnough'], 2);
      expect(aggregated.errorCounts['backTooForward'], 1);
    });

    test('toMap 不含 id 当 id 为 null', () {
      final noId = WorkoutSession(
        exerciseType: ExerciseType.bicepCurl,
        startedAt: DateTime(2026, 5, 10),
        totalSets: 1,
        totalReps: 10,
        totalDurationSeconds: 30,
        errorCounts: {},
        setSummaries: [],
      );

      expect(noId.toMap().containsKey('id'), isFalse);
    });
  });

  group('SetSummary.fromJson', () {
    test('fromJson 还原 toJson 结果', () {
      final json = summary1.toJson();
      final restored = SetSummary.fromJson(json);

      expect(restored.exerciseName, 'squat');
      expect(restored.setNumber, 1);
      expect(restored.repsCompleted, 10);
      expect(restored.errorCounts['notDeepEnough'], 2);
      expect(restored.avgKeyAngle, 88.5);
    });

    test('fromJson avgKeyAngle 为 null', () {
      const noAngle = SetSummary(
        exerciseName: 'bicep_curl',
        setNumber: 1,
        totalSets: 3,
        repsCompleted: 8,
        targetReps: 12,
        durationSeconds: 40,
        errorCounts: {},
      );

      final json = noAngle.toJson();
      final restored = SetSummary.fromJson(json);
      expect(restored.avgKeyAngle, isNull);
    });
  });
}

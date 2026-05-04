import 'package:flutter_test/flutter_test.dart';
import 'package:kinecue/core/models/set_summary.dart';

void main() {
  group('SetSummary', () {
    test('toJson 包含所有必要字段', () {
      const summary = SetSummary(
        exerciseName: 'squat',
        setNumber: 2,
        totalSets: 3,
        repsCompleted: 10,
        targetReps: 12,
        durationSeconds: 45,
        errorCounts: {'notDeepEnough': 3, 'backTooForward': 1},
        avgKeyAngle: 88.25,
      );

      final json = summary.toJson();

      expect(json['exercise'], 'squat');
      expect(json['set_number'], 2);
      expect(json['total_sets'], 3);
      expect(json['reps_completed'], 10);
      expect(json['target_reps'], 12);
      expect(json['set_duration_seconds'], 45);
      expect(json['errors'], {'notDeepEnough': 3, 'backTooForward': 1});
      expect(json['avg_key_angle'], 88.3); // rounded to 1 decimal
    });

    test('toJson avgKeyAngle 为 null 时不包含该字段', () {
      const summary = SetSummary(
        exerciseName: 'bicep_curl',
        setNumber: 1,
        totalSets: 3,
        repsCompleted: 12,
        targetReps: 12,
        durationSeconds: 30,
        errorCounts: {},
      );

      final json = summary.toJson();

      expect(json.containsKey('avg_key_angle'), false);
      expect(json['errors'], isEmpty);
    });

    test('toJson 空错误映射序列化正确', () {
      const summary = SetSummary(
        exerciseName: 'squat',
        setNumber: 1,
        totalSets: 1,
        repsCompleted: 5,
        targetReps: 5,
        durationSeconds: 20,
        errorCounts: {},
        avgKeyAngle: 90.0,
      );

      final json = summary.toJson();

      expect(json['errors'], isA<Map>());
      expect(json['errors'], isEmpty);
      expect(json['avg_key_angle'], 90.0);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:kinecue/core/models/exercise_type.dart';
import 'package:kinecue/core/models/set_summary.dart';
import 'package:kinecue/core/models/workout_session.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:kinecue/core/services/workout_db_service.dart';

void main() {
  // 使用 ffi 内存数据库进行测试
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('WorkoutDbService', () {
    late WorkoutDbService service;

    setUp(() async {
      service = WorkoutDbService.instance;
      await service.init();
    });

    test('insertSession 返回正整数 id', () async {
      final session = WorkoutSession.fromSets(
        exerciseType: ExerciseType.squat,
        startedAt: DateTime(2026, 5, 10, 14, 0),
        sets: [
          const SetSummary(
            exerciseName: 'squat',
            setNumber: 1,
            totalSets: 3,
            repsCompleted: 10,
            targetReps: 12,
            durationSeconds: 45,
            errorCounts: {'notDeepEnough': 2},
            avgKeyAngle: 88.0,
          ),
        ],
      );

      final id = await service.insertSession(session);
      expect(id, greaterThan(0));
    });

    test('getRecentSessions 返回按时间倒序排列', () async {
      final older = WorkoutSession.fromSets(
        exerciseType: ExerciseType.squat,
        startedAt: DateTime(2026, 5, 8),
        sets: [
          const SetSummary(
            exerciseName: 'squat',
            setNumber: 1,
            totalSets: 1,
            repsCompleted: 5,
            targetReps: 12,
            durationSeconds: 30,
            errorCounts: {},
          ),
        ],
      );
      final newer = WorkoutSession.fromSets(
        exerciseType: ExerciseType.bicepCurl,
        startedAt: DateTime(2026, 5, 11),
        sets: [
          const SetSummary(
            exerciseName: 'bicep_curl',
            setNumber: 1,
            totalSets: 1,
            repsCompleted: 8,
            targetReps: 12,
            durationSeconds: 35,
            errorCounts: {},
          ),
        ],
      );

      await service.insertSession(older);
      await service.insertSession(newer);

      final sessions = await service.getRecentSessions(limit: 10);
      expect(sessions.length, greaterThanOrEqualTo(2));
      // 最新的在前
      expect(sessions.first.exerciseType, ExerciseType.bicepCurl);
    });

    test('getSession 根据 id 查询单条记录', () async {
      final session = WorkoutSession.fromSets(
        exerciseType: ExerciseType.bicepCurl,
        startedAt: DateTime(2026, 5, 12),
        sets: [
          const SetSummary(
            exerciseName: 'bicep_curl',
            setNumber: 1,
            totalSets: 2,
            repsCompleted: 12,
            targetReps: 12,
            durationSeconds: 50,
            errorCounts: {'bodySwing': 3},
            avgKeyAngle: 35.0,
          ),
        ],
      );

      final id = await service.insertSession(session);
      final fetched = await service.getSession(id);

      expect(fetched, isNotNull);
      expect(fetched!.exerciseType, ExerciseType.bicepCurl);
      expect(fetched.totalReps, 12);
      expect(fetched.setSummaries.first.errorCounts['bodySwing'], 3);
    });

    test('getSession 不存在的 id 返回 null', () async {
      final fetched = await service.getSession(99999);
      expect(fetched, isNull);
    });
  });
}

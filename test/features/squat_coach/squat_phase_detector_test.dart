import 'package:flutter_test/flutter_test.dart';
import 'package:kinecue/features/squat_coach/domain/squat_phase_detector.dart';

void main() {
  late SquatPhaseDetector detector;

  setUp(() => detector = SquatPhaseDetector());

  group('SquatPhaseDetector 阶段转换', () {
    test('初始状态为 standing', () {
      expect(detector.phase, SquatPhase.standing);
    });

    test('从 standing 下蹲进入 descending（膝角 = 130°）', () {
      detector.update(170.0);
      final (phase, completed) = detector.update(130.0);
      expect(phase, SquatPhase.descending);
      expect(completed, isFalse);
    });

    test('膝角 ≤ 95° 进入 bottom', () {
      detector.update(170.0);
      detector.update(130.0);
      final (phase, completed) = detector.update(90.0);
      expect(phase, SquatPhase.bottom);
      expect(completed, isFalse);
    });

    test('从 bottom 起身进入 ascending（膝角 = 130°）', () {
      detector.update(170.0);
      detector.update(130.0);
      detector.update(90.0);
      final (phase, completed) = detector.update(130.0);
      expect(phase, SquatPhase.ascending);
      expect(completed, isFalse);
    });

    test('完成一次循环：ascending → standing → cycleCompleted = true', () {
      detector.update(170.0); // standing
      detector.update(130.0); // descending
      detector.update(90.0);  // bottom
      detector.update(130.0); // ascending
      final (phase, completed) = detector.update(160.0); // standing
      expect(phase, SquatPhase.standing);
      expect(completed, isTrue);
    });

    test('连续两次循环，cycleCompleted 各触发一次', () {
      int cycles = 0;

      void squat() {
        detector.update(170.0);
        detector.update(130.0);
        detector.update(90.0);
        detector.update(130.0);
        final (_, completed) = detector.update(160.0);
        if (completed) cycles++;
      }

      squat();
      squat();
      expect(cycles, 2);
    });
  });

  group('SquatPhaseDetector 边界条件', () {
    test('膝角 = 150°（standing 临界）→ descending', () {
      detector.update(170.0);
      final (phase, _) = detector.update(150.0);
      expect(phase, SquatPhase.descending);
    });

    test('膝角 = 151° → standing，不触发 cycleCompleted', () {
      detector.update(170.0);
      final (phase, completed) = detector.update(151.0);
      expect(phase, SquatPhase.standing);
      expect(completed, isFalse);
    });

    test('膝角 = 95°（bottom 临界）→ bottom', () {
      detector.update(170.0);
      detector.update(130.0);
      final (phase, _) = detector.update(95.0);
      expect(phase, SquatPhase.bottom);
    });

    test('膝角 = 96°（bottom 上方）从 bottom 来 → ascending', () {
      detector.update(170.0);
      detector.update(130.0);
      detector.update(90.0); // bottom
      final (phase, _) = detector.update(96.0);
      expect(phase, SquatPhase.ascending);
    });

    test('未经过 bottom 直接从 descending 回 standing，不触发 cycleCompleted', () {
      detector.update(170.0); // standing
      detector.update(130.0); // descending
      // 直接回站立（未到底部）
      final (phase, completed) = detector.update(160.0); // standing
      expect(phase, SquatPhase.standing);
      expect(completed, isFalse);
    });
  });
}

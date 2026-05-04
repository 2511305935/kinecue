import 'package:flutter_test/flutter_test.dart';
import 'package:kinecue/features/bicep_curl_coach/domain/curl_phase_detector.dart';

void main() {
  late CurlPhaseDetector detector;

  setUp(() => detector = CurlPhaseDetector());

  group('CurlPhaseDetector 阶段转换', () {
    test('初始状态为 extended', () {
      expect(detector.phase, CurlPhase.extended);
    });

    test('从 extended 弯曲进入 curling（肘角 = 120°）', () {
      detector.update(170.0);
      final (phase, completed) = detector.update(120.0);
      expect(phase, CurlPhase.curling);
      expect(completed, isFalse);
    });

    test('肘角 ≤ 40° 进入 peak', () {
      detector.update(170.0);
      detector.update(120.0);
      final (phase, completed) = detector.update(35.0);
      expect(phase, CurlPhase.peak);
      expect(completed, isFalse);
    });

    test('从 peak 放下进入 lowering（肘角 = 90°）', () {
      detector.update(170.0);
      detector.update(120.0);
      detector.update(35.0);
      final (phase, completed) = detector.update(90.0);
      expect(phase, CurlPhase.lowering);
      expect(completed, isFalse);
    });

    test('完成一次循环：lowering → extended → cycleCompleted = true', () {
      detector.update(170.0); // extended
      detector.update(120.0); // curling
      detector.update(35.0);  // peak
      detector.update(90.0);  // lowering
      final (phase, completed) = detector.update(165.0); // extended
      expect(phase, CurlPhase.extended);
      expect(completed, isTrue);
    });

    test('连续两次循环，cycleCompleted 各触发一次', () {
      int cycles = 0;

      void curl() {
        detector.update(170.0);
        detector.update(120.0);
        detector.update(35.0);
        detector.update(90.0);
        final (_, completed) = detector.update(165.0);
        if (completed) cycles++;
      }

      curl();
      curl();
      expect(cycles, 2);
    });
  });

  group('CurlPhaseDetector 边界条件', () {
    test('肘角 = 160°（extended 临界）→ curling', () {
      detector.update(170.0);
      final (phase, _) = detector.update(160.0);
      expect(phase, CurlPhase.curling);
    });

    test('肘角 = 161° → extended，不触发 cycleCompleted', () {
      detector.update(170.0);
      final (phase, completed) = detector.update(161.0);
      expect(phase, CurlPhase.extended);
      expect(completed, isFalse);
    });

    test('肘角 = 40°（peak 临界）→ peak', () {
      detector.update(170.0);
      detector.update(120.0);
      final (phase, _) = detector.update(40.0);
      expect(phase, CurlPhase.peak);
    });

    test('肘角 = 41°（peak 上方）从 peak 来 → lowering', () {
      detector.update(170.0);
      detector.update(120.0);
      detector.update(35.0); // peak
      final (phase, _) = detector.update(41.0);
      expect(phase, CurlPhase.lowering);
    });

    test('未经过 peak 直接从 curling 回 extended，不触发 cycleCompleted', () {
      detector.update(170.0); // extended
      detector.update(120.0); // curling
      // 直接回伸直（未到顶峰）
      final (phase, completed) = detector.update(165.0); // extended
      expect(phase, CurlPhase.extended);
      expect(completed, isFalse);
    });

    test('reset() 恢复 extended', () {
      detector.update(120.0); // curling
      detector.reset();
      expect(detector.phase, CurlPhase.extended);
    });
  });
}

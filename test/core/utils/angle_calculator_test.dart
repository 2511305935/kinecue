import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:kinecue/core/utils/angle_calculator.dart';

/// 构造仅含 x/y 坐标的 PoseLandmark 测试桩。
PoseLandmark _lm(double x, double y) => PoseLandmark(
      type: PoseLandmarkType.nose,
      x: x,
      y: y,
      z: 0,
      likelihood: 1.0,
    );

void main() {
  group('AngleCalculator.calculate', () {
    test('直角：垂直两向量应返回 90°', () {
      // B 在原点，A 在正上方，C 在正右方 → 夹角 90°
      final a = _lm(0, -1);
      final b = _lm(0, 0);
      final c = _lm(1, 0);

      expect(AngleCalculator.calculate(a, b, c), closeTo(90.0, 0.001));
    });

    test('平角：共线反向应返回 180°', () {
      // B 在原点，A 在左，C 在右 → 夹角 180°
      final a = _lm(-1, 0);
      final b = _lm(0, 0);
      final c = _lm(1, 0);

      expect(AngleCalculator.calculate(a, b, c), closeTo(180.0, 0.001));
    });

    test('深蹲底部：构造 80° 夹角，误差 < 1°', () {
      // BA = (0, -1)，BC = (sin80°, -cos80°) → 夹角精确 80°
      final rad = 80.0 * math.pi / 180.0;
      final a = _lm(0, -1);
      final b = _lm(0, 0);
      final c = _lm(math.sin(rad), -math.cos(rad));

      expect(AngleCalculator.calculate(a, b, c), closeTo(80.0, 1.0));
    });

    test('两点重合：BA 向量为零应返回 0 且不抛异常', () {
      // A 与 B 重合，magBA = 0
      final a = _lm(0, 0);
      final b = _lm(0, 0);
      final c = _lm(1, 0);

      expect(AngleCalculator.calculate(a, b, c), equals(0.0));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:kinecue/features/bicep_curl_coach/domain/curl_angle_model.dart';
import 'package:kinecue/features/bicep_curl_coach/domain/curl_form_checker.dart';

void main() {
  group('CurlFormChecker.check', () {
    test('肘角 30°、肩角 15° → good（正常弯举顶峰）', () {
      final model = CurlAngleModel(elbowAngle: 30.0, shoulderAngle: 15.0);
      expect(CurlFormChecker.check(model), CurlError.good);
    });

    test('肘角 170°、肩角 15° → good（正常伸展）', () {
      final model = CurlAngleModel(elbowAngle: 170.0, shoulderAngle: 15.0);
      expect(CurlFormChecker.check(model), CurlError.good);
    });

    test('肩角 3° → bodySwing（大臂过度前倾）', () {
      final model = CurlAngleModel(elbowAngle: 90.0, shoulderAngle: 3.0);
      expect(CurlFormChecker.check(model), CurlError.bodySwing);
    });

    test('肩角 40° → bodySwing（大臂后摆借力）', () {
      final model = CurlAngleModel(elbowAngle: 90.0, shoulderAngle: 40.0);
      expect(CurlFormChecker.check(model), CurlError.bodySwing);
    });

    test('肘角 null、肩角正常 → good（肘角置信度不足）', () {
      final model = CurlAngleModel(elbowAngle: null, shoulderAngle: 15.0);
      expect(CurlFormChecker.check(model), CurlError.good);
    });

    test('肩角 5°（临界值）→ good（恰好不触发）', () {
      final model = CurlAngleModel(elbowAngle: 90.0, shoulderAngle: 5.0);
      expect(CurlFormChecker.check(model), CurlError.good);
    });

    test('肩角 35°（临界值）→ good（恰好不触发）', () {
      final model = CurlAngleModel(elbowAngle: 90.0, shoulderAngle: 35.0);
      expect(CurlFormChecker.check(model), CurlError.good);
    });
  });
}

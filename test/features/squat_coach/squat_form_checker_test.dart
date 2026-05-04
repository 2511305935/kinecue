import 'package:flutter_test/flutter_test.dart';
import 'package:kinecue/features/squat_coach/domain/squat_angle_model.dart';
import 'package:kinecue/features/squat_coach/domain/squat_form_checker.dart';

void main() {
  group('SquatFormChecker.check', () {
    test('膝角 = 120° → notDeepEnough', () {
      final model = SquatAngleModel(
        kneeAngle: 120.0,
        hipAngle: 60.0,
        ankleAngle: 85.0,
      );
      expect(SquatFormChecker.check(model), SquatError.notDeepEnough);
    });

    test('膝角 = 90°、髋角 = 60°、踝角 = 85° → good', () {
      final model = SquatAngleModel(
        kneeAngle: 90.0,
        hipAngle: 60.0,
        ankleAngle: 85.0,
      );
      expect(SquatFormChecker.check(model), SquatError.good);
    });

    test('髋角 = 30° → backTooForward（优先级高于 notDeepEnough）', () {
      final model = SquatAngleModel(
        kneeAngle: 120.0,
        hipAngle: 30.0,
        ankleAngle: 85.0,
      );
      expect(SquatFormChecker.check(model), SquatError.backTooForward);
    });

    test('膝角 = 95°（临界值）→ good（恰好到位）', () {
      final model = SquatAngleModel(
        kneeAngle: 95.0,
        hipAngle: 60.0,
        ankleAngle: 85.0,
      );
      expect(SquatFormChecker.check(model), SquatError.good);
    });
  });
}

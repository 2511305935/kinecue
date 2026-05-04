import 'package:flutter/material.dart';

import 'package:kinecue/core/constants/copy.dart';
import 'package:kinecue/core/constants/pose_thresholds.dart';
import 'package:kinecue/features/squat_coach/domain/squat_angle_model.dart';
import 'package:kinecue/features/squat_coach/domain/squat_form_checker.dart';

/// 深蹲实时反馈面板：侧边气泡布局。
///
/// 角度数值 + 计次置于右侧气泡栏，仅在有错误时显示错误气泡，
/// 所有气泡背景极浅半透明，不遮挡姿态视野。
class SquatFeedbackWidget extends StatelessWidget {
  const SquatFeedbackWidget({
    super.key,
    required this.angles,
    required this.error,
    required this.repCount,
  });

  final SquatAngleModel angles;
  final SquatError error;
  final int repCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 计次
        _Bubble(
          child: _RepCounter(repCount: repCount),
        ),
        const SizedBox(height: 6),
        // 三关节角度
        _Bubble(
          child: _AngleRow(
            label: AppCopy.labelKnee,
            angle: angles.kneeAngle,
            min: PoseThresholds.kKneeMin,
            max: PoseThresholds.kKneeMax,
          ),
        ),
        const SizedBox(height: 4),
        _Bubble(
          child: _AngleRow(
            label: AppCopy.labelHip,
            angle: angles.hipAngle,
            min: PoseThresholds.kHipMin,
            max: PoseThresholds.kHipMax,
          ),
        ),
        const SizedBox(height: 4),
        _Bubble(
          child: _AngleRow(
            label: AppCopy.labelAnkle,
            angle: angles.ankleAngle,
            min: PoseThresholds.kAnkleMin,
            max: PoseThresholds.kAnkleMax,
          ),
        ),
        // 错误提示气泡：仅在有错时显示
        if (error != SquatError.good) ...[
          const SizedBox(height: 8),
          _Bubble(
            alpha: 0.55,
            child: _ErrorLabel(error: error),
          ),
        ],
      ],
    );
  }
}

// ── 气泡容器 ─────────────────────────────────────────────────

class _Bubble extends StatelessWidget {
  const _Bubble({this.alpha = 0.38, required this.child});

  final double alpha;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: alpha),
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}

// ── 单行角度 ─────────────────────────────────────────────────

class _AngleRow extends StatelessWidget {
  const _AngleRow({
    required this.label,
    required this.angle,
    required this.min,
    required this.max,
  });

  final String label;
  final double? angle;
  final double min;
  final double max;

  @override
  Widget build(BuildContext context) {
    final inRange = angle != null && angle! >= min && angle! <= max;
    final color = angle == null
        ? Colors.white38
        : inRange
            ? Colors.greenAccent
            : Colors.amberAccent;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
        const SizedBox(width: 4),
        Text(
          angle != null ? '${angle!.toStringAsFixed(0)}°' : '--',
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// ── 错误标签 ─────────────────────────────────────────────────

class _ErrorLabel extends StatelessWidget {
  const _ErrorLabel({required this.error});

  final SquatError error;

  @override
  Widget build(BuildContext context) {
    final (text, color) = switch (error) {
      SquatError.good => (AppCopy.feedbackGood, Colors.greenAccent),
      SquatError.notDeepEnough =>
        (AppCopy.feedbackNotDeepEnough, Colors.amberAccent),
      SquatError.kneeOverToe =>
        (AppCopy.feedbackKneeOverToe, Colors.orangeAccent),
      SquatError.backTooForward =>
        (AppCopy.feedbackBackTooForward, Colors.redAccent),
    };
    return Text(
      text,
      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
    );
  }
}

// ── 计次 ─────────────────────────────────────────────────────

class _RepCounter extends StatelessWidget {
  const _RepCounter({required this.repCount});

  final int repCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${AppCopy.labelReps} ',
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, animation) => ScaleTransition(
            scale: Tween<double>(begin: 1.5, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOut),
            ),
            child: child,
          ),
          child: Text(
            '$repCount',
            key: ValueKey(repCount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

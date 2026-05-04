import 'package:flutter/material.dart';

import 'package:kinecue/core/constants/copy.dart';
import 'package:kinecue/core/constants/pose_thresholds.dart';
import 'package:kinecue/features/bicep_curl_coach/domain/curl_angle_model.dart';
import 'package:kinecue/features/bicep_curl_coach/domain/curl_form_checker.dart';

/// 弯举实时反馈面板：侧边气泡布局。
class CurlFeedbackWidget extends StatelessWidget {
  const CurlFeedbackWidget({
    super.key,
    required this.angles,
    required this.error,
    required this.repCount,
  });

  final CurlAngleModel angles;
  final CurlError error;
  final int repCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _Bubble(child: _RepCounter(repCount: repCount)),
        const SizedBox(height: 6),
        // 肘角：在 peak~extended 范围内为达标
        _Bubble(
          child: _AngleRow(
            label: AppCopy.labelElbow,
            angle: angles.elbowAngle,
            min: PoseThresholds.kCurlElbowPeak,
            max: PoseThresholds.kCurlElbowExtended,
          ),
        ),
        const SizedBox(height: 4),
        // 肩角：在合理范围内说明大臂稳定
        _Bubble(
          child: _AngleRow(
            label: AppCopy.labelShoulder,
            angle: angles.shoulderAngle,
            min: PoseThresholds.kCurlShoulderMin,
            max: PoseThresholds.kCurlShoulderMax,
          ),
        ),
        if (error != CurlError.good) ...[
          const SizedBox(height: 8),
          _Bubble(alpha: 0.55, child: _ErrorLabel(error: error)),
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

  final CurlError error;

  @override
  Widget build(BuildContext context) {
    final (text, color) = switch (error) {
      CurlError.good => (AppCopy.feedbackCurlGood, Colors.greenAccent),
      CurlError.bodySwing =>
        (AppCopy.feedbackBodySwing, Colors.redAccent),
      CurlError.incompleteExtension =>
        (AppCopy.feedbackIncompleteExtension, Colors.amberAccent),
      CurlError.incompleteCurl =>
        (AppCopy.feedbackIncompleteCurl, Colors.amberAccent),
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

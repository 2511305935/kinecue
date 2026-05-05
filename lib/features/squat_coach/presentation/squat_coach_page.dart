import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import 'package:kinecue/core/constants/copy.dart';
import 'package:kinecue/core/constants/pose_thresholds.dart';
import 'package:kinecue/core/models/exercise_type.dart';
import 'package:kinecue/core/models/set_summary.dart';
import 'package:kinecue/core/models/workout_config.dart';
import 'package:kinecue/core/utils/angle_calculator.dart';
import 'package:kinecue/features/squat_coach/domain/squat_angle_model.dart';
import 'package:kinecue/features/squat_coach/domain/squat_form_checker.dart';
import 'package:kinecue/features/squat_coach/domain/squat_phase_detector.dart';
import 'package:kinecue/features/squat_coach/presentation/squat_feedback_widget.dart';
import 'package:kinecue/shared/mixins/camera_coach_mixin.dart';
import 'package:kinecue/shared/widgets/pose_painter.dart';

class SquatCoachPage extends StatefulWidget {
  const SquatCoachPage({super.key, required this.cameras, required this.config});

  final List<CameraDescription> cameras;
  final WorkoutConfig config;

  @override
  State<SquatCoachPage> createState() => _SquatCoachPageState();
}

class _SquatCoachPageState extends State<SquatCoachPage>
    with CameraCoachMixin<SquatCoachPage> {
  // ── 深蹲监控区配置 ─────────────────────────────────────
  static const _kSquatMonitoredConnections = [
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
    [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
    [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee],
    [PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],
    [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee],
    [PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle],
  ];

  static const _kSquatMonitoredLandmarks = {
    PoseLandmarkType.leftShoulder,
    PoseLandmarkType.rightShoulder,
    PoseLandmarkType.leftHip,
    PoseLandmarkType.rightHip,
    PoseLandmarkType.leftKnee,
    PoseLandmarkType.rightKnee,
    PoseLandmarkType.leftAnkle,
    PoseLandmarkType.rightAnkle,
  };

  // ── 深蹲状态 ─────────────────────────────────────────────
  SquatAngleModel _angles = const SquatAngleModel(
    kneeAngle: null,
    hipAngle: null,
    ankleAngle: null,
  );
  SquatError _error = SquatError.good;
  final SquatPhaseDetector _phaseDetector = SquatPhaseDetector();
  int _repCount = 0;
  int _bottomGoodFrames = 0;
  bool _bottomQualityMet = false;
  static const int _kBottomQualityMinFrames = 3;
  int _descendingBadFrames = 0;
  static const int _kDescendingBadMinFrames = 3;
  static const int _kDescendingBadVoiceMinFrames = 15;

  // ── TTS 状态 ──────────────────────────────────────────────
  SquatError _lastSpokenError = SquatError.good;
  int _lastSpokenRep = 0;

  // ── 每组数据收集 ──────────────────────────────────────────
  final Map<String, int> _errorCounts = {};
  final List<double> _bottomAngles = [];

  // ── Mixin: cameras / config ───────────────────────────────

  @override
  List<CameraDescription> get cameras => widget.cameras;

  @override
  WorkoutConfig get workoutConfig => widget.config;

  @override
  ExerciseType get exerciseType => ExerciseType.squat;

  // ── Lifecycle ─────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    initCoach();
  }

  @override
  void dispose() {
    disposeCoach();
    super.dispose();
  }

  // ── Mixin: onPoseDetected ─────────────────────────────────

  @override
  void onPoseDetected(Pose? detectedPose) {
    final angles =
        detectedPose != null ? _computeAngles(detectedPose) : _angles;
    final newError = SquatFormChecker.check(angles);

    int newRepCount = _repCount;
    SquatPhase currentPhase = _phaseDetector.phase;

    if (angles.isFullyValid) {
      final prevPhase = _phaseDetector.phase;
      final (phase, cycleCompleted) =
          _phaseDetector.update(angles.kneeAngle!);
      currentPhase = phase;

      if (prevPhase == SquatPhase.standing &&
          phase == SquatPhase.descending) {
        _bottomQualityMet = false;
        _bottomGoodFrames = 0;
      }

      // 收集每组底部角度
      if (phase == SquatPhase.bottom && angles.kneeAngle != null) {
        _bottomAngles.add(angles.kneeAngle!);
      }

      if (phase == SquatPhase.descending &&
          newError == SquatError.notDeepEnough) {
        if (_descendingBadFrames < _kDescendingBadMinFrames) {
          _descendingBadFrames++;
        }
      } else {
        _descendingBadFrames = 0;
      }

      if (phase == SquatPhase.bottom && newError == SquatError.good) {
        _bottomGoodFrames++;
        if (_bottomGoodFrames >= _kBottomQualityMinFrames) {
          _bottomQualityMet = true;
        }
      }

      if (cycleCompleted) {
        if (_bottomQualityMet) {
          newRepCount = _repCount + 1;
          // 统计本次动作的错误
          if (newError != SquatError.good) {
            final key = newError.name;
            _errorCounts[key] = (_errorCounts[key] ?? 0) + 1;
          }
        }
        _bottomQualityMet = false;
        _bottomGoodFrames = 0;
      }
    }

    final displayError = _effectiveError(newError, currentPhase);
    final voiceError = _effectiveVoiceError(newError, currentPhase);

    setState(() {
      poses = detectedPose != null ? [detectedPose] : [];
      _angles = angles;
      _error = displayError;
      _repCount = newRepCount;
    });

    _triggerTts(voiceError, newRepCount, currentPhase);
    notifyRepCompleted(newRepCount);
  }

  // ── Error filtering ───────────────────────────────────────

  SquatError _effectiveError(SquatError raw, SquatPhase phase) {
    if (phase == SquatPhase.standing) return SquatError.good;
    if (raw == SquatError.notDeepEnough) {
      if (phase == SquatPhase.descending) {
        return _descendingBadFrames >= _kDescendingBadMinFrames
            ? SquatError.notDeepEnough
            : SquatError.good;
      }
      return (phase == SquatPhase.ascending && !_bottomQualityMet)
          ? SquatError.notDeepEnough
          : SquatError.good;
    }
    return raw;
  }

  SquatError _effectiveVoiceError(SquatError raw, SquatPhase phase) {
    if (phase == SquatPhase.standing) return SquatError.good;
    if (raw == SquatError.notDeepEnough) {
      if (phase == SquatPhase.descending) {
        return _descendingBadFrames >= _kDescendingBadVoiceMinFrames
            ? SquatError.notDeepEnough
            : SquatError.good;
      }
      return (phase == SquatPhase.ascending && !_bottomQualityMet)
          ? SquatError.notDeepEnough
          : SquatError.good;
    }
    return raw;
  }

  // ── TTS ────────────────────────────────────────────────────

  void _triggerTts(SquatError newError, int newRepCount, SquatPhase phase) {
    if (newRepCount > _lastSpokenRep) {
      _lastSpokenRep = newRepCount;
      _lastSpokenError = newError;
      unawaited(
        tts.stop().then((_) => tts.speak(AppCopy.repAnnouncement(newRepCount))),
      );
      return;
    }

    if (phase == SquatPhase.standing) {
      _lastSpokenError = newError;
      return;
    }

    if (newError == SquatError.good && _lastSpokenError != SquatError.good) {
      unawaited(tts.stop());
      _lastSpokenError = newError;
      return;
    }

    if (newError != SquatError.good && newError != _lastSpokenError) {
      _lastSpokenError = newError;
      unawaited(tts.speak(_textForError(newError)));
    } else {
      _lastSpokenError = newError;
    }
  }

  String _textForError(SquatError error) => switch (error) {
        SquatError.good => AppCopy.feedbackGood,
        SquatError.notDeepEnough => AppCopy.feedbackNotDeepEnough,
        SquatError.kneeOverToe => AppCopy.feedbackKneeOverToe,
        SquatError.backTooForward => AppCopy.feedbackBackTooForward,
      };

  // ── Helpers ────────────────────────────────────────────────

  Set<PoseLandmarkType> _highlightedJoints(SquatError error) =>
      switch (error) {
        SquatError.notDeepEnough => {
            PoseLandmarkType.leftHip,
            PoseLandmarkType.leftKnee,
            PoseLandmarkType.leftAnkle,
            PoseLandmarkType.rightHip,
            PoseLandmarkType.rightKnee,
            PoseLandmarkType.rightAnkle,
          },
        SquatError.backTooForward => {
            PoseLandmarkType.leftShoulder,
            PoseLandmarkType.rightShoulder,
            PoseLandmarkType.leftHip,
            PoseLandmarkType.rightHip,
          },
        _ => const {},
      };

  SquatAngleModel _computeAngles(Pose pose) {
    PoseLandmark? lm(PoseLandmarkType t) {
      final l = pose.landmarks[t];
      return (l != null && l.likelihood >= PoseThresholds.kLandmarkConfidence)
          ? l
          : null;
    }

    final shoulder = lm(PoseLandmarkType.leftShoulder);
    final hip = lm(PoseLandmarkType.leftHip);
    final knee = lm(PoseLandmarkType.leftKnee);
    final ankle = lm(PoseLandmarkType.leftAnkle);
    final foot = lm(PoseLandmarkType.leftFootIndex);

    return SquatAngleModel(
      kneeAngle: (hip != null && knee != null && ankle != null)
          ? AngleCalculator.calculate(hip, knee, ankle)
          : null,
      hipAngle: (shoulder != null && hip != null && knee != null)
          ? AngleCalculator.calculate(shoulder, hip, knee)
          : null,
      ankleAngle: (knee != null && ankle != null && foot != null)
          ? AngleCalculator.calculate(knee, ankle, foot)
          : null,
    );
  }

  // ── Mixin: session management ──────────────────────────────

  @override
  SetSummary buildSetSummary(int setNumber) {
    final duration = setStartTime != null
        ? DateTime.now().difference(setStartTime!).inSeconds
        : 0;
    final avgAngle = _bottomAngles.isNotEmpty
        ? _bottomAngles.reduce((a, b) => a + b) / _bottomAngles.length
        : null;

    return SetSummary(
      exerciseName: 'squat',
      setNumber: setNumber,
      totalSets: workoutConfig.totalSets,
      repsCompleted: _repCount,
      targetReps: workoutConfig.targetReps,
      durationSeconds: duration,
      errorCounts: Map.of(_errorCounts),
      avgKeyAngle: avgAngle,
    );
  }

  @override
  void resetForNextSet() {
    _angles = const SquatAngleModel(
        kneeAngle: null, hipAngle: null, ankleAngle: null);
    _error = SquatError.good;
    _phaseDetector.reset();
    _repCount = 0;
    _bottomGoodFrames = 0;
    _bottomQualityMet = false;
    _descendingBadFrames = 0;
    _lastSpokenError = SquatError.good;
    _lastSpokenRep = 0;
    _errorCounts.clear();
    _bottomAngles.clear();
    poses = [];
  }

  // ── Mixin: buildExerciseOverlays ──────────────────────────

  @override
  List<Widget> buildExerciseOverlays(
    BuildContext context, {
    required Size portrait,
    required double scale,
    required double offsetX,
    required double offsetY,
  }) {
    return [
      // Skeleton + angle labels + error highlights
      if (imageSize != Size.zero)
        Positioned.fill(
          child: CustomPaint(
            painter: PosePainter(
              poses: poses,
              imageSize: imageSize,
              rotation: rotation,
              portraitSize: portrait,
              coverScale: scale,
              coverOffsetX: offsetX,
              coverOffsetY: offsetY,
              monitoredConnections: _kSquatMonitoredConnections,
              monitoredLandmarks: _kSquatMonitoredLandmarks,
              angleLabels: [
                (PoseLandmarkType.leftKnee, _angles.kneeAngle),
                (PoseLandmarkType.leftHip, _angles.hipAngle),
                (PoseLandmarkType.leftAnkle, _angles.ankleAngle),
              ],
              highlightedJoints: _highlightedJoints(_error),
              isGood: _error == SquatError.good &&
                  _phaseDetector.phase != SquatPhase.standing,
            ),
          ),
        ),

      // Feedback bubbles
      Positioned(
        right: 10,
        top: MediaQuery.of(context).padding.top + 60,
        bottom: MediaQuery.of(context).padding.bottom + 20,
        child: Center(
          child: SquatFeedbackWidget(
            angles: _angles,
            error: _error,
            repCount: _repCount,
          ),
        ),
      ),
    ];
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) => buildCoachScaffold(context);
}

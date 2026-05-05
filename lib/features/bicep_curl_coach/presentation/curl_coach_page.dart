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
import 'package:kinecue/features/bicep_curl_coach/domain/curl_angle_model.dart';
import 'package:kinecue/features/bicep_curl_coach/domain/curl_form_checker.dart';
import 'package:kinecue/features/bicep_curl_coach/domain/curl_phase_detector.dart';
import 'package:kinecue/features/bicep_curl_coach/presentation/curl_feedback_widget.dart';
import 'package:kinecue/shared/mixins/camera_coach_mixin.dart';
import 'package:kinecue/shared/widgets/pose_painter.dart';

class CurlCoachPage extends StatefulWidget {
  const CurlCoachPage({super.key, required this.cameras, required this.config});

  final List<CameraDescription> cameras;
  final WorkoutConfig config;

  @override
  State<CurlCoachPage> createState() => _CurlCoachPageState();
}

class _CurlCoachPageState extends State<CurlCoachPage>
    with CameraCoachMixin<CurlCoachPage> {
  // ── 弯举监控区配置 ─────────────────────────────────────
  static const _kCurlMonitoredConnections = [
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
    [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
    [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
    [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
  ];

  static const _kCurlMonitoredLandmarks = {
    PoseLandmarkType.leftShoulder,
    PoseLandmarkType.rightShoulder,
    PoseLandmarkType.leftElbow,
    PoseLandmarkType.rightElbow,
    PoseLandmarkType.leftWrist,
    PoseLandmarkType.rightWrist,
  };

  // ── 弯举状态 ───────────────────────────────────────────
  CurlAngleModel _angles = const CurlAngleModel(
    elbowAngle: null,
    shoulderAngle: null,
  );
  CurlError _error = CurlError.good;
  final CurlPhaseDetector _phaseDetector = CurlPhaseDetector();
  int _repCount = 0;
  int _peakGoodFrames = 0;
  bool _peakQualityMet = false;
  static const int _kPeakQualityMinFrames = 3;
  int _curlingBadFrames = 0;
  static const int _kCurlingBadMinFrames = 3;
  static const int _kCurlingBadVoiceMinFrames = 15;

  // ── TTS 状态 ──────────────────────────────────────────────
  CurlError _lastSpokenError = CurlError.good;
  int _lastSpokenRep = 0;

  // ── 每组数据收集 ──────────────────────────────────────────
  final Map<String, int> _errorCounts = {};
  final List<double> _peakAngles = [];

  // ── Mixin: cameras / config ───────────────────────────────

  @override
  List<CameraDescription> get cameras => widget.cameras;

  @override
  WorkoutConfig get workoutConfig => widget.config;

  @override
  ExerciseType get exerciseType => ExerciseType.bicepCurl;

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
    final newError = CurlFormChecker.check(angles);

    int newRepCount = _repCount;
    CurlPhase currentPhase = _phaseDetector.phase;

    if (angles.isFullyValid) {
      final prevPhase = _phaseDetector.phase;
      final (phase, cycleCompleted) =
          _phaseDetector.update(angles.elbowAngle!);
      currentPhase = phase;

      if (prevPhase == CurlPhase.extended && phase == CurlPhase.curling) {
        _peakQualityMet = false;
        _peakGoodFrames = 0;
      }

      if (phase == CurlPhase.curling && newError == CurlError.bodySwing) {
        if (_curlingBadFrames < _kCurlingBadVoiceMinFrames) {
          _curlingBadFrames++;
        }
      } else {
        _curlingBadFrames = 0;
      }

      // 收集每组顶峰角度
      if (phase == CurlPhase.peak && angles.elbowAngle != null) {
        _peakAngles.add(angles.elbowAngle!);
      }

      if (phase == CurlPhase.peak && newError == CurlError.good) {
        _peakGoodFrames++;
        if (_peakGoodFrames >= _kPeakQualityMinFrames) {
          _peakQualityMet = true;
        }
      }

      if (cycleCompleted) {
        if (_peakQualityMet) {
          newRepCount = _repCount + 1;
          if (newError != CurlError.good) {
            final key = newError.name;
            _errorCounts[key] = (_errorCounts[key] ?? 0) + 1;
          }
        }
        _peakQualityMet = false;
        _peakGoodFrames = 0;
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

  CurlError _effectiveError(CurlError raw, CurlPhase phase) {
    if (phase == CurlPhase.extended) return CurlError.good;
    if (raw == CurlError.bodySwing) {
      return _curlingBadFrames >= _kCurlingBadMinFrames
          ? CurlError.bodySwing
          : CurlError.good;
    }
    return raw;
  }

  CurlError _effectiveVoiceError(CurlError raw, CurlPhase phase) {
    if (phase == CurlPhase.extended) return CurlError.good;
    if (raw == CurlError.bodySwing) {
      return _curlingBadFrames >= _kCurlingBadVoiceMinFrames
          ? CurlError.bodySwing
          : CurlError.good;
    }
    return raw;
  }

  // ── TTS ────────────────────────────────────────────────────

  void _triggerTts(CurlError newError, int newRepCount, CurlPhase phase) {
    if (newRepCount > _lastSpokenRep) {
      _lastSpokenRep = newRepCount;
      _lastSpokenError = newError;
      unawaited(
        tts.stop().then((_) => tts.speak(AppCopy.repAnnouncement(newRepCount))),
      );
      return;
    }

    if (phase == CurlPhase.extended) {
      _lastSpokenError = newError;
      return;
    }

    if (newError == CurlError.good && _lastSpokenError != CurlError.good) {
      unawaited(tts.stop());
      _lastSpokenError = newError;
      return;
    }

    if (newError != CurlError.good && newError != _lastSpokenError) {
      _lastSpokenError = newError;
      unawaited(tts.speak(_textForError(newError)));
    } else {
      _lastSpokenError = newError;
    }
  }

  String _textForError(CurlError error) => switch (error) {
        CurlError.good => AppCopy.feedbackCurlGood,
        CurlError.bodySwing => AppCopy.feedbackBodySwing,
        CurlError.incompleteExtension => AppCopy.feedbackIncompleteExtension,
        CurlError.incompleteCurl => AppCopy.feedbackIncompleteCurl,
      };

  // ── Helpers ────────────────────────────────────────────────

  Set<PoseLandmarkType> _highlightedJoints(CurlError error) =>
      switch (error) {
        CurlError.bodySwing => {
            PoseLandmarkType.leftShoulder,
            PoseLandmarkType.rightShoulder,
            PoseLandmarkType.leftElbow,
            PoseLandmarkType.rightElbow,
          },
        _ => const {},
      };

  CurlAngleModel _computeAngles(Pose pose) {
    PoseLandmark? lm(PoseLandmarkType t) {
      final l = pose.landmarks[t];
      return (l != null && l.likelihood >= PoseThresholds.kLandmarkConfidence)
          ? l
          : null;
    }

    final hip = lm(PoseLandmarkType.leftHip);
    final shoulder = lm(PoseLandmarkType.leftShoulder);
    final elbow = lm(PoseLandmarkType.leftElbow);
    final wrist = lm(PoseLandmarkType.leftWrist);

    return CurlAngleModel(
      elbowAngle: (shoulder != null && elbow != null && wrist != null)
          ? AngleCalculator.calculate(shoulder, elbow, wrist)
          : null,
      shoulderAngle: (hip != null && shoulder != null && elbow != null)
          ? AngleCalculator.calculate(hip, shoulder, elbow)
          : null,
    );
  }

  // ── Mixin: session management ──────────────────────────────

  @override
  SetSummary buildSetSummary(int setNumber) {
    final duration = setStartTime != null
        ? DateTime.now().difference(setStartTime!).inSeconds
        : 0;
    final avgAngle = _peakAngles.isNotEmpty
        ? _peakAngles.reduce((a, b) => a + b) / _peakAngles.length
        : null;

    return SetSummary(
      exerciseName: 'bicep_curl',
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
    _angles = const CurlAngleModel(elbowAngle: null, shoulderAngle: null);
    _error = CurlError.good;
    _phaseDetector.reset();
    _repCount = 0;
    _peakGoodFrames = 0;
    _peakQualityMet = false;
    _curlingBadFrames = 0;
    _lastSpokenError = CurlError.good;
    _lastSpokenRep = 0;
    _errorCounts.clear();
    _peakAngles.clear();
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
              monitoredConnections: _kCurlMonitoredConnections,
              monitoredLandmarks: _kCurlMonitoredLandmarks,
              angleLabels: [
                (PoseLandmarkType.leftElbow, _angles.elbowAngle),
                (PoseLandmarkType.leftShoulder, _angles.shoulderAngle),
              ],
              highlightedJoints: _highlightedJoints(_error),
              isGood: _error == CurlError.good &&
                  _phaseDetector.phase != CurlPhase.extended,
            ),
          ),
        ),

      // Feedback bubbles
      Positioned(
        right: 10,
        top: MediaQuery.of(context).padding.top + 60,
        bottom: MediaQuery.of(context).padding.bottom + 20,
        child: Center(
          child: CurlFeedbackWidget(
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

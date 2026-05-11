import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import 'package:kinecue/core/constants/copy.dart';
import 'package:kinecue/core/constants/debug_flags.dart';
import 'package:kinecue/core/constants/pose_thresholds.dart';
import 'package:kinecue/core/models/exercise_type.dart';
import 'package:kinecue/core/models/session_state.dart';
import 'package:kinecue/core/models/set_summary.dart';
import 'package:kinecue/core/models/workout_config.dart';
import 'package:kinecue/core/models/workout_session.dart';
import 'package:kinecue/core/services/coaching_api_service.dart';
import 'package:kinecue/core/services/workout_db_service.dart';
import 'package:kinecue/core/theme/app_theme.dart';
import 'package:kinecue/core/utils/logger.dart';
import 'package:kinecue/features/pose_detection/data/pose_detector_service.dart';
import 'package:kinecue/shared/widgets/rest_screen_overlay.dart';

/// Shared camera, pose-detection, TTS, and session lifecycle for all coach pages.
///
/// Concrete pages mix this in and implement [cameras], [workoutConfig],
/// [onPoseDetected], [buildExerciseOverlays], [buildSetSummary],
/// and [resetForNextSet].
mixin CameraCoachMixin<T extends StatefulWidget> on State<T> {
  // ── Abstract — subclass must implement ────────────────────

  List<CameraDescription> get cameras;
  WorkoutConfig get workoutConfig;
  ExerciseType get exerciseType;
  void onPoseDetected(Pose? pose);

  List<Widget> buildExerciseOverlays(
    BuildContext context, {
    required Size portrait,
    required double scale,
    required double offsetX,
    required double offsetY,
  });

  /// Build a [SetSummary] from the current set's accumulated stats.
  SetSummary buildSetSummary(int setNumber);

  /// Reset exercise-specific state for the next set (rep count, errors, angles, phase).
  void resetForNextSet();

  // ── Camera / Detection state ──────────────────────────────

  CameraController? cameraController;
  CameraLensDirection lensDirection = CameraLensDirection.front;
  bool isSwitching = false;
  final PoseDetectorService detectorService = PoseDetectorService();
  List<Pose> poses = [];
  bool _isProcessing = false;
  Size imageSize = Size.zero;
  InputImageRotation rotation = InputImageRotation.rotation270deg;
  String? cameraError;

  // ── TTS ────────────────────────────────────────────────────

  final FlutterTts tts = FlutterTts();

  // ── Session state ──────────────────────────────────────────

  SessionPhase sessionPhase = SessionPhase.exercising;
  int currentSet = 1;
  int _totalRepsAccumulated = 0;
  DateTime? setStartTime;
  DateTime? _sessionStartTime;
  final List<SetSummary> _completedSets = [];

  // ── Rest timer ─────────────────────────────────────────────

  Timer? _restTimer;
  int remainingSeconds = 0;
  DateTime? _restStartTime;

  // ── AI Coaching ────────────────────────────────────────────

  final CoachingApiService _coachingService = CoachingApiService();
  String? coachingText;
  bool isLoadingCoaching = false;

  // ── Lifecycle helpers ──────────────────────────────────────

  void initCoach() {
    _sessionStartTime = DateTime.now();
    setStartTime = DateTime.now();
    _completedSets.clear();
    initCamera();
    initTts();
  }

  void disposeCoach() {
    _restTimer?.cancel();
    _coachingService.dispose();
    cameraController?.dispose();
    detectorService.close();
    tts.stop();
  }

  // ── Camera ─────────────────────────────────────────────────

  Future<void> initCamera() async {
    final camera = cameras.firstWhere(
      (c) => c.lensDirection == lensDirection,
      orElse: () => cameras.first,
    );

    rotation =
        InputImageRotationValue.fromRawValue(camera.sensorOrientation) ??
            InputImageRotation.rotation270deg;

    cameraController = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.bgra8888,
    );

    try {
      await cameraController!.initialize();
    } on CameraException catch (e) {
      Log.e('Camera init failed: ${e.description}', tag: 'Camera');
      if (!mounted) return;
      setState(() => cameraError = AppCopy.cameraPermissionDenied);
      return;
    }

    if (!mounted) return;
    setState(() {});
    cameraController!.startImageStream(_processFrame);
  }

  Future<void> switchCamera() async {
    if (isSwitching) return;
    setState(() {
      isSwitching = true;
      poses = [];
      imageSize = Size.zero;
    });

    await cameraController?.dispose();
    cameraController = null;

    lensDirection = lensDirection == CameraLensDirection.front
        ? CameraLensDirection.back
        : CameraLensDirection.front;

    await initCamera();
    if (mounted) setState(() => isSwitching = false);
  }

  // ── TTS ────────────────────────────────────────────────────

  Future<void> initTts() async {
    await tts.setLanguage('zh-CN');
    await tts.setSpeechRate(0.45);
    await tts.setVolume(1.0);
  }

  // ── Frame processing ───────────────────────────────────────

  Future<void> _processFrame(CameraImage image) async {
    if (_isProcessing || sessionPhase != SessionPhase.exercising) return;
    _isProcessing = true;

    try {
      imageSize = Size(image.width.toDouble(), image.height.toDouble());

      final inputImage = InputImage.fromBytes(
        bytes: image.planes[0].bytes,
        metadata: InputImageMetadata(
          size: imageSize,
          rotation: rotation,
          format: InputImageFormat.bgra8888,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );

      final detectedPoses = await detectorService.processImage(inputImage);
      if (!mounted) return;

      final detectedPose =
          detectedPoses.isNotEmpty && isPoseRealistic(detectedPoses.first)
              ? detectedPoses.first
              : null;

      onPoseDetected(detectedPose);
    } finally {
      _isProcessing = false;
    }
  }

  bool isPoseRealistic(Pose pose) {
    double? minY, maxY;
    for (final t in [
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftAnkle,
      PoseLandmarkType.rightAnkle,
    ]) {
      final lm = pose.landmarks[t];
      if (lm == null) continue;
      if (minY == null || lm.y < minY) minY = lm.y;
      if (maxY == null || lm.y > maxY) maxY = lm.y;
    }
    if (minY == null || maxY == null) return false;
    return (maxY - minY) >=
        imageSize.height * PoseThresholds.kPoseMinSpanRatio;
  }

  // ── Session management ─────────────────────────────────────

  /// Call this from [onPoseDetected] after updating rep count.
  /// Triggers rest phase when target reps are reached.
  void notifyRepCompleted(int repCount) {
    if (sessionPhase != SessionPhase.exercising) return;
    if (repCount >= workoutConfig.targetReps) {
      _startRest(repCount);
    }
  }

  void _startRest(int repsCompleted) {
    _totalRepsAccumulated += repsCompleted;

    // Build set summary before resetting
    final summary = buildSetSummary(currentSet);
    _completedSets.add(summary);

    // Last set → go to completed directly (with coaching text)
    final isLastSet = currentSet >= workoutConfig.totalSets;

    setState(() {
      sessionPhase = isLastSet ? SessionPhase.resting : SessionPhase.resting;
      remainingSeconds = workoutConfig.restSeconds;
      coachingText = null;
      isLoadingCoaching = true;
    });

    // Start rest timer
    _restStartTime = DateTime.now();
    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        _restTimer?.cancel();
        return;
      }
      final elapsed =
          DateTime.now().difference(_restStartTime!).inSeconds;
      final remaining = workoutConfig.restSeconds - elapsed;
      setState(() {
        remainingSeconds = remaining > 0 ? remaining : 0;
      });
    });

    // Request AI coaching asynchronously
    _coachingService.getCoachingFeedback(summary).then((text) {
      if (!mounted) return;
      setState(() {
        coachingText = text;
        isLoadingCoaching = false;
      });
    });

    Log.d(
      'Set $currentSet complete: ${summary.repsCompleted} reps',
      tag: 'Session',
    );
  }

  void _startNextSet() {
    _restTimer?.cancel();
    currentSet++;
    resetForNextSet();
    setStartTime = DateTime.now();

    setState(() {
      sessionPhase = SessionPhase.exercising;
      coachingText = null;
      isLoadingCoaching = false;
    });
  }

  void _endWorkout() {
    _persistWorkout();
    Navigator.pop(context);
  }

  void _persistWorkout() {
    if (_completedSets.isEmpty) return;
    final session = WorkoutSession.fromSets(
      exerciseType: exerciseType,
      startedAt: _sessionStartTime ?? DateTime.now(),
      sets: List.of(_completedSets),
    );
    WorkoutDbService.instance.insertSession(session).catchError((e) {
      Log.e('Failed to save workout: $e', tag: 'DB');
      return -1;
    });
  }

  // ── Layout helpers ─────────────────────────────────────────

  Size get portraitPreviewSize {
    final ps = cameraController!.value.previewSize!;
    final swap = rotation == InputImageRotation.rotation90deg ||
        rotation == InputImageRotation.rotation270deg;
    return swap ? Size(ps.height, ps.width) : ps;
  }

  // ── Build ──────────────────────────────────────────────────

  Widget buildCoachScaffold(BuildContext context) {
    // Camera error
    if (cameraError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.videocam_off,
                    color: AppColors.onSurfaceLow, size: 64),
                const SizedBox(height: 16),
                Text(
                  cameraError!,
                  style: TextStyle(
                      color: AppColors.onSurfaceHigh, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(AppCopy.goBack),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Camera loading
    if (cameraController == null ||
        !cameraController!.value.isInitialized) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    final screen = MediaQuery.of(context).size;
    final portrait = portraitPreviewSize;

    final bool isLandscape = screen.width > screen.height;
    final double scale = isLandscape
        ? math.min(screen.width / portrait.width,
            screen.height / portrait.height)
        : math.max(screen.width / portrait.width,
            screen.height / portrait.height);

    final double scaledW = portrait.width * scale;
    final double scaledH = portrait.height * scale;
    final double offsetX = (scaledW - screen.width) / 2;
    final double offsetY = (scaledH - screen.height) / 2;

    return Scaffold(
      body: Stack(
        children: [
          // ① Camera preview
          Positioned.fill(
            child: ClipRect(
              child: FittedBox(
                fit: isLandscape ? BoxFit.contain : BoxFit.cover,
                alignment: Alignment.center,
                child: SizedBox(
                  width: portrait.width,
                  height: portrait.height,
                  child: CameraPreview(cameraController!),
                ),
              ),
            ),
          ),

          // ② Overlay mask
          Positioned.fill(
            child: ColoredBox(
              color: AppColors.surface.withValues(alpha: 0.10),
            ),
          ),

          // ③④ Exercise-specific overlays
          if (sessionPhase == SessionPhase.exercising)
            ...buildExerciseOverlays(
              context,
              portrait: portrait,
              scale: scale,
              offsetX: offsetX,
              offsetY: offsetY,
            ),

          // ⑤ Debug overlay
          if (kShowDebugOverlay && sessionPhase == SessionPhase.exercising)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.all(6),
                color: AppColors.overlayLight,
                child: Text(
                  'img: ${imageSize.width.toInt()}×${imageSize.height.toInt()}'
                  '\nrot: $rotation'
                  '\nportrait: ${portrait.width.toInt()}×${portrait.height.toInt()}'
                  '\nscale: ${scale.toStringAsFixed(2)}'
                  '\noffX: ${offsetX.toInt()} offY: ${offsetY.toInt()}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                  ),
                ),
              ),
            ),

          // ⑥ Camera switch + exit buttons
          if (sessionPhase == SessionPhase.exercising)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 16,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: _endWorkout,
                    icon: const Icon(Icons.close_rounded),
                    color: AppColors.onSurface,
                    iconSize: 28,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.overlaySubtle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: isSwitching ? null : switchCamera,
                    icon: const Icon(Icons.cameraswitch_rounded),
                    color: AppColors.onSurface,
                    iconSize: 28,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.overlaySubtle,
                    ),
                  ),
                ],
              ),
            ),

          // ⑦ Rest screen overlay
          if (sessionPhase == SessionPhase.resting)
            Positioned.fill(
              child: RestScreenOverlay(
                setNumber: currentSet,
                repsCompleted: workoutConfig.targetReps,
                targetReps: workoutConfig.targetReps,
                remainingSeconds: remainingSeconds,
                coachingText: coachingText,
                isLoadingCoaching: isLoadingCoaching,
                isLastSet: currentSet >= workoutConfig.totalSets,
                onNextSet: _startNextSet,
                onEndWorkout: _endWorkout,
              ),
            ),

          // ⑧ Workout complete overlay
          if (sessionPhase == SessionPhase.completed)
            Positioned.fill(
              child: WorkoutCompleteOverlay(
                totalSets: currentSet,
                totalReps: _totalRepsAccumulated,
                onFinish: _endWorkout,
              ),
            ),
        ],
      ),
    );
  }
}

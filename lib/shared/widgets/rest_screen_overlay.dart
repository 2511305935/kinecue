import 'package:flutter/material.dart';

import 'package:kinecue/core/constants/copy.dart';
import 'package:kinecue/core/theme/app_theme.dart';

/// 组间休息覆盖层：倒计时 + AI 教练建议 + 操作按钮。
class RestScreenOverlay extends StatelessWidget {
  const RestScreenOverlay({
    super.key,
    required this.setNumber,
    required this.repsCompleted,
    required this.targetReps,
    required this.remainingSeconds,
    required this.coachingText,
    required this.isLoadingCoaching,
    required this.onNextSet,
    required this.onEndWorkout,
    required this.isLastSet,
  });

  final int setNumber;
  final int repsCompleted;
  final int targetReps;
  final int remainingSeconds;
  final String? coachingText;
  final bool isLoadingCoaching;
  final VoidCallback onNextSet;
  final VoidCallback onEndWorkout;
  final bool isLastSet;

  String get _timerText {
    final m = remainingSeconds ~/ 60;
    final s = remainingSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.overlay,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 组完成标题
                Text(
                  AppCopy.setComplete(setNumber),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppCopy.setProgress(repsCompleted, targetReps),
                  style: TextStyle(
                    color: AppColors.onSurfaceMedium,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 32),

                // 倒计时
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadiusLg),
                  ),
                  child: Column(
                    children: [
                      Text(
                        AppCopy.restTime,
                        style: TextStyle(
                          color: AppColors.onSurfaceLow,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) =>
                            FadeTransition(opacity: animation, child: child),
                        child: Text(
                          _timerText,
                          key: ValueKey(remainingSeconds),
                          style: const TextStyle(
                            color: AppColors.onSurface,
                            fontSize: 48,
                            fontWeight: FontWeight.w300,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // AI 教练建议
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppCopy.aiCoachTitle,
                        style: TextStyle(
                          color: AppColors.onSurfaceLow,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (isLoadingCoaching)
                        Text(
                          AppCopy.aiCoachLoading,
                          style: TextStyle(
                            color: AppColors.onSurfaceLow,
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        )
                      else
                        Text(
                          coachingText ?? AppCopy.aiCoachFallback,
                          style: const TextStyle(
                            color: AppColors.onSurface,
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // 操作按钮
                if (!isLastSet)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: onNextSet,
                      child: Text(
                        AppCopy.nextSet,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: onEndWorkout,
                    child: Text(
                      AppCopy.endWorkout,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 训练完成覆盖层。
class WorkoutCompleteOverlay extends StatelessWidget {
  const WorkoutCompleteOverlay({
    super.key,
    required this.totalSets,
    required this.totalReps,
    required this.onFinish,
  });

  final int totalSets;
  final int totalReps;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.overlayDark,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) => Transform.scale(
                    scale: value,
                    child: child,
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    color: AppColors.warning,
                    size: 64,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  AppCopy.workoutComplete,
                  style: TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppCopy.workoutSummary(totalSets, totalReps),
                  style: TextStyle(
                    color: AppColors.onSurfaceMedium,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: onFinish,
                    child: const Text(
                      AppCopy.goBack,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

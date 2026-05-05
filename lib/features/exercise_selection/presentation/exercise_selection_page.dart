import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:kinecue/core/constants/copy.dart';
import 'package:kinecue/core/models/workout_config.dart';
import 'package:kinecue/core/models/workout_session.dart';
import 'package:kinecue/core/services/workout_db_service.dart';
import 'package:kinecue/features/squat_coach/presentation/squat_coach_page.dart';
import 'package:kinecue/features/bicep_curl_coach/presentation/curl_coach_page.dart';

/// 运动选择页：app 入口，选择训练动作并配置组数后跳转到对应教练页。
class ExerciseSelectionPage extends StatefulWidget {
  const ExerciseSelectionPage({super.key, required this.cameras});

  final List<CameraDescription> cameras;

  @override
  State<ExerciseSelectionPage> createState() => _ExerciseSelectionPageState();
}

class _ExerciseSelectionPageState extends State<ExerciseSelectionPage> {
  int _targetReps = WorkoutConfig.defaultConfig.targetReps;
  int _totalSets = WorkoutConfig.defaultConfig.totalSets;
  int _restSeconds = WorkoutConfig.defaultConfig.restSeconds;

  List<WorkoutSession> _recentSessions = [];

  WorkoutConfig get _config => WorkoutConfig(
        targetReps: _targetReps,
        totalSets: _totalSets,
        restSeconds: _restSeconds,
      );

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final sessions = await WorkoutDbService.instance.getRecentSessions();
    if (mounted) setState(() => _recentSessions = sessions);
  }

  Future<void> _startExercise(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            const SizedBox(height: 60),
            const Text(
              'KineCue',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppCopy.selectExerciseTitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),

            // ── 训练配置 ────────────────────────────────
            _ConfigRow(
              configs: [
                _ConfigItem(
                  label: AppCopy.configReps,
                  value: _targetReps,
                  min: 1,
                  max: 30,
                  onChanged: (v) => setState(() => _targetReps = v),
                ),
                _ConfigItem(
                  label: AppCopy.configSets,
                  value: _totalSets,
                  min: 1,
                  max: 10,
                  onChanged: (v) => setState(() => _totalSets = v),
                ),
                _ConfigItem(
                  label: AppCopy.configRest,
                  value: _restSeconds,
                  min: 10,
                  max: 180,
                  step: 10,
                  onChanged: (v) => setState(() => _restSeconds = v),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // ── 运动卡片 ────────────────────────────────
            _ExerciseCard(
              icon: Icons.fitness_center,
              title: AppCopy.exerciseSquat,
              subtitle: AppCopy.exerciseSquatDesc,
              onTap: () => _startExercise(
                SquatCoachPage(cameras: widget.cameras, config: _config),
              ),
            ),
            const SizedBox(height: 16),
            _ExerciseCard(
              icon: Icons.front_hand,
              title: AppCopy.exerciseBicepCurl,
              subtitle: AppCopy.exerciseBicepCurlDesc,
              onTap: () => _startExercise(
                CurlCoachPage(cameras: widget.cameras, config: _config),
              ),
            ),

            // ── 训练记录 ────────────────────────────────
            const SizedBox(height: 36),
            Text(
              AppCopy.historyTitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            if (_recentSessions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    AppCopy.historyEmpty,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 14,
                    ),
                  ),
                ),
              )
            else
              for (final session in _recentSessions) ...[
                _HistoryCard(session: session),
                const SizedBox(height: 10),
              ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── 配置行 ──────────────────────────────────────────────────

class _ConfigRow extends StatelessWidget {
  const _ConfigRow({required this.configs});

  final List<_ConfigItem> configs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (int i = 0; i < configs.length; i++) ...[
            if (i > 0)
              Container(
                width: 1,
                height: 36,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: Colors.white.withValues(alpha: 0.1),
              ),
            Expanded(child: configs[i]),
          ],
        ],
      ),
    );
  }
}

class _ConfigItem extends StatelessWidget {
  const _ConfigItem({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.step = 1,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            _StepButton(
              icon: Icons.remove,
              enabled: value > min,
              onTap: () => onChanged((value - step).clamp(min, max)),
            ),
            SizedBox(
              width: 40,
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _StepButton(
              icon: Icons.add,
              enabled: value < max,
              onTap: () => onChanged((value + step).clamp(min, max)),
            ),
          ],
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: enabled ? 0.12 : 0.04),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled
              ? Colors.white.withValues(alpha: 0.7)
              : Colors.white.withValues(alpha: 0.2),
        ),
      ),
    );
  }
}

// ── 运动卡片 ─────────────────────────────────────────────────

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 36),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 训练记录卡片 ─────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.session});

  final WorkoutSession session;

  IconData get _icon => switch (session.exerciseType.name) {
        'squat' => Icons.fitness_center,
        'bicepCurl' => Icons.front_hand,
        _ => Icons.sports,
      };

  String get _exerciseName =>
      AppCopy.exerciseNames[session.exerciseType.name] ??
      session.exerciseType.name;

  String get _dateText {
    final d = session.startedAt;
    return DateFormat('M月d日 HH:mm').format(d);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(_icon, color: Colors.white38, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_exerciseName · $_dateText',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppCopy.historyItemSummary(
                    session.totalSets,
                    session.totalReps,
                    session.totalDurationSeconds,
                  ),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

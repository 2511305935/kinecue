import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:kinecue/core/constants/copy.dart';
import 'package:kinecue/core/models/set_summary.dart';
import 'package:kinecue/core/models/workout_session.dart';
import 'package:kinecue/core/services/workout_db_service.dart';
import 'package:kinecue/core/theme/app_theme.dart';

/// 训练详情页：展示单次训练的每组数据。
class TrainingDetailPage extends StatefulWidget {
  const TrainingDetailPage({super.key, required this.sessionId});

  final int sessionId;

  @override
  State<TrainingDetailPage> createState() => _TrainingDetailPageState();
}

class _TrainingDetailPageState extends State<TrainingDetailPage> {
  WorkoutSession? _session;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final session = await WorkoutDbService.instance.getSession(widget.sessionId);
    if (mounted) {
      setState(() {
        _session = session;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppCopy.detailTitle)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off, color: AppColors.onSurfaceLow, size: 48),
              const SizedBox(height: 12),
              Text(
                AppCopy.detailNotFound,
                style: TextStyle(color: AppColors.onSurfaceMedium, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    final session = _session!;
    final exerciseName =
        AppCopy.exerciseNames[session.exerciseType.name] ??
        session.exerciseType.name;
    final dateText = DateFormat('yyyy年M月d日 HH:mm').format(session.startedAt);

    return Scaffold(
      appBar: AppBar(title: const Text(AppCopy.detailTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
        children: [
          const SizedBox(height: AppSpacing.md),

          // ── 概要 ──────────────────────────────────
          Text(
            exerciseName,
            style: const TextStyle(
              color: AppColors.onSurface,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dateText,
            style: TextStyle(color: AppColors.onSurfaceMedium, fontSize: 14),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── 总览卡片 ──────────────────────────────
          _SummaryRow(session: session),
          const SizedBox(height: AppSpacing.lg),

          // ── 错误统计 ──────────────────────────────
          if (session.errorCounts.isNotEmpty) ...[
            _SectionTitle(AppCopy.detailErrors),
            const SizedBox(height: AppSpacing.sm),
            _ErrorSummaryCard(errorCounts: session.errorCounts),
            const SizedBox(height: AppSpacing.lg),
          ],

          // ── 每组详情 ──────────────────────────────
          if (session.setSummaries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(
                child: Text(
                  AppCopy.detailNoSets,
                  style: TextStyle(
                    color: AppColors.onSurfaceLow,
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            for (final summary in session.setSummaries) ...[
              _SetCard(summary: summary),
              const SizedBox(height: AppSpacing.sm),
            ],

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

// ── 总览行 ──────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.session});

  final WorkoutSession session;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(label: AppCopy.configSets, value: '${session.totalSets}'),
          _StatItem(label: AppCopy.detailReps, value: '${session.totalReps}'),
          _StatItem(
            label: AppCopy.detailDuration,
            value: AppCopy.formatDuration(session.totalDurationSeconds),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(color: AppColors.onSurfaceLow, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// ── 错误统计卡片 ────────────────────────────────────────────

class _ErrorSummaryCard extends StatelessWidget {
  const _ErrorSummaryCard({required this.errorCounts});

  final Map<String, int> errorCounts;

  @override
  Widget build(BuildContext context) {
    final sorted = errorCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Column(
        children: [
          for (int i = 0; i < sorted.length; i++) ...[
            if (i > 0) Divider(height: 1, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      AppCopy.errorDisplayNames[sorted[i].key] ?? sorted[i].key,
                      style: TextStyle(
                        color: AppColors.onSurfaceHigh,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppSpacing.bubbleRadius),
                    ),
                    child: Text(
                      '${sorted[i].value}',
                      style: const TextStyle(
                        color: AppColors.warning,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── 单组卡片 ────────────────────────────────────────────────

class _SetCard extends StatelessWidget {
  const _SetCard({required this.summary});

  final SetSummary summary;

  @override
  Widget build(BuildContext context) {
    final hasErrors = summary.errorCounts.values.any((v) => v > 0);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardSubtle,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          Row(
            children: [
              Text(
                AppCopy.detailSetLabel(summary.setNumber),
                style: const TextStyle(
                  color: AppColors.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${summary.repsCompleted}/${summary.targetReps} 次',
                style: TextStyle(
                  color: summary.repsCompleted >= summary.targetReps
                      ? AppColors.primary
                      : AppColors.onSurfaceMedium,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 指标行
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: 4,
            children: [
              _Chip(
                label: AppCopy.detailDuration,
                value: AppCopy.formatDuration(summary.durationSeconds),
              ),
              if (summary.avgKeyAngle != null)
                _Chip(
                  label: AppCopy.detailAvgAngle,
                  value: '${summary.avgKeyAngle!.toStringAsFixed(1)}°',
                ),
            ],
          ),

          // 错误明细
          if (hasErrors) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final e in summary.errorCounts.entries)
                  if (e.value > 0)
                    _ErrorChip(
                      label: AppCopy.errorDisplayNames[e.key] ?? e.key,
                      count: e.value,
                    ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 4),
            Text(
              AppCopy.detailNoErrors,
              style: TextStyle(color: AppColors.primary, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

// ── 小组件 ──────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.onSurfaceLow,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label ',
          style: TextStyle(color: AppColors.onSurfaceLow, fontSize: 12),
        ),
        Text(
          value,
          style: TextStyle(color: AppColors.onSurfaceHigh, fontSize: 13),
        ),
      ],
    );
  }
}

class _ErrorChip extends StatelessWidget {
  const _ErrorChip({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.bubbleRadius),
      ),
      child: Text(
        '$label ×$count',
        style: TextStyle(color: AppColors.onSurfaceMedium, fontSize: 11),
      ),
    );
  }
}

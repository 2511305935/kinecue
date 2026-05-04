import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'package:kinecue/core/constants/copy.dart';
import 'package:kinecue/features/squat_coach/presentation/squat_coach_page.dart';
import 'package:kinecue/features/bicep_curl_coach/presentation/curl_coach_page.dart';

/// 运动选择页：app 入口，选择训练动作后跳转到对应教练页。
class ExerciseSelectionPage extends StatelessWidget {
  const ExerciseSelectionPage({super.key, required this.cameras});

  final List<CameraDescription> cameras;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 40),
              _ExerciseCard(
                icon: Icons.fitness_center,
                title: AppCopy.exerciseSquat,
                subtitle: AppCopy.exerciseSquatDesc,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SquatCoachPage(cameras: cameras),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _ExerciseCard(
                icon: Icons.front_hand,
                title: AppCopy.exerciseBicepCurl,
                subtitle: AppCopy.exerciseBicepCurlDesc,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CurlCoachPage(cameras: cameras),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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

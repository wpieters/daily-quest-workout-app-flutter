import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:daily_quest/shared/models/user_progress.dart';

class AnimationService {
  // Animation paths
  static const String _stageCompletionPath = 'assets/images/animations/stage_completion.json';
  static const String _basicPowerUpPath = 'assets/images/animations/basic_power_up.json';
  static const String _superSaiyan1Path = 'assets/images/animations/super_saiyan_1.json';
  static const String _superSaiyan2Path = 'assets/images/animations/super_saiyan_2.json';
  static const String _ultraInstinctPath = 'assets/images/animations/ultra_instinct.json';

  // Show stage completion animation
  static void showStageCompletionAnimation(BuildContext context) {
    _showAnimationDialog(
      context: context,
      animationPath: _stageCompletionPath,
      title: 'Stage Completed!',
      message: 'Keep going, you\'re making progress!',
      duration: const Duration(seconds: 2),
    );
  }

  // Show daily goal completion animation based on streak
  static void showDailyGoalCompletionAnimation(BuildContext context, int streak) {
    String animationPath;
    String title;
    String message;

    if (streak >= 100) {
      // Ultra Instinct (100+ days)
      animationPath = _ultraInstinctPath;
      title = 'ULTRA INSTINCT!';
      message = 'Day $streak! Your power level is over 9000!';
    } else if (streak >= 31) {
      // Super Saiyan 2 (31-100 days)
      animationPath = _superSaiyan2Path;
      title = 'SUPER SAIYAN 2!';
      message = 'Day $streak! Your power continues to grow!';
    } else if (streak >= 8) {
      // Super Saiyan 1 (8-30 days)
      animationPath = _superSaiyan1Path;
      title = 'SUPER SAIYAN!';
      message = 'Day $streak! You\'ve broken your limits!';
    } else {
      // Basic power-up (1-7 days)
      animationPath = _basicPowerUpPath;
      title = 'POWER UP!';
      message = 'Day $streak! Keep building your streak!';
    }

    _showAnimationDialog(
      context: context,
      animationPath: animationPath,
      title: title,
      message: message,
      duration: const Duration(seconds: 3),
    );
  }

  // Helper method to show animation dialog
  static void _showAnimationDialog({
    required BuildContext context,
    required String animationPath,
    required String title,
    required String message,
    required Duration duration,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        // Auto-dismiss after duration
        Future.delayed(duration, () {
          Navigator.of(context).pop();
        });

        return AlertDialog(
          backgroundColor: Colors.black.withOpacity(0.8),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animation
              SizedBox(
                height: 200,
                width: 200,
                child: Lottie.asset(
                  animationPath,
                  repeat: true,
                  animate: true,
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Message
              Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  // Get animation path based on power level
  static String getPowerUpAnimationPath(int powerLevel) {
    switch (powerLevel) {
      case 4:
        return _ultraInstinctPath;
      case 3:
        return _superSaiyan2Path;
      case 2:
        return _superSaiyan1Path;
      case 1:
      default:
        return _basicPowerUpPath;
    }
  }
}

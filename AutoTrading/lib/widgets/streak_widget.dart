import 'package:flutter/material.dart';
import '../../core/constants/app_theme.dart';

class StreakWidget extends StatelessWidget {
  final int currentStreak;
  final int bestStreak;

  const StreakWidget({super.key, required this.currentStreak, required this.bestStreak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: currentStreak >= 7
              ? [AppTheme.primaryOrange, AppTheme.primaryAmber]
              : [AppTheme.primaryAmber, AppTheme.primaryAmber.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            currentStreak >= 7 ? Icons.local_fire_department : Icons.whatshot_rounded,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$currentStreak day${currentStreak == 1 ? '' : 's'}',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  'Best: $bestStreak days',
                  style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.9)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
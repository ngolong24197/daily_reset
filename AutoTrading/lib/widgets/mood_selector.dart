import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_theme.dart';
import '../models/mood.dart';

class MoodSelector extends StatelessWidget {
  final Mood? selectedMood;
  final ValueChanged<Mood> onMoodSelected;

  const MoodSelector({super.key, this.selectedMood, required this.onMoodSelected});

  static const Map<Mood, (String emoji, String label, Color color)> _moodData = {
    Mood.great: ('😄', 'Great', AppTheme.moodGreat),
    Mood.good: ('🙂', 'Good', AppTheme.moodGood),
    Mood.okay: ('😐', 'Okay', AppTheme.moodOkay),
    Mood.low: ('😔', 'Low', AppTheme.moodLow),
    Mood.rough: ('😢', 'Rough', AppTheme.moodRough),
  };

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Mood selector',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _moodData.entries.map((entry) {
          final mood = entry.key;
          final (emoji, label, color) = entry.value;
          final isSelected = selectedMood == mood;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Semantics(
                label: '$label mood',
                button: true,
                selected: isSelected,
                child: Material(
                  color: isSelected ? color : color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      onMoodSelected(mood);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: isSelected ? Border.all(color: color, width: 2) : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(fontSize: isSelected ? 36 : 28),
                            child: Text(emoji),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.white : color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
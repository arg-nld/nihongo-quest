import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Lesson results: score, rewards granted, and a mistakes recap.
class LessonResultsScreen extends ConsumerWidget {
  const LessonResultsScreen({
    super.key,
    required this.sectionId,
    required this.title,
    required this.score,
    required this.total,
    required this.practiceCorrect,
    required this.practiceTotal,
    required this.unlockedAchievements,
  });

  final String sectionId;
  final String title;
  final int score;
  final int total;
  final int practiceCorrect;
  final int practiceTotal;
  final List<String> unlockedAchievements;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final passed = total > 0 && score / total >= 0.7;
    final player = ref.watch(progressProvider.select((p) => p.player));
    return Scaffold(
      appBar: AppBar(title: const Text('Results')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                passed ? Icons.celebration : Icons.fitness_center,
                size: 72,
                color: passed ? AppTheme.matcha : AppTheme.sakuraDeep,
              ),
              const SizedBox(height: 8),
              Text(
                passed ? '$title complete!' : 'Keep practicing!',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text('Quiz score: $score / $total'
                  '   ·   Practice: $practiceCorrect / $practiceTotal'),
              const SizedBox(height: 12),
              StatRow(player: player, dueCount: 0),
              if (unlockedAchievements.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.emoji_events,
                        size: 20, color: AppTheme.matchaDark),
                    const SizedBox(width: 6),
                    Text('Achievements: ${unlockedAchievements.join(", ")}'),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

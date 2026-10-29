import 'dart:math';

/// Reward rules. Designed to reward learning, not tapping:
///  - An exercise grants full XP/coins only the FIRST time it is answered
///    correctly (tracked by exercise ID). Replays grant a token amount.
///  - Review sessions always grant full XP (reviewing is the point).
///  - Quiz/lesson bonuses scale with the score, once per improvement.
class Rewards {
  static const int xpPerCorrectFirst = 10;
  static const int xpPerCorrectReplay = 2;
  static const int xpPerReviewCorrect = 8;
  static const int coinsPerCorrectFirst = 5;
  static const int coinsPerCorrectReplay = 1;
  static const int coinsPerReviewCorrect = 4;
  static const int lessonCompleteXp = 40;
  static const int lessonCompleteCoins = 20;
  static const int perfectQuizBonusXp = 30;

  static int quizBonusXp(int score, int total) {
    if (total == 0) return 0;
    return (30 * score / total).round();
  }

  static int levelUpRewardCoins(int newLevel) => 10 * newLevel;
}

/// Daily quest model: one per calendar day, e.g. "review 10 items".
class DailyQuest {
  const DailyQuest({
    required this.id,
    required this.title,
    required this.goal,
    required this.progress,
    required this.done,
  });

  final String id;
  final String title;
  final int goal;
  final int progress;
  final bool done;
}

/// Unlocks: the textbook order is the spine; section N unlocks when section
/// N-1 is marked complete by the unit boss or the legacy quiz pass threshold.
class Unlocks {
  static const double passFraction = 0.7;

  /// Returns the set of unlocked section IDs given lesson progress.
  static Set<String> unlockedSections(
      List<String> orderedSectionIds, Map<String, LessonProgressLite> progress) {
    final unlocked = <String>{};
    for (var i = 0; i < orderedSectionIds.length; i++) {
      final id = orderedSectionIds[i];
      if (i == 0) {
        unlocked.add(id);
        continue;
      }
      final prev = progress[orderedSectionIds[i - 1]];
      if (prev != null &&
          (prev.completed ||
              (prev.bestQuizTotal > 0 &&
                  prev.bestQuizScore / prev.bestQuizTotal >= passFraction))) {
        unlocked.add(id);
      } else {
        break; // sequential: stop at the first locked one
      }
    }
    return unlocked;
  }
}

/// Minimal progress snapshot used by [Unlocks] (keeps core independent of
/// persistence details).
class LessonProgressLite {
  const LessonProgressLite({
    required this.completed,
    required this.bestQuizScore,
    required this.bestQuizTotal,
  });
  final bool completed;
  final int bestQuizScore;
  final int bestQuizTotal;
}

/// Deterministic shuffle helper (tests + word_order exercise presentation).
List<int> seededShuffleIndices(int length, int seed) {
  final rng = Random(seed);
  final indices = List<int>.generate(length, (i) => i);
  for (var i = length - 1; i > 0; i--) {
    final j = rng.nextInt(i + 1);
    final tmp = indices[i];
    indices[i] = indices[j];
    indices[j] = tmp;
  }
  return indices;
}

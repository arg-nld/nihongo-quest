import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_quest/core/rewards.dart';
import 'package:nihongo_quest/models/progress_models.dart';

void main() {
  group('ReviewState SRS intervals', () {
    final now = DateTime(2026, 10, 22, 9, 0);

    test('first correct schedules review 1 day out', () {
      final s = const ReviewState(itemId: 'v1', itemType: 'vocab').answered(
          wasCorrect: true, now: now);
      expect(s.streak, 1);
      expect(s.attempts, 1);
      expect(s.correct, 1);
      final due = DateTime.fromMillisecondsSinceEpoch(s.nextReviewOn!);
      expect(due.difference(DateTime(2026, 10, 22)).inDays, 1);
    });

    test('streak 2 -> 3 days, streak 3 -> 7 days', () {
      var s = const ReviewState(itemId: 'v1', itemType: 'vocab');
      s = s.answered(wasCorrect: true, now: now);
      s = s.answered(wasCorrect: true, now: now);
      expect(s.streak, 2);
      final due2 = DateTime.fromMillisecondsSinceEpoch(s.nextReviewOn!);
      expect(due2.difference(DateTime(2026, 10, 22)).inDays, 3);
      s = s.answered(wasCorrect: true, now: now);
      final due3 = DateTime.fromMillisecondsSinceEpoch(s.nextReviewOn!);
      expect(due3.difference(DateTime(2026, 10, 22)).inDays, 7);
    });

    test('miss resets streak and schedules a same-day (4h) retry', () {
      var s = const ReviewState(itemId: 'v1', itemType: 'vocab');
      s = s.answered(wasCorrect: true, now: now);
      s = s.answered(wasCorrect: false, now: now);
      expect(s.streak, 0);
      expect(s.correct, 1);
      expect(s.attempts, 2);
      final due = DateTime.fromMillisecondsSinceEpoch(s.nextReviewOn!);
      expect(due.difference(now).inHours, 4);
    });

    test('long streak clamps at the 90-day interval', () {
      var s = const ReviewState(
          itemId: 'v1', itemType: 'vocab', streak: 10, attempts: 10, correct: 10);
      s = s.answered(wasCorrect: true, now: now);
      final due = DateTime.fromMillisecondsSinceEpoch(s.nextReviewOn!);
      expect(due.difference(DateTime(2026, 10, 22)).inDays, 90);
    });

    test('isDue: never-reviewed is due', () {
      expect(const ReviewState(itemId: 'v', itemType: 'vocab').isDue, isTrue);
    });

    test('isDue: future review is not due', () {
      final s = const ReviewState(itemId: 'v', itemType: 'vocab')
          .answered(wasCorrect: true, now: DateTime.now());
      // streak 1 -> due tomorrow, so not due today
      expect(s.isDue, isFalse);
    });

    group('mastery tiers', () {
      test('no attempts -> new', () {
        expect(const ReviewState(itemId: 'v', itemType: 'vocab').mastery,
            Mastery.new_);
      });
      test('one correct answer is NOT mastery', () {
        final s = const ReviewState(itemId: 'v', itemType: 'vocab')
            .answered(wasCorrect: true, now: DateTime.now());
        expect(s.mastery, isNot(Mastery.mastered));
      });
      test('streak 1-2 -> familiar', () {
        final s = const ReviewState(
                itemId: 'v', itemType: 'vocab', streak: 2, attempts: 3, correct: 3)
            .answered(wasCorrect: true, now: DateTime.now());
        // streak becomes 3 but let's test the pre-answer state separately
        expect(s.streak, 3);
        final low = const ReviewState(
            itemId: 'v', itemType: 'vocab', streak: 1, attempts: 1, correct: 1);
        expect(low.mastery, Mastery.familiar);
      });
      test('streak >=3 with accuracy >=60% -> mastered', () {
        final s = const ReviewState(
            itemId: 'v', itemType: 'vocab', streak: 2, attempts: 3, correct: 3);
        final after = s.answered(wasCorrect: true, now: DateTime.now());
        expect(after.mastery, Mastery.mastered);
      });
      test('streak >=3 with low accuracy stays familiar', () {
        final s = const ReviewState(
            itemId: 'v', itemType: 'vocab', streak: 2, attempts: 10, correct: 3);
        final after = s.answered(wasCorrect: true, now: DateTime.now());
        expect(after.streak, 3);
        expect(after.accuracy, lessThan(0.6));
        expect(after.mastery, Mastery.familiar);
      });
    });

    test('JSON round-trip', () {
      final s = const ReviewState(itemId: 'v', itemType: 'vocab')
          .answered(wasCorrect: true, now: DateTime(2026, 1, 1));
      final back = ReviewState.fromJson(s.toJson());
      expect(back.itemId, s.itemId);
      expect(back.streak, s.streak);
      expect(back.nextReviewOn, s.nextReviewOn);
    });
  });

  group('PlayerState leveling', () {
    test('level curve', () {
      expect(const PlayerState(xp: 0).level, 1);
      expect(const PlayerState(xp: 99).level, 1);
      expect(const PlayerState(xp: 100).level, 2);
      // level 2 needs 100 more (total 300)
      expect(const PlayerState(xp: 299).level, 2);
      expect(const PlayerState(xp: 300).level, 3);
    });

    test('xpIntoLevel', () {
      expect(const PlayerState(xp: 150).xpIntoLevel, 50);
    });
  });

  group('anti-farm rewards', () {
    test('first correct > replay reward', () {
      expect(Rewards.xpPerCorrectReplay, lessThan(Rewards.xpPerCorrectFirst));
      expect(Rewards.coinsPerCorrectReplay, lessThan(Rewards.coinsPerCorrectFirst));
      // a replay should be a token amount, not half
      expect(Rewards.xpPerCorrectReplay, lessThanOrEqualTo(Rewards.xpPerCorrectFirst ~/ 3));
    });

    test('quiz bonus scales with score', () {
      expect(Rewards.quizBonusXp(0, 10), 0);
      expect(Rewards.quizBonusXp(5, 10), 15);
      expect(Rewards.quizBonusXp(10, 10), Rewards.perfectQuizBonusXp);
    });

    test('level-up reward scales with level', () {
      expect(Rewards.levelUpRewardCoins(1), 10);
      expect(Rewards.levelUpRewardCoins(5), 50);
    });
  });

  group('Unlocks', () {
    final order = ['pre_a', 'pre_b', 'pre_c', 'pre_d'];
    test('first section always unlocked', () {
      final u = Unlocks.unlockedSections(order, {});
      expect(u, {'pre_a'});
    });

    test('passing 70% unlocks the next section', () {
      final u = Unlocks.unlockedSections(order, {
        'pre_a': const LessonProgressLite(
            completed: false, bestQuizScore: 4, bestQuizTotal: 5),
      });
      expect(u, {'pre_a', 'pre_b'});
    });

    test('failing the quiz keeps the next section locked', () {
      final u = Unlocks.unlockedSections(order, {
        'pre_a': const LessonProgressLite(
            completed: false, bestQuizScore: 3, bestQuizTotal: 5),
      });
      expect(u, {'pre_a'});
    });

    test('sequential chain', () {
      final u = Unlocks.unlockedSections(order, {
        'pre_a': const LessonProgressLite(completed: true, bestQuizScore: 5, bestQuizTotal: 5),
        'pre_b': const LessonProgressLite(completed: true, bestQuizScore: 5, bestQuizTotal: 5),
        'pre_c': const LessonProgressLite(completed: false, bestQuizScore: 0, bestQuizTotal: 0),
      });
      expect(u, {'pre_a', 'pre_b', 'pre_c'});
    });

    test('a gap breaks the chain', () {
      final u = Unlocks.unlockedSections(order, {
        'pre_a': const LessonProgressLite(completed: true, bestQuizScore: 5, bestQuizTotal: 5),
        'pre_b': const LessonProgressLite(completed: false, bestQuizScore: 0, bestQuizTotal: 0),
        'pre_c': const LessonProgressLite(completed: true, bestQuizScore: 5, bestQuizTotal: 5),
      });
      expect(u.contains('pre_d'), isFalse,
          reason: 'completing pre_c must not unlock pre_d while pre_b is locked');
    });
  });

  test('seededShuffleIndices is deterministic', () {
    final a = seededShuffleIndices(10, 42);
    final b = seededShuffleIndices(10, 42);
    expect(a, b);
    expect(a.toSet().length, 10, reason: 'permutation, no repeats');
  });
}

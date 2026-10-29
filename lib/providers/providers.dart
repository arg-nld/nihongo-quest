import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/rewards.dart';
import '../data/curriculum_repository.dart';
import '../data/progress_repository.dart';
import '../models/curriculum_models.dart';
import '../models/progress_models.dart';

/// Simple override-able provider for SharedPreferences (initialized in main).
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Override in ProviderScope');
});

final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  return SharedPreferencesProgressRepository(ref.watch(sharedPreferencesProvider));
});

final curriculumRepositoryProvider = Provider<CurriculumRepository>((ref) {
  return CurriculumRepository();
});

/// Ordered sections of the curriculum.
final sectionsProvider = FutureProvider<List<SectionX>>((ref) async {
  final repo = ref.watch(curriculumRepositoryProvider);
  final sections = await repo.loadSections();
  return sections.map(SectionX.new).toList();
});

/// Wrapper pairing a section with its optional lesson content.
class SectionX {
  SectionX(this.section);
  final Section section;
  Lesson? lesson;
}

/// The whole persisted progress document.
class ProgressController extends Notifier<ProgressData> {
  @override
  ProgressData build() {
    final repo = ref.watch(progressRepositoryProvider);
    // Load asynchronously once; initial state is empty.
    _load(repo);
    return const ProgressData();
  }

  Future<void> _load(ProgressRepository repo) async {
    final data = await repo.load();
    state = data;
  }

  Future<void> _persist() async {
    await ref.read(progressRepositoryProvider).save(state);
  }

  // ---- Player --------------------------------------------------------

  /// Adds XP/coins and returns any newly granted achievement IDs.
  List<String> addRewards({int xp = 0, int coins = 0}) {
    final player = state.player;
    final oldLevel = player.level;
    final newCoins = player.coins + coins;
    var unlocked = <String>[];
    var updated = player.copyWith(xp: player.xp + xp, coins: newCoins);
    // Level-up coin bonus.
    if (updated.level > oldLevel) {
      for (var lvl = oldLevel + 1; lvl <= updated.level; lvl++) {
        updated = updated.copyWith(coins: updated.coins + Rewards.levelUpRewardCoins(lvl));
      }
    }
    // Achievement: level milestones.
    final achievements = [...updated.achievements];
    void grant(String id) {
      if (!achievements.contains(id)) {
        achievements.add(id);
        unlocked.add(id);
      }
    }

    if (updated.level >= 5) grant('level_5');
    if (updated.level >= 10) grant('level_10');
    state = state.copyWith(player: updated.copyWith(achievements: achievements));
    _persist();
    return unlocked;
  }

  /// Records the daily quest completion (once per calendar day).
  bool completeDailyQuest() {
    final today = DateTime.now();
    final key =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    if (state.player.dailyQuestDate == key && state.player.dailyQuestDone) {
      return false;
    }
    // Set the quest flags first, then grant rewards on top of the updated
    // player so the XP/coins are not overwritten.
    state = state.copyWith(
        player: state.player.copyWith(dailyQuestDate: key, dailyQuestDone: true));
    addRewards(xp: 30, coins: 15);
    _persist();
    return true;
  }

  DailyQuest currentQuest({required int reviewsDone}) {
    const goal = 10;
    final today = DateTime.now();
    final key =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final done = state.player.dailyQuestDate == key && state.player.dailyQuestDone;
    return DailyQuest(
      id: 'daily_review_$key',
      title: 'Review $goal items today',
      goal: goal,
      progress: reviewsDone.clamp(0, goal),
      done: done || reviewsDone >= goal,
    );
  }

  void setDisplayName(String name) {
    state = state.copyWith(player: state.player.copyWith(displayName: name));
    _persist();
  }

  void setAvatar(String avatar) {
    state = state.copyWith(player: state.player.copyWith(avatar: avatar));
    _persist();
  }

  // ---- Settings ------------------------------------------------------

  void updateSettings(AppSettings Function(AppSettings) updater) {
    state = state.copyWith(settings: updater(state.settings));
    _persist();
  }


  // ---- Shop and boss upgrades ---------------------------------------

  /// Purchase a repeatable item that will be consumed by a future battle.
  bool purchaseInventoryItem({required String itemId, required int cost}) {
    if (cost < 0 || state.player.coins < cost) return false;
    final inventory = {...state.inventory};
    inventory[itemId] = (inventory[itemId] ?? 0) + 1;
    state = state.copyWith(
      player: state.player.copyWith(coins: state.player.coins - cost),
      inventory: inventory,
    );
    _persist();
    return true;
  }

  /// Purchase a permanent upgrade. The caller supplies the rank cap shown in
  /// the shop; the state layer checks the cap again before spending coins.
  bool purchasePermanentUpgrade({
    required String upgradeId,
    required int cost,
    required int maxRank,
  }) {
    final currentRank = state.upgrades[upgradeId] ?? 0;
    if (cost < 0 || state.player.coins < cost || currentRank >= maxRank) {
      return false;
    }
    state = state.copyWith(
      player: state.player.copyWith(coins: state.player.coins - cost),
      upgrades: {...state.upgrades, upgradeId: currentRank + 1},
    );
    _persist();
    return true;
  }

  /// Consume one item from inventory. Returns false when none are available.
  bool consumeInventoryItem(String itemId) {
    final count = state.inventory[itemId] ?? 0;
    if (count <= 0) return false;
    final inventory = {...state.inventory};
    if (count == 1) {
      inventory.remove(itemId);
    } else {
      inventory[itemId] = count - 1;
    }
    state = state.copyWith(inventory: inventory);
    _persist();
    return true;
  }

  // ---- Lessons -------------------------------------------------------

  /// Records one scored exercise result for [sectionId]. [firstTime] means the
  /// exercise ID was answered correctly for the first time ever.
  void recordExercise({
    required String sectionId,
    required bool correct,
    required bool firstTime,
    required bool isReview,
    String? vocabId,
  }) {
    // The Reference Library is browse-only; never score or schedule its items.
    if (sectionId == 'reference') return;
    // XP/coins.
    if (correct) {
      if (isReview) {
        addRewards(xp: Rewards.xpPerReviewCorrect, coins: Rewards.coinsPerReviewCorrect);
      } else if (firstTime) {
        addRewards(xp: Rewards.xpPerCorrectFirst, coins: Rewards.coinsPerCorrectFirst);
      } else {
        addRewards(xp: Rewards.xpPerCorrectReplay, coins: Rewards.coinsPerCorrectReplay);
      }
    }
    // Vocabulary review state.
    if (vocabId != null) {
      recordReview(itemId: vocabId, itemType: 'vocab', wasCorrect: correct);
    }
  }

  /// Persist completion of one ordinary or mastery-review node.
  void completeStage(String stageId) {
    if (stageId.isEmpty || state.completedStageIds.contains(stageId)) return;
    state = state.copyWith(
      completedStageIds: {...state.completedStageIds, stageId},
    );
    _persist();
  }

  /// A boss victory clears its curriculum section and unlocks the next section.
  /// Boss progress is separate from quiz score so defeating the boss is the
  /// sole completion condition in the staged learning path.
  List<String> recordBossVictory(String sectionId) {
    if (sectionId == 'reference') return const [];
    final existing = state.lessons[sectionId] ?? LessonProgress(sectionId: sectionId);
    final now = DateTime.now().millisecondsSinceEpoch;
    state = state.copyWith(
      lessons: {
        ...state.lessons,
        sectionId: existing.copyWith(
          completed: true,
          attempts: existing.attempts + 1,
          lastCompletedOn: existing.lastCompletedOn ?? now,
        ),
      },
    );
    var unlocked = <String>[];
    if (!existing.completed) {
      unlocked.addAll(addRewards(
        xp: Rewards.lessonCompleteXp,
        coins: Rewards.lessonCompleteCoins,
      ));
    }
    _persist();
    return unlocked;
  }

  /// Records a lesson quiz submission and marks the lesson complete when
  /// passed. Returns newly granted achievement IDs. Kept for legacy quizzes.
  List<String> recordQuizResult(String sectionId, int score, int total) {
    // Guard at the progress boundary as well as hiding the start button in UI.
    if (sectionId == 'reference') return const [];
    final existing = state.lessons[sectionId] ?? LessonProgress(sectionId: sectionId);
    final improved = score > existing.bestQuizScore;
    final passed = total > 0 && score / total >= Unlocks.passFraction;
    var progress = existing.copyWith(
      attempts: existing.attempts + 1,
      bestQuizScore: improved ? score : existing.bestQuizScore,
      bestQuizTotal: improved ? total : existing.bestQuizTotal,
      completed: existing.completed || passed,
      lastCompletedOn:
          passed && !existing.completed ? DateTime.now().millisecondsSinceEpoch : null,
    );
    state = state.copyWith(lessons: {...state.lessons, sectionId: progress});
    var unlocked = <String>[];
    if (passed && !existing.completed) {
      unlocked.addAll(addRewards(
          xp: Rewards.lessonCompleteXp + Rewards.quizBonusXp(score, total),
          coins: Rewards.lessonCompleteCoins));
      final achievements = [...state.player.achievements];
      void grant(String id) {
        if (!achievements.contains(id)) achievements.add(id);
      }

      if (score == total && total >= 5) grant('perfect_quiz');
      state = state.copyWith(player: state.player.copyWith(achievements: achievements));
    }
    _persist();
    return unlocked;
  }

  /// Records a Cumulative Review (cumulative checkpoint) run. Checkpoints are
  /// optional: they never gate progression and pay no lesson rewards — the
  /// per-exercise review rewards already accrued during the session. The
  /// first passed challenge grants a one-time achievement.
  List<String> recordCheckpointResult(int score, int total) {
    final passed = total > 0 && score / total >= Unlocks.passFraction;
    if (!passed) return const [];
    if (state.player.achievements.contains('checkpoint_clear')) return const [];
    final achievements = [...state.player.achievements, 'checkpoint_clear'];
    state = state.copyWith(player: state.player.copyWith(achievements: achievements));
    _persist();
    return const ['checkpoint_clear'];
  }

  // ---- Reviews (SRS) -------------------------------------------------

  void recordReview({
    required String itemId,
    required String itemType,
    required bool wasCorrect,
  }) {
    // Defend the SRS boundary by ID as well; callers cannot schedule lookup-only terms.
    if (itemId.startsWith('reference_v_')) return;
    final existing = state.reviews[itemId] ?? ReviewState(itemId: itemId, itemType: itemType);
    final updated = existing.answered(wasCorrect: wasCorrect, now: DateTime.now());
    state = state.copyWith(reviews: {...state.reviews, itemId: updated});
    _persist();
  }

  /// Unlocks a lesson's vocabulary into the review system (no scheduling yet —
  /// it becomes due immediately so it appears in Review Today).
  void registerVocab(List<String> vocabIds, {String? sectionId}) {
    // Callers identify the source section so browse-only reference terms cannot
    // accidentally enter spaced repetition.
    if (sectionId == 'reference') return;
    final reviews = {...state.reviews};
    for (final id in vocabIds) {
      if (id.startsWith('reference_v_')) continue;
      reviews.putIfAbsent(
          id, () => ReviewState(itemId: id, itemType: 'vocab', nextReviewOn: null));
    }
    state = state.copyWith(reviews: reviews);
    _persist();
  }

  /// Due review item IDs, weakest and most overdue first.
  List<String> dueReviewIds() {
    final due = state.reviews.values.where((r) => r.isDue).toList()
      ..sort((a, b) {
        // Never-reviewed first, then lowest streak, then lowest accuracy.
        final aNever = a.nextReviewOn == null ? 0 : 1;
        final bNever = b.nextReviewOn == null ? 0 : 1;
        if (aNever != bNever) return aNever - bNever;
        if (a.streak != b.streak) return a.streak - b.streak;
        return a.accuracy.compareTo(b.accuracy);
      });
    return due.map((r) => r.itemId).toList();
  }
}

final progressProvider = NotifierProvider<ProgressController, ProgressData>(
  ProgressController.new,
);

/// Derived: map of sectionId -> LessonProgress.
final lessonProgressProvider = Provider<Map<String, LessonProgress>>((ref) {
  return ref.watch(progressProvider).lessons;
});

/// Derived: unlocked section IDs in curriculum order.
final unlockedSectionsProvider = FutureProvider<Set<String>>((ref) async {
  final sections = await ref.watch(sectionsProvider.future);
  final progress = ref.watch(lessonProgressProvider);
  final ordered = sections.map((s) => s.section.id).toList();
  final lite = progress.map((k, v) => MapEntry(
      k, LessonProgressLite(completed: v.completed, bestQuizScore: v.bestQuizScore, bestQuizTotal: v.bestQuizTotal)));
  return Unlocks.unlockedSections(ordered, lite);
});

/// Derived: the next section to study (first unlocked, incomplete one).
final nextSectionProvider = FutureProvider<String?>((ref) async {
  final sections = await ref.watch(sectionsProvider.future);
  final unlocked = await ref.watch(unlockedSectionsProvider.future);
  for (final s in sections) {
    final id = s.section.id;
    if (s.section.type == 'reference') continue;
    if (unlocked.contains(id) && !(ref.read(lessonProgressProvider)[id]?.completed ?? false)) {
      return id;
    }
  }
  return null;
});

/// Derived: display details for the next section (title/subtitle), so screens
/// never have to show a raw section id to the learner.
final nextSectionDetailsProvider =
    FutureProvider<({String id, String title, String subtitle})?>((ref) async {
  final id = await ref.watch(nextSectionProvider.future);
  if (id == null) return null;
  final sections = await ref.watch(sectionsProvider.future);
  final section = sections.map((x) => x.section).firstWhere((s) => s.id == id);
  return (id: id, title: section.title, subtitle: section.subtitle);
});

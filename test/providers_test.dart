import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_quest/core/rewards.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nihongo_quest/data/curriculum_repository.dart';
import 'package:nihongo_quest/data/progress_repository.dart';
import 'package:nihongo_quest/models/curriculum_models.dart';
import 'package:nihongo_quest/models/progress_models.dart';
import 'package:nihongo_quest/providers/providers.dart';

/// Curriculum stub for provider tests: a tiny ordered spine with a trailing
/// reference section, so tests can assert reference-only behavior without
/// touching the real asset bundle.
class _FakeCurriculumRepo extends CurriculumRepository {
  List<Section> makeSections(int order) => [
        Section(
            id: 'pre_a',
            order: order++,
            title: 'Pre-Lesson A',
            subtitle: '',
            type: 'pre_lesson',
            area: 'Test',
            pages: '1-2',
            contentFile: 'pre_a.json'),
        Section(
            id: 'lesson_01',
            order: order++,
            title: 'Lesson 1',
            subtitle: '',
            type: 'lesson',
            area: 'Test',
            pages: '3-4',
            contentFile: 'lesson_01.json'),
        Section(
            id: 'reference',
            order: order,
            title: 'Reference Library',
            subtitle: '',
            type: 'reference',
            area: 'Test',
            pages: '5-6',
            contentFile: 'reference.json'),
      ];

  @override
  Future<List<Section>> loadSections() async => makeSections(1);

  @override
  Future<Lesson?> loadLesson(String sectionId) async => null;
}

void main() {
  late InMemoryProgressRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = InMemoryProgressRepository();
    container = ProviderContainer(overrides: [
      progressRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);
  });

  ProgressController controller() => container.read(progressProvider.notifier);

  group('addRewards', () {
    test('adds xp and coins', () {
      controller().addRewards(xp: 50, coins: 10);
      final p = container.read(progressProvider).player;
      expect(p.xp, 50);
      expect(p.coins, 10);
    });

    test('level up grants coin bonus and milestone achievements', () {
      // 100 xp -> level 2 -> +20 coins; level 5 needs 100+200+300+400=1000.
      final unlocked = controller().addRewards(xp: 1000);
      final p = container.read(progressProvider).player;
      expect(p.level, 5);
      // coins: level-up bonuses 10*2 + 10*3 + 10*4 + 10*5 = 140
      expect(p.coins, 140);
      expect(p.achievements, contains('level_5'));
      expect(unlocked, contains('level_5'));
    });

    test('achievements are granted once', () {
      controller().addRewards(xp: 1000);
      controller().addRewards(xp: 0);
      expect(
          container.read(progressProvider).player.achievements.where((a) => a == 'level_5'),
          hasLength(1));
    });
  });

  group('anti-farm: exercise rewards', () {
    test('first correct grants full rewards, replay grants token rewards', () {
      controller().recordExercise(
          sectionId: 'lesson_01', correct: true, firstTime: true, isReview: false);
      final p1 = container.read(progressProvider).player;
      expect(p1.xp, Rewards.xpPerCorrectFirst);
      expect(p1.coins, Rewards.coinsPerCorrectFirst);

      // Same exercise answered correctly again (replay): token rewards only.
      controller().recordExercise(
          sectionId: 'lesson_01', correct: true, firstTime: false, isReview: false);
      final p2 = container.read(progressProvider).player;
      expect(p2.xp, Rewards.xpPerCorrectFirst + Rewards.xpPerCorrectReplay);
      expect(p2.coins, Rewards.coinsPerCorrectFirst + Rewards.coinsPerCorrectReplay);

      // 100 replays cannot outweigh a first-time answer.
      for (var i = 0; i < 100; i++) {
        controller().recordExercise(
            sectionId: 'lesson_01', correct: true, firstTime: false, isReview: false);
      }
      final p3 = container.read(progressProvider).player;
      expect(p3.xp, Rewards.xpPerCorrectFirst + 101 * Rewards.xpPerCorrectReplay);
      expect(p3.xp, lessThan(500));
    });

    test('wrong answers grant nothing', () {
      controller().recordExercise(
          sectionId: 'lesson_01', correct: false, firstTime: true, isReview: false);
      final p = container.read(progressProvider).player;
      expect(p.xp, 0);
      expect(p.coins, 0);
    });

    test('review rewards differ from lesson rewards', () {
      controller().recordExercise(
          sectionId: 'lesson_01',
          correct: true,
          firstTime: true,
          isReview: true,
          vocabId: 'lesson_01_v_hai');
      final p = container.read(progressProvider).player;
      expect(p.xp, Rewards.xpPerReviewCorrect);
      // and the vocab review state was recorded
      expect(container.read(progressProvider).reviews['lesson_01_v_hai'], isNotNull);
    });
  });

  group('quiz recording', () {
    test('passing marks complete and grants lesson rewards once', () {
      final unlocked1 = controller().recordQuizResult('lesson_01', 5, 5);
      final p1 = container.read(progressProvider).player;
      expect(p1.xp, Rewards.lessonCompleteXp + Rewards.quizBonusXp(5, 5));
      expect(container.read(progressProvider).lessons['lesson_01']!.completed, isTrue);
      expect(unlocked1, contains('perfect_quiz'));

      // Replaying the same perfect quiz grants no new lesson rewards.
      controller().recordQuizResult('lesson_01', 5, 5);
      final p2 = container.read(progressProvider).player;
      expect(p2.xp, p1.xp, reason: 'no double reward for an already-completed lesson');
    });

    test('failing does not complete the lesson', () {
      controller().recordQuizResult('lesson_01', 3, 5);
      final lp = container.read(progressProvider).lessons['lesson_01']!;
      expect(lp.completed, isFalse);
      expect(lp.attempts, 1);
      expect(container.read(progressProvider).player.xp, 0);
    });

    test('best score is kept across attempts', () {
      controller().recordQuizResult('lesson_01', 4, 5);
      controller().recordQuizResult('lesson_01', 2, 5);
      final lp = container.read(progressProvider).lessons['lesson_01']!;
      expect(lp.bestQuizScore, 4);
      expect(lp.bestQuizTotal, 5);
      expect(lp.completed, isTrue); // 4/5 = 80% >= 70%
    });
  });

  group('boss challenge (checkpoint)', () {
    test('passing grants the achievement exactly once', () {
      final u1 = controller().recordCheckpointResult(10, 12);
      expect(u1, ['checkpoint_clear']);
      final u2 = controller().recordCheckpointResult(12, 12);
      expect(u2, isEmpty, reason: 'already earned — no repeat grant');
      expect(
          container.read(progressProvider).player.achievements,
          contains('checkpoint_clear'));
    });

    test('passing never marks a lesson complete or gates progress', () {
      controller().recordCheckpointResult(12, 12);
      final lessons = container.read(progressProvider).lessons;
      expect(lessons['checkpoint'], isNull,
          reason: 'checkpoints are not lessons');
      expect(lessons, isEmpty, reason: 'a checkpoint must not touch lesson state');
    });

    test('failing grants nothing', () {
      expect(controller().recordCheckpointResult(7, 12), isEmpty); // 58% < 70%
      expect(container.read(progressProvider).player.achievements,
          isNot(contains('checkpoint_clear')));
    });
  });

  test('next-up never points at the Reference Library (reference-only)',
      () async {
    final fake = _FakeCurriculumRepo();
    final c = ProviderContainer(overrides: [
      progressRepositoryProvider.overrideWithValue(repo),
      curriculumRepositoryProvider.overrideWithValue(fake),
    ]);
    addTearDown(c.dispose);
    // Let the controller's initial async load settle so it cannot wipe the
    // quiz results below.
    await Future<void>.delayed(Duration.zero);
    final cp = c.read(progressProvider.notifier);
    cp.recordQuizResult('pre_a', 5, 5);
    cp.recordQuizResult('lesson_01', 5, 5);
    final next = await c.read(nextSectionProvider.future);
    expect(next, isNull,
        reason: 'with every sequential section complete, next-up must end — '
            'never fall through to the reference section');
  });

  group('daily quest', () {
    test('grants rewards once per day', () {
      expect(controller().completeDailyQuest(), isTrue);
      final p1 = container.read(progressProvider).player;
      expect(p1.xp, 30);
      expect(p1.coins, 15);
      expect(p1.dailyQuestDone, isTrue);

      // Same day: denied, no extra rewards.
      expect(controller().completeDailyQuest(), isFalse);
      final p2 = container.read(progressProvider).player;
      expect(p2.xp, 30);
      expect(p2.coins, 15);
    });

    test('currentQuest reflects state', () {
      final q = controller().currentQuest(reviewsDone: 3);
      expect(q.goal, 10);
      expect(q.progress, 3);
      expect(q.done, isFalse);
      final done = controller().currentQuest(reviewsDone: 12);
      expect(done.progress, 10);
      expect(done.done, isTrue);
    });
  });

  test('Reference Library cannot affect scores, progression, or reviews', () {
    controller().recordExercise(
      sectionId: 'reference',
      correct: true,
      firstTime: true,
      isReview: false,
      vocabId: 'reference_v_ohayou_gozaimasu',
    );
    final unlocked = controller().recordQuizResult('reference', 5, 5);
    controller().registerVocab(
      ['reference_v_ohayou_gozaimasu'],
      sectionId: 'reference',
    );
    // The ID guard also protects the SRS if a caller omits the section ID.
    controller().registerVocab(['reference_v_ohayou_gozaimasu']);
    controller().recordReview(
      itemId: 'reference_v_ohayou_gozaimasu',
      itemType: 'vocab',
      wasCorrect: true,
    );

    final progress = container.read(progressProvider);
    expect(unlocked, isEmpty);
    expect(progress.player.xp, 0);
    expect(progress.player.coins, 0);
    expect(progress.lessons, isEmpty);
    expect(progress.reviews, isEmpty);
  });

  group('reviews / SRS through the controller', () {
    test('registerVocab makes items due immediately', () {
      controller().registerVocab(['lesson_01_v_hai', 'lesson_01_v_iie']);
      final due = controller().dueReviewIds();
      expect(due, containsAll(['lesson_01_v_hai', 'lesson_01_v_iie']));
      // registerVocab is idempotent and does not reset progress
      controller().recordReview(itemId: 'lesson_01_v_hai', itemType: 'vocab', wasCorrect: true);
      controller().registerVocab(['lesson_01_v_hai']);
      final rs = container.read(progressProvider).reviews['lesson_01_v_hai']!;
      expect(rs.streak, 1, reason: 're-registering must not wipe review state');
    });

    test('dueReviewIds orders never-reviewed first, then weakest streak', () {
      // Review two items today (both due in future), register a third fresh.
      controller().registerVocab(['a', 'b', 'c']);
      controller().recordReview(itemId: 'b', itemType: 'vocab', wasCorrect: true);
      controller().recordReview(itemId: 'b', itemType: 'vocab', wasCorrect: true);
      final due = controller().dueReviewIds();
      // 'b' has been answered, so it is scheduled in the future and not due.
      expect(due, isNot(contains('b')), reason: 'b is scheduled in the future');
      // Never-reviewed items come first; 'a' and 'c' tie on every sort key,
      // so assert the contract rather than a specific tie-break winner.
      expect(due, isNotEmpty);
      expect(due.first, anyOf('a', 'c'),
          reason: 'a never-reviewed item is due first');
      expect(due.toSet(), {'a', 'c'});
    });
  });

  group('staged lesson progression', () {
    test('stages persist and boss victory completes the section', () async {
      controller().completeStage('pre_a_stage_1');
      expect(container.read(progressProvider).completedStageIds,
          contains('pre_a_stage_1'));

      controller().recordBossVictory('pre_a');
      final progress = container.read(progressProvider);
      expect(progress.lessons['pre_a']?.completed, isTrue);
      expect(progress.completedStageIds, contains('pre_a_stage_1'));
      expect(progress.lessons['pre_a']?.lastCompletedOn, isNotNull);

      final loaded = await repo.load();
      expect(loaded.completedStageIds, contains('pre_a_stage_1'));
      expect(loaded.lessons['pre_a']?.completed, isTrue);
    });

    test('old saves without stage ids remain compatible', () {
      final oldSave = ProgressData.fromJson({
        'player': {'xp': 15},
        'settings': {'showRomaji': true},
        'lessons': <String, dynamic>{},
        'reviews': <String, dynamic>{},
      });
      expect(oldSave.completedStageIds, isEmpty);
      expect(oldSave.player.xp, 15);
    });
  });

  group('persistence', () {
    test('progress survives a repository round-trip', () async {
      controller().addRewards(xp: 120, coins: 5);
      controller().registerVocab(['v1']);
      controller().recordReview(itemId: 'v1', itemType: 'vocab', wasCorrect: true);

      // Simulate app restart: load from the same repo.
      final loaded = await repo.load();
      expect(loaded.player.xp, 120);
      expect(loaded.reviews['v1']!.streak, 1);
    });

    test('corrupted save data starts fresh instead of crashing', () async {
      SharedPreferences.setMockInitialValues(
          {'nihongo_quest_progress_v1': '{not json'});
      final sp = await SharedPreferences.getInstance();
      final r = SharedPreferencesProgressRepository(sp);
      final d = await r.load();
      expect(d.player.xp, 0, reason: 'corrupt save -> fresh start');
    });

    test('ProgressData JSON round-trip', () {
      const data = ProgressData(
        player: PlayerState(xp: 55, coins: 7, displayName: 'Traveler'),
        completedStageIds: {'pre_a_stage_1', 'pre_a_stage_2'},
        inventory: {'extra_heart': 2},
        upgrades: {'timer_crystal': 3, 'power_rune': 1},
      );
      final back = ProgressData.fromJson(data.toJson());
      expect(back.player.xp, 55);
      expect(back.player.coins, 7);
      expect(back.player.displayName, 'Traveler');
      expect(back.settings.showRomaji, isTrue, reason: 'defaults preserved');
      expect(back.completedStageIds, {'pre_a_stage_1', 'pre_a_stage_2'});
      expect(back.inventory['extra_heart'], 2);
      expect(back.upgrades['timer_crystal'], 3);
      expect(back.upgrades['power_rune'], 1);
    });
  });

  group('shop upgrades', () {
    test('repeatable extra-heart items debit coins and can be consumed once', () {
      controller().addRewards(coins: 100);
      expect(controller().purchaseInventoryItem(itemId: 'extra_heart', cost: 40), isTrue);
      expect(container.read(progressProvider).player.coins, 60);
      expect(container.read(progressProvider).inventory['extra_heart'], 1);
      expect(controller().consumeInventoryItem('extra_heart'), isTrue);
      expect(container.read(progressProvider).inventory.containsKey('extra_heart'), isFalse);
      expect(controller().consumeInventoryItem('extra_heart'), isFalse);
    });

    test('permanent upgrades are rank-limited and persist in progress data', () {
      controller().addRewards(coins: 200);
      expect(controller().purchasePermanentUpgrade(
        upgradeId: 'timer_crystal', cost: 60, maxRank: 2), isTrue);
      expect(controller().purchasePermanentUpgrade(
        upgradeId: 'timer_crystal', cost: 60, maxRank: 2), isTrue);
      expect(controller().purchasePermanentUpgrade(
        upgradeId: 'timer_crystal', cost: 60, maxRank: 2), isFalse);
      final saved = ProgressData.fromJson(container.read(progressProvider).toJson());
      expect(saved.upgrades['timer_crystal'], 2);
      expect(saved.player.coins, 80);
    });
  });

  group('settings', () {
    test('updateSettings toggles romaji visibility', () {
      expect(container.read(progressProvider).settings.showRomaji, isTrue);
      controller().updateSettings((s) => s.copyWith(showRomaji: false));
      expect(container.read(progressProvider).settings.showRomaji, isFalse);
    });
  });
}

import 'package:flutter/foundation.dart';

/// Player progress models. Serialized to JSON and persisted via
/// [ProgressRepository] (see lib/data/progress_repository.dart).

/// Per-lesson progress.
@immutable
class LessonProgress {
  const LessonProgress({
    required this.sectionId,
    this.completed = false,
    this.bestQuizScore = 0,
    this.bestQuizTotal = 0,
    this.attempts = 0,
    this.lastCompletedOn,
  });

  final String sectionId;
  final bool completed;
  final int bestQuizScore;
  final int bestQuizTotal;
  final int attempts;

  /// Milliseconds since epoch; null while never completed.
  final int? lastCompletedOn;

  LessonProgress copyWith({
    bool? completed,
    int? bestQuizScore,
    int? bestQuizTotal,
    int? attempts,
    int? lastCompletedOn,
    bool clearLastCompletedOn = false,
  }) =>
      LessonProgress(
        sectionId: sectionId,
        completed: completed ?? this.completed,
        bestQuizScore: bestQuizScore ?? this.bestQuizScore,
        bestQuizTotal: bestQuizTotal ?? this.bestQuizTotal,
        attempts: attempts ?? this.attempts,
        lastCompletedOn: clearLastCompletedOn
            ? null
            : (lastCompletedOn ?? this.lastCompletedOn),
      );

  static LessonProgress fromJson(Map<String, dynamic> j) => LessonProgress(
        sectionId: j['sectionId'] as String,
        completed: (j['completed'] ?? false) as bool,
        bestQuizScore: (j['bestQuizScore'] ?? 0) as int,
        bestQuizTotal: (j['bestQuizTotal'] ?? 0) as int,
        attempts: (j['attempts'] ?? 0) as int,
        lastCompletedOn: j['lastCompletedOn'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'sectionId': sectionId,
        'completed': completed,
        'bestQuizScore': bestQuizScore,
        'bestQuizTotal': bestQuizTotal,
        'attempts': attempts,
        'lastCompletedOn': lastCompletedOn,
      };
}

/// Mastery tiers for vocabulary / skills.
enum Mastery { new_, learning, familiar, mastered }

/// Spaced-repetition state for one vocabulary item (or skill).
///
/// Algorithm (documented in README "How progress and spaced repetition work"):
///  - Correct recall advances [streak] and schedules the next review at
///    `intervals[streak]` days (1, 3, 7, 14, 30, 90).
///  - A miss resets [streak] to 0 and schedules a same-day review.
///  - Mastery transitions: streak 0 → new/learning, 1–2 → familiar,
///    ≥3 with accuracy ≥ 60% → mastered. One correct answer never masters.
@immutable
class ReviewState {
  const ReviewState({
    required this.itemId,
    required this.itemType, // 'vocab' | 'skill'
    this.attempts = 0,
    this.correct = 0,
    this.streak = 0,
    this.lastReviewOn,
    this.nextReviewOn,
  });

  static const List<int> intervals = [1, 3, 7, 14, 30, 90];

  final String itemId;
  final String itemType;
  final int attempts;
  final int correct;
  final int streak;

  /// Milliseconds since epoch (day precision).
  final int? lastReviewOn;
  final int? nextReviewOn;

  double get accuracy => attempts == 0 ? 0 : correct / attempts;
  bool get isDue {
    if (nextReviewOn == null) return true; // never reviewed
    final now = DateTime.now();
    final due = DateTime.fromMillisecondsSinceEpoch(nextReviewOn!);
    return !due.isAfter(DateTime(now.year, now.month, now.day));
  }

  Mastery get mastery {
    if (attempts == 0) return Mastery.new_;
    if (streak >= 3 && accuracy >= 0.6) return Mastery.mastered;
    if (streak >= 1) return Mastery.familiar;
    return Mastery.learning;
  }

  /// Returns the updated state after answering.
  ReviewState answered({required bool wasCorrect, required DateTime now}) {
    final day = DateTime(now.year, now.month, now.day);
    final newStreak = wasCorrect ? streak + 1 : 0;
    final idx = (newStreak - 1).clamp(0, intervals.length - 1);
    final next = wasCorrect
        ? day.add(Duration(days: intervals[idx]))
        : day.add(const Duration(hours: 4)); // same-session retry today
    return ReviewState(
      itemId: itemId,
      itemType: itemType,
      attempts: attempts + 1,
      correct: correct + (wasCorrect ? 1 : 0),
      streak: newStreak,
      lastReviewOn: day.millisecondsSinceEpoch,
      nextReviewOn: next.millisecondsSinceEpoch,
    );
  }

  ReviewState copyWith({int? streak, int? nextReviewOn}) => ReviewState(
        itemId: itemId,
        itemType: itemType,
        attempts: attempts,
        correct: correct,
        streak: streak ?? this.streak,
        lastReviewOn: lastReviewOn,
        nextReviewOn: nextReviewOn ?? this.nextReviewOn,
      );

  static ReviewState fromJson(Map<String, dynamic> j) => ReviewState(
        itemId: j['itemId'] as String,
        itemType: (j['itemType'] ?? 'vocab') as String,
        attempts: (j['attempts'] ?? 0) as int,
        correct: (j['correct'] ?? 0) as int,
        streak: (j['streak'] ?? 0) as int,
        lastReviewOn: j['lastReviewOn'] as int?,
        nextReviewOn: j['nextReviewOn'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'itemId': itemId,
        'itemType': itemType,
        'attempts': attempts,
        'correct': correct,
        'streak': streak,
        'lastReviewOn': lastReviewOn,
        'nextReviewOn': nextReviewOn,
      };
}

/// Player profile: XP, level, coins, achievements.
@immutable
class PlayerState {
  const PlayerState({
    this.xp = 0,
    this.coins = 0,
    this.achievements = const [],
    this.dailyQuestDate,
    this.dailyQuestDone = false,
    this.displayName = 'Traveler',
    this.avatar = 'tanuki',
  });

  /// XP needed to reach the next level grows linearly: level n needs 100 * n.
  static int xpForLevel(int level) => 100 * level;

  final int xp;
  final int coins;
  final List<String> achievements;
  final String? dailyQuestDate; // yyyy-MM-dd the current quest belongs to
  final bool dailyQuestDone;
  final String displayName;
  final String avatar;

  int get level {
    var lvl = 1;
    var remaining = xp;
    while (remaining >= xpForLevel(lvl)) {
      remaining -= xpForLevel(lvl);
      lvl++;
    }
    return lvl;
  }

  int get xpIntoLevel {
    var remaining = xp;
    var lvl = 1;
    while (remaining >= xpForLevel(lvl)) {
      remaining -= xpForLevel(lvl);
      lvl++;
    }
    return remaining;
  }

  PlayerState copyWith({
    int? xp,
    int? coins,
    List<String>? achievements,
    String? dailyQuestDate,
    bool? dailyQuestDone,
    String? displayName,
    String? avatar,
  }) =>
      PlayerState(
        xp: xp ?? this.xp,
        coins: coins ?? this.coins,
        achievements: achievements ?? this.achievements,
        dailyQuestDate: dailyQuestDate ?? this.dailyQuestDate,
        dailyQuestDone: dailyQuestDone ?? this.dailyQuestDone,
        displayName: displayName ?? this.displayName,
        avatar: avatar ?? this.avatar,
      );

  static PlayerState fromJson(Map<String, dynamic> j) => PlayerState(
        xp: (j['xp'] ?? 0) as int,
        coins: (j['coins'] ?? 0) as int,
        achievements: (j['achievements'] as List<dynamic>? ?? const [])
            .map((e) => e as String)
            .toList(),
        dailyQuestDate: j['dailyQuestDate'] as String?,
        dailyQuestDone: (j['dailyQuestDone'] ?? false) as bool,
        displayName: (j['displayName'] ?? 'Traveler') as String,
        avatar: (j['avatar'] ?? 'tanuki') as String,
      );

  Map<String, dynamic> toJson() => {
        'xp': xp,
        'coins': coins,
        'achievements': achievements,
        'dailyQuestDate': dailyQuestDate,
        'dailyQuestDone': dailyQuestDone,
        'displayName': displayName,
        'avatar': avatar,
      };
}

/// App settings.
@immutable
class AppSettings {
  const AppSettings({
    this.showRomaji = true,
    this.immediateFeedback = true,
    this.dailyReviewGoal = 15,
  });

  final bool showRomaji;
  final bool immediateFeedback; // learning mode vs. exam-style delayed feedback
  final int dailyReviewGoal;

  AppSettings copyWith({
    bool? showRomaji,
    bool? immediateFeedback,
    int? dailyReviewGoal,
  }) =>
      AppSettings(
        showRomaji: showRomaji ?? this.showRomaji,
        immediateFeedback: immediateFeedback ?? this.immediateFeedback,
        dailyReviewGoal: dailyReviewGoal ?? this.dailyReviewGoal,
      );

  static AppSettings fromJson(Map<String, dynamic> j) => AppSettings(
        showRomaji: (j['showRomaji'] ?? true) as bool,
        immediateFeedback: (j['immediateFeedback'] ?? true) as bool,
        dailyReviewGoal: (j['dailyReviewGoal'] ?? 15) as int,
      );

  Map<String, dynamic> toJson() => {
        'showRomaji': showRomaji,
        'immediateFeedback': immediateFeedback,
        'dailyReviewGoal': dailyReviewGoal,
      };
}

/// The full persisted progress document.
@immutable
class ProgressData {
  const ProgressData({
    this.player = const PlayerState(),
    this.settings = const AppSettings(),
    this.lessons = const {},
    this.reviews = const {},
    this.completedStageIds = const {},
    this.inventory = const {},
    this.upgrades = const {},
  });

  final PlayerState player;
  final AppSettings settings;
  final Map<String, LessonProgress> lessons;
  final Map<String, ReviewState> reviews;

  /// Persistent per-node completion for the multi-stage lesson path.
  /// Missing values in older saves safely default to an empty set.
  final Set<String> completedStageIds;

  /// Repeatable battle consumables. Counts are decremented when a battle starts.
  final Map<String, int> inventory;

  /// Permanent shop upgrade ranks, stored by upgrade ID.
  final Map<String, int> upgrades;

  ProgressData copyWith({
    PlayerState? player,
    AppSettings? settings,
    Map<String, LessonProgress>? lessons,
    Map<String, ReviewState>? reviews,
    Set<String>? completedStageIds,
    Map<String, int>? inventory,
    Map<String, int>? upgrades,
  }) =>
      ProgressData(
        player: player ?? this.player,
        settings: settings ?? this.settings,
        lessons: lessons ?? this.lessons,
        reviews: reviews ?? this.reviews,
        completedStageIds: completedStageIds ?? this.completedStageIds,
        inventory: inventory ?? this.inventory,
        upgrades: upgrades ?? this.upgrades,
      );

  static ProgressData fromJson(Map<String, dynamic> j) => ProgressData(
        player: PlayerState.fromJson((j['player'] ?? const {}) as Map<String, dynamic>),
        settings: AppSettings.fromJson((j['settings'] ?? const {}) as Map<String, dynamic>),
        lessons: (j['lessons'] as Map<String, dynamic>? ?? const {}).map(
          (k, v) => MapEntry(k, LessonProgress.fromJson(v as Map<String, dynamic>)),
        ),
        reviews: (j['reviews'] as Map<String, dynamic>? ?? const {}).map(
          (k, v) => MapEntry(k, ReviewState.fromJson(v as Map<String, dynamic>)),
        ),
        completedStageIds: (j['completedStageIds'] as List<dynamic>? ?? const [])
            .whereType<String>()
            .toSet(),
        inventory: (j['inventory'] as Map<String, dynamic>? ?? const {}).map(
          (k, v) => MapEntry(k, (v as num).toInt()),
        ),
        upgrades: (j['upgrades'] as Map<String, dynamic>? ?? const {}).map(
          (k, v) => MapEntry(k, (v as num).toInt()),
        ),
      );

  Map<String, dynamic> toJson() => {
        'player': player.toJson(),
        'settings': settings.toJson(),
        'lessons': lessons.map((k, v) => MapEntry(k, v.toJson())),
        'reviews': reviews.map((k, v) => MapEntry(k, v.toJson())),
        'completedStageIds': completedStageIds.toList()..sort(),
        'inventory': inventory,
        'upgrades': upgrades,
      };

  /// Schema version, bumped when the format changes. Older saves remain valid.
  static const int schemaVersion = 3;
}

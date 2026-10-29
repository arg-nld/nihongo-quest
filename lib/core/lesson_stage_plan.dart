import 'dart:collection';

import '../models/curriculum_models.dart';

enum LessonStageKind { practice, review, boss }

/// One independently unlockable node inside a curriculum section.
class LessonStage {
  const LessonStage({
    required this.id,
    required this.levelLabel,
    required this.title,
    required this.subtitle,
    required this.kind,
    required this.exercises,
  });

  final String id;
  final String levelLabel;
  final String title;
  final String subtitle;
  final LessonStageKind kind;

  /// Practice/review items for normal nodes. Boss receives the full verified
  /// question pool; the battle shuffles it and uses each question at most once.
  final List<Exercise> exercises;

  bool get isBoss => kind == LessonStageKind.boss;
  bool get isReview => kind == LessonStageKind.review;
}

/// Splits existing authored lesson content into category-based game levels.
/// No textbook content is generated here: stages only reorganize validated
/// exercises that already exist in the curriculum JSON.
class LessonStagePlan {
  static const int questionsPerStage = 5;
  static const int reviewQuestionCount = 10;

  static List<LessonStage> build({
    required Section section,
    required Lesson lesson,
  }) {
    if (section.type == 'reference' || section.id == 'reference') {
      return const [];
    }

    final practice = lesson.exercises
        .where((e) => e.verified && e.type != 'flashcard')
        .toList();
    final groups = LinkedHashMap<String, List<Exercise>>();
    for (final exercise in practice) {
      final category = _categoryFor(exercise);
      groups.putIfAbsent(category, () => <Exercise>[]).add(exercise);
    }
    _mergeTinyGroups(groups);

    final stageSpecs = <({
      String idSuffix,
      String title,
      String subtitle,
      LessonStageKind kind,
      List<Exercise> exercises,
    })>[];
    for (final entry in groups.entries) {
      final items = entry.value;
      if (items.isEmpty) continue;
      final partCount = (items.length / questionsPerStage).ceil();
      final baseSize = items.length ~/ partCount;
      final largerPartCount = items.length % partCount;
      var offset = 0;
      for (var part = 0; part < partCount; part++) {
        // Balance the split: 6 questions become 3+3, not 5+1. This keeps
        // every category level meaningful while still capping it at five.
        final partSize = baseSize + (part < largerPartCount ? 1 : 0);
        final end = offset + partSize;
        final title = partCount > 1 ? '${entry.key} · Part ${part + 1}' : entry.key;
        stageSpecs.add((
          idSuffix: 'level_${_slug(entry.key)}_part_${part + 1}',
          title: title,
          subtitle: 'No timer or lives · Answer each question once · 80% accuracy to pass',
          kind: LessonStageKind.practice,
          exercises: _padShortStage(
            base: items.sublist(offset, end),
            category: entry.key,
            categoryItems: items,
            practice: practice,
            quiz: lesson.quiz,
          ),
        ));
        offset = end;
      }
    }

    final review = _reviewPool(practice, lesson.quiz);
    if (review.isNotEmpty) {
      stageSpecs.add((
        idSuffix: 'review',
        title: 'Mastery Review',
        subtitle: 'Mix the skills from this unit before challenging the boss',
        kind: LessonStageKind.review,
        exercises: review,
      ));
    }

    final bossPool = <Exercise>[
      ...practice,
      ...lesson.quiz.where((e) => e.verified && e.type != 'flashcard'),
    ];
    final uniqueBossPool = <String, Exercise>{};
    for (final exercise in bossPool) {
      uniqueBossPool.putIfAbsent(exercise.id, () => exercise);
    }
    if (uniqueBossPool.isNotEmpty) {
      stageSpecs.add((
        idSuffix: 'boss',
        title: 'Boss Battle',
        subtitle: 'Defeat the guardian: correct answers damage its HP; mistakes and timeouts cost hearts',
        kind: LessonStageKind.boss,
        exercises: uniqueBossPool.values.toList(),
      ));
    }

    final unitNumber = section.order;
    return [
      for (var i = 0; i < stageSpecs.length; i++)
        LessonStage(
          id: '${section.id}_${stageSpecs[i].idSuffix}',
          levelLabel: '$unitNumber-${i + 1}',
          title: stageSpecs[i].title,
          subtitle: stageSpecs[i].subtitle,
          kind: stageSpecs[i].kind,
          exercises: stageSpecs[i].exercises,
        ),
    ];
  }

  static String _slug(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');

  static String _categoryFor(Exercise exercise) {
    switch (exercise.skill) {
      case 'writing_systems':
        return 'Writing Systems';
      case 'pronunciation':
        return 'Pronunciation & Vowel Sounds';
      case 'long_short':
      case 'double_consonants':
        return 'Sound Patterns';
      case 'hiragana':
      case 'reading':
        return 'Reading Kana';
      case 'vocab':
      case 'vocab_body':
      case 'vocab_bedbath':
        return 'Word Meanings';
      case 'grammar':
        return 'Grammar & Particles';
      case 'sentences':
        return 'Sentence Building';
      case 'counting':
      case 'counters':
        return 'Numbers & Counters';
      case 'age':
        return 'Age & Personal Details';
      case 'phrases':
      case 'greetings':
      case 'leave_return':
      case 'dialogue':
      case 'culture':
        return 'Conversation & Everyday Use';
      default:
        return 'Mixed Skills';
    }
  }

  /// Prevents one-question nodes by merging tiny groups into a related category
  /// or, if none exists, the largest viable category. Content is never dropped.
  static void _mergeTinyGroups(LinkedHashMap<String, List<Exercise>> groups) {
    const targetOrder = <String, List<String>>{
      'Writing Systems': ['Reading Kana', 'Pronunciation & Vowel Sounds'],
      'Pronunciation & Vowel Sounds': ['Sound Patterns', 'Writing Systems', 'Reading Kana'],
      'Sound Patterns': ['Pronunciation & Vowel Sounds', 'Writing Systems'],
      'Reading Kana': ['Writing Systems', 'Pronunciation & Vowel Sounds'],
      'Word Meanings': ['Sentence Building', 'Conversation & Everyday Use'],
      'Grammar & Particles': ['Sentence Building', 'Conversation & Everyday Use'],
      'Sentence Building': ['Grammar & Particles', 'Word Meanings'],
      'Numbers & Counters': ['Age & Personal Details', 'Word Meanings'],
      'Age & Personal Details': ['Conversation & Everyday Use', 'Numbers & Counters'],
      'Conversation & Everyday Use': [
        'Age & Personal Details',
        'Sentence Building',
        'Word Meanings',
        'Grammar & Particles',
        'Numbers & Counters',
      ],
      'Mixed Skills': ['Word Meanings', 'Grammar & Particles', 'Sentence Building'],
    };

    final tinyKeys = groups.entries
        .where((entry) => entry.value.length < 2)
        .map((entry) => entry.key)
        .toList();
    for (final key in tinyKeys) {
      final source = groups[key];
      if (source == null || source.isEmpty) continue;
      final targets = targetOrder[key] ?? const <String>[];
      String? destination;
      for (final candidate in targets) {
        if (candidate != key && (groups[candidate]?.length ?? 0) >= 2) {
          destination = candidate;
          break;
        }
      }
      if (destination == null) {
        // If no semantic neighbour exists (for example a single culture item
        // in a counting pre-lesson), attach it to the largest established
        // category instead of creating a one-question level.
        final candidates = groups.entries
            .where((entry) => entry.key != key && entry.value.length >= 2)
            .toList()
          ..sort((a, b) => b.value.length.compareTo(a.value.length));
        if (candidates.isNotEmpty) destination = candidates.first.key;
      }
      if (destination != null) {
        groups[destination]!.addAll(source);
        groups.remove(key);
      }
    }
  }


  /// Keeps the original category/stage structure, but adds reinforcement items
  /// to short practice stages so the 80% pass rule is meaningful. The original
  /// category questions stay assigned to their original stage; supplemental
  /// questions can recur in neighboring stages, but never twice inside one stage.
  /// This preserves the map's existing stage count while ensuring at least five
  /// distinct questions per ordinary practice stage.
  static List<Exercise> _padShortStage({
    required List<Exercise> base,
    required String category,
    required List<Exercise> categoryItems,
    required List<Exercise> practice,
    required List<Exercise> quiz,
  }) {
    final result = List<Exercise>.from(base);
    if (result.length >= questionsPerStage) return result;

    final seen = result.map((exercise) => exercise.id).toSet();
    const relatedCategories = <String, List<String>>{
      'Writing Systems': ['Reading Kana', 'Pronunciation & Vowel Sounds'],
      'Pronunciation & Vowel Sounds': ['Sound Patterns', 'Writing Systems', 'Reading Kana'],
      'Sound Patterns': ['Pronunciation & Vowel Sounds', 'Writing Systems', 'Reading Kana'],
      'Reading Kana': ['Writing Systems', 'Pronunciation & Vowel Sounds'],
      'Word Meanings': ['Sentence Building', 'Conversation & Everyday Use', 'Reading Kana'],
      'Grammar & Particles': ['Sentence Building', 'Conversation & Everyday Use', 'Word Meanings'],
      'Sentence Building': ['Grammar & Particles', 'Conversation & Everyday Use', 'Word Meanings'],
      'Numbers & Counters': ['Age & Personal Details', 'Word Meanings', 'Conversation & Everyday Use'],
      'Age & Personal Details': ['Conversation & Everyday Use', 'Numbers & Counters', 'Word Meanings'],
      'Conversation & Everyday Use': [
        'Age & Personal Details',
        'Sentence Building',
        'Word Meanings',
        'Grammar & Particles',
        'Numbers & Counters',
      ],
      'Mixed Skills': ['Word Meanings', 'Grammar & Particles', 'Sentence Building'],
    };

    final related = relatedCategories[category] ?? const <String>[];
    final candidates = <Exercise>[
      ...categoryItems,
      ...practice.where((exercise) => related.contains(_categoryFor(exercise))),
      ...practice,
      ...quiz,
    ];

    for (final exercise in candidates) {
      if (!exercise.verified || exercise.type == 'flashcard') continue;
      if (seen.add(exercise.id)) result.add(exercise);
      if (result.length >= questionsPerStage) break;
    }
    return result;
  }

  static List<Exercise> _reviewPool(
    List<Exercise> practice,
    List<Exercise> quiz,
  ) {
    final unique = <String, Exercise>{};
    for (final exercise in quiz) {
      if (exercise.verified && exercise.type != 'flashcard') {
        unique.putIfAbsent(exercise.id, () => exercise);
      }
    }
    final extras = practice.where((e) => !unique.containsKey(e.id)).toList();
    if (extras.isNotEmpty) {
      // Evenly sample across the practice list rather than taking only its
      // opening topic, so the review covers more than one category.
      final desiredExtras = (reviewQuestionCount - unique.length).clamp(0, 5);
      for (var i = 0; i < desiredExtras; i++) {
        final index = ((i + 1) * extras.length / (desiredExtras + 1)).floor();
        final safeIndex = index < 0
            ? 0
            : (index >= extras.length ? extras.length - 1 : index);
        final exercise = extras[safeIndex];
        unique.putIfAbsent(exercise.id, () => exercise);
      }
    }
    return unique.values.take(reviewQuestionCount).toList();
  }
}

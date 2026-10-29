import 'package:flutter/foundation.dart';

/// Curriculum data models.
///
/// Lesson content lives in `assets/curriculum/<section>.json` — never in widget
/// code. Every exercise and vocabulary item carries a stable ID and, where
/// source-derived, a `source` page reference into the OCR archive
/// (`vlm_ocr/chapters/<section>/pages/page_NNNN.txt`).
///
/// Two JSON documents describe the whole course:
///  - `curriculum.json` — ordered list of [Section]s (the map spine).
///  - `<sectionId>.json` — one [Lesson] per section.

/// One node of the curriculum map: a pre-lesson, a lesson, or a reference part.
@immutable
class Section {
  const Section({
    required this.id,
    required this.order,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.area,
    required this.pages,
    required this.contentFile,
  });

  /// Stable ID, e.g. `pre_a`, `lesson_01`, `reference`.
  final String id;
  final int order;
  final String title;
  final String subtitle;

  /// `pre_lesson` | `lesson` | `reference`.
  final String type;

  /// World-map area this section belongs to (cosmetic grouping).
  final String area;
  final String pages;
  final String contentFile;

  static Section fromJson(Map<String, dynamic> j) => Section(
        id: j['id'] as String,
        order: j['order'] as int,
        title: j['title'] as String,
        subtitle: (j['subtitle'] ?? '') as String,
        type: (j['type'] ?? 'lesson') as String,
        area: (j['area'] ?? 'Japan') as String,
        pages: (j['pages'] ?? '') as String,
        contentFile: j['contentFile'] as String,
      );
}

/// A vocabulary entry introduced by a lesson.
@immutable
class VocabItem {
  const VocabItem({
    required this.id,
    required this.japanese,
    required this.romaji,
    required this.english,
    this.kanji,
    this.example,
    this.exampleRomaji,
    this.exampleEnglish,
    this.source,
    this.verified = true,
  });

  final String id;
  final String japanese; // kana (or kana+kanji) surface form
  final String romaji;
  final String english;
  final String? kanji;
  final String? example;
  final String? exampleRomaji;
  final String? exampleEnglish;

  /// e.g. `lesson_01 p.34`.
  final String? source;
  final bool verified;

  static VocabItem fromJson(Map<String, dynamic> j) => VocabItem(
        id: j['id'] as String,
        japanese: j['japanese'] as String,
        romaji: (j['romaji'] ?? '') as String,
        english: j['english'] as String,
        kanji: j['kanji'] as String?,
        example: j['example'] as String?,
        exampleRomaji: j['exampleRomaji'] as String?,
        exampleEnglish: j['exampleEnglish'] as String?,
        source: j['source'] as String?,
        verified: (j['verified'] ?? true) as bool,
      );
}

/// A concise, original grammar note grounded in the textbook.
@immutable
class GrammarNote {
  const GrammarNote({
    required this.id,
    required this.title,
    required this.pattern,
    required this.explanation,
    required this.examples,
    this.mistakes = const [],
    this.source,
  });

  final String id;
  final String title;
  final String pattern; // e.g. "[word] + desu"
  final String explanation;
  final List<GrammarExample> examples;
  final List<String> mistakes;
  final String? source;

  static GrammarNote fromJson(Map<String, dynamic> j) => GrammarNote(
        id: j['id'] as String,
        title: j['title'] as String,
        pattern: j['pattern'] as String,
        explanation: j['explanation'] as String,
        examples: (j['examples'] as List<dynamic>? ?? const [])
            .map((e) => GrammarExample.fromJson(e as Map<String, dynamic>))
            .toList(),
        mistakes: (j['mistakes'] as List<dynamic>? ?? const [])
            .map((e) => e as String)
            .toList(),
        source: j['source'] as String?,
      );
}

@immutable
class GrammarExample {
  const GrammarExample({
    required this.japanese,
    required this.romaji,
    required this.english,
  });
  factory GrammarExample.fromJson(Map<String, dynamic> j) => GrammarExample(
        japanese: j['japanese'] as String,
        romaji: (j['romaji'] ?? '') as String,
        english: j['english'] as String,
      );
  final String japanese;
  final String romaji;
  final String english;
}

/// A single practice/assessment item.
///
/// Supported [Exercise.type] strings:
///  - `multiple_choice` — [Exercise.choices] + [Exercise.answerIndex]
///  - `fill_blank`      — sentence with `___`, [Exercise.accepted] answers (normalized)
///  - `word_order`      — [Exercise.tokens] shuffled by the player, correct order given
///  - `match`           — [Exercise.pairs] of left/right items
///  - `translation`     — direction `ja_to_en` (multiple-choice style) or
///                        `en_to_ja` (typed, [Exercise.accepted] answers)
///  - `flashcard`       — non-scored active-recall card (front/back)
@immutable
class Exercise {
  const Exercise({
    required this.id,
    required this.type,
    required this.prompt,
    required this.explanation,
    required this.verified,
    this.choices = const [],
    this.answerIndex,
    this.accepted = const [],
    this.tokens = const [],
    this.pairs = const [],
    this.direction,
    this.hint,
    this.source,
    this.skill,
    this.vocabId,
  });

  final String id;
  final String type;
  final String prompt;
  final String explanation;
  final bool verified;

  final List<String> choices;
  final int? answerIndex;
  final List<String> accepted; // normalized (see AnswerChecker)
  final List<String> tokens; // correct order for word_order
  final List<MatchPair> pairs;
  final String? direction; // for translation: ja_to_en | en_to_ja
  final String? hint;
  final String? source;
  final String? skill; // skill tag for accuracy tracking / SRS
  final String? vocabId; // linked vocabulary item, feeds Review Today

  static Exercise fromJson(Map<String, dynamic> j) => Exercise(
        id: j['id'] as String,
        type: j['type'] as String,
        prompt: j['prompt'] as String,
        explanation: (j['explanation'] ?? '') as String,
        verified: (j['verified'] ?? true) as bool,
        choices: (j['choices'] as List<dynamic>? ?? const [])
            .map((e) => e as String)
            .toList(),
        answerIndex: j['answerIndex'] as int?,
        accepted: (j['accepted'] as List<dynamic>? ?? const [])
            .map((e) => e as String)
            .toList(),
        tokens: (j['tokens'] as List<dynamic>? ?? const [])
            .map((e) => e as String)
            .toList(),
        pairs: (j['pairs'] as List<dynamic>? ?? const [])
            .map((e) => MatchPair.fromJson(e as Map<String, dynamic>))
            .toList(),
        direction: j['direction'] as String?,
        hint: j['hint'] as String?,
        source: j['source'] as String?,
        skill: j['skill'] as String?,
        vocabId: j['vocabId'] as String?,
      );
}

@immutable
class MatchPair {
  const MatchPair({required this.left, required this.right});
  final String left;
  final String right;

  static MatchPair fromJson(Map<String, dynamic> j) =>
      MatchPair(left: j['left'] as String, right: j['right'] as String);
}

/// A full lesson's authored content.
@immutable
class Lesson {
  const Lesson({
    required this.sectionId,
    required this.title,
    required this.subtitle,
    required this.pages,
    required this.vocab,
    required this.grammar,
    required this.exercises,
    required this.quiz,
    required this.summary,
    this.kanaFocus = const [],
    this.objectives = const [],
  });

  final String sectionId;
  final String title;
  final String subtitle;
  final String pages;
  final List<VocabItem> vocab;
  final List<GrammarNote> grammar;
  final List<Exercise> exercises;
  final List<Exercise> quiz;
  final String summary;
  final List<String> kanaFocus;
  final List<String> objectives;

  /// All scored exercises (practice + quiz).
  List<Exercise> get scoredExercises => [...exercises, ...quiz];

  static Lesson fromJson(Map<String, dynamic> j) => Lesson(
        sectionId: j['sectionId'] as String,
        title: j['title'] as String,
        subtitle: (j['subtitle'] ?? '') as String,
        pages: (j['pages'] ?? '') as String,
        vocab: (j['vocab'] as List<dynamic>? ?? const [])
            .map((e) => VocabItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        grammar: (j['grammar'] as List<dynamic>? ?? const [])
            .map((e) => GrammarNote.fromJson(e as Map<String, dynamic>))
            .toList(),
        exercises: (j['exercises'] as List<dynamic>? ?? const [])
            .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
            .toList(),
        quiz: (j['quiz'] as List<dynamic>? ?? const [])
            .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
            .toList(),
        summary: (j['summary'] ?? '') as String,
        kanaFocus: (j['kanaFocus'] as List<dynamic>? ?? const [])
            .map((e) => e as String)
            .toList(),
        objectives: (j['objectives'] as List<dynamic>? ?? const [])
            .map((e) => e as String)
            .toList(),
      );
}

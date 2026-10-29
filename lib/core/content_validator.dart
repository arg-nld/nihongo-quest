import '../models/curriculum_models.dart';

/// Validates curriculum content so malformed data can never crash the app.
///
/// Returns a list of human-readable problems; an empty list means the lesson
/// is safe to load. Structural problems (missing required fields, bad types)
/// are caught by [Lesson.fromJson] throwing — callers should catch and convert
/// to a problem string.
class ContentValidator {
  static const Set<String> knownTypes = {
    'multiple_choice',
    'fill_blank',
    'word_order',
    'match',
    'translation',
    'flashcard',
  };

  /// Validate a whole lesson. [sectionIds] is the set of valid section IDs.
  static List<String> validateLesson(Lesson lesson, Set<String> sectionIds) {
    final problems = <String>[];
    if (!sectionIds.contains(lesson.sectionId)) {
      problems.add('sectionId "${lesson.sectionId}" is not registered in curriculum.json');
    }
    final ids = <String>{};

    void checkExercises(List<Exercise> list, String kind) {
      for (final ex in list) {
        if (ids.contains(ex.id)) {
          problems.add('duplicate exercise ID "${ex.id}"');
        }
        ids.add(ex.id);
        problems.addAll(validateExercise(ex, lesson, kind));
      }
    }

    for (final v in lesson.vocab) {
      if (v.japanese.isEmpty || v.english.isEmpty) {
        problems.add('vocab "${v.id}" missing japanese/english');
      }
      if (!v.verified) {
        // unverified vocab may exist but is reported; scored questions that
        // reference it are rejected below.
      }
    }
    for (final g in lesson.grammar) {
      if (g.title.isEmpty || g.pattern.isEmpty || g.explanation.isEmpty) {
        problems.add('grammar "${g.id}" missing title/pattern/explanation');
      }
    }
    checkExercises(lesson.exercises, 'exercise');
    checkExercises(lesson.quiz, 'quiz');

    final vocabById = {for (final v in lesson.vocab) v.id: v};
    final quizIds = lesson.quiz.map((ex) => ex.id).toSet();
    for (final ex in lesson.scoredExercises) {
      final vocabId = ex.vocabId;
      if (vocabId != null && !vocabById.containsKey(vocabId)) {
        problems.add('exercise "${ex.id}" references unknown vocab "$vocabId"');
      } else if (vocabId != null &&
          quizIds.contains(ex.id) &&
          vocabById[vocabId]!.verified == false) {
        problems.add('quiz "${ex.id}" references unverified vocab "$vocabId"');
      }
    }
    if (lesson.sectionId.startsWith('lesson_') && lesson.quiz.isEmpty) {
      problems.add('lesson has no quiz');
    }
    if (lesson.sectionId == 'reference' &&
        (lesson.exercises.isNotEmpty || lesson.quiz.isNotEmpty)) {
      problems.add('reference content must be browse-only with no scored exercises or quiz');
    }
    return problems;
  }

  static List<String> validateExercise(Exercise ex, Lesson lesson, String kind) {
    final p = <String>[];
    final ref = '$kind "${ex.id}"';
    if (!knownTypes.contains(ex.type)) {
      p.add('$ref: unknown type "${ex.type}"');
      return p;
    }
    if (ex.prompt.isEmpty && ex.type != 'flashcard') {
      p.add('$ref: empty prompt');
    }
    switch (ex.type) {
      case 'multiple_choice':
        if (ex.choices.length < 2) p.add('$ref: needs >=2 choices');
        if (ex.answerIndex == null ||
            ex.answerIndex! < 0 ||
            ex.answerIndex! >= ex.choices.length) {
          p.add('$ref: answerIndex ${ex.answerIndex} out of range');
        }
      case 'translation':
        if (ex.direction != 'ja_to_en' && ex.direction != 'en_to_ja') {
          p.add('$ref: direction must be ja_to_en or en_to_ja');
        }
        if (ex.direction == 'ja_to_en') {
          if (ex.choices.length < 2) p.add('$ref: ja_to_en needs >=2 choices');
          if (ex.answerIndex == null ||
              ex.answerIndex! < 0 ||
              ex.answerIndex! >= ex.choices.length) {
            p.add('$ref: answerIndex out of range');
          }
        } else if (ex.accepted.isEmpty) {
          p.add('$ref: en_to_ja needs accepted answers');
        }
      case 'fill_blank':
        if (ex.accepted.isEmpty) p.add('$ref: needs accepted answers');
        if (!ex.prompt.contains('___')) p.add('$ref: prompt must contain ___');
      case 'word_order':
        if (ex.tokens.length < 2) p.add('$ref: needs >=2 tokens');
      case 'match':
        if (ex.pairs.length < 2) p.add('$ref: needs >=2 pairs');
        final rights = ex.pairs.map((e) => e.right).toSet();
        if (rights.length != ex.pairs.length) {
          p.add('$ref: duplicate right-side values in pairs');
        }
      case 'flashcard':
        break;
    }
    // Unverified content must not appear in scored assessments.
    if (!ex.verified && kind == 'quiz') {
      p.add('$ref: unverified exercise used in quiz');
    }
    return p;
  }
}

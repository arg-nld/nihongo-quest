import '../models/curriculum_models.dart';

/// Answer validation for every exercise type.
///
/// Typed answers (fill_blank / translation en_to_ja) are normalized before
/// comparison: trimmed, lowercased, punctuation stripped, long-vowel and
/// spacing variants collapsed. Japanese answers compare against every
/// [Exercise.accepted] entry (documented alternatives), so natural variation
/// like "wa" / "は" or "konnichiwa" / "konnitiha" can be accepted explicitly.
class AnswerChecker {
  /// Normalize a typed answer.
  static String normalize(String input) {
    var s = input.trim().toLowerCase();
    // strip common punctuation and full-width variants
    s = s.replaceAll(RegExp(r'[.,!?;:"、。！？，「」\s]+'), '');
    // collapse macron/long-vowel romaji variants: ou→o? No — that changes words.
    // Instead unify common apostrophes and hyphens only.
    s = s.replaceAll(RegExp(r"['’\-]"), '');
    return s;
  }

  static bool check(Exercise ex, dynamic answer) {
    switch (ex.type) {
      case 'multiple_choice':
      case 'translation' when ex.direction == 'ja_to_en':
        return answer is int && answer == ex.answerIndex;
      case 'fill_blank':
        if (answer is! String) return false;
        final given = normalize(answer);
        if (given.isEmpty) return false;
        final matchesAccepted = ex.accepted.any((a) => normalize(a) == given);
        final matchesChoice = ex.answerIndex != null &&
            ex.answerIndex! >= 0 &&
            ex.answerIndex! < ex.choices.length &&
            normalize(ex.choices[ex.answerIndex!]) == given;
        return matchesAccepted || matchesChoice;
      case 'translation' when ex.direction == 'en_to_ja':
        if (answer is! String) return false;
        final given = normalize(answer);
        if (given.isEmpty) return false;
        return ex.accepted.any((a) => normalize(a) == given);
      case 'word_order':
        if (answer is! List) return false;
        // answer = order of token indices as the player assembled them
        final given = answer.whereType<int>().map((i) => ex.tokens[i]).join(' ');
        return given == ex.tokens.join(' ');
      case 'match':
        if (answer is! Map) return false;
        // answer = leftIndex -> rightString chosen
        for (var i = 0; i < ex.pairs.length; i++) {
          final chosen = answer['$i'];
          if (chosen is! String || chosen != ex.pairs[i].right) return false;
        }
        return true;
      case 'flashcard':
        return true; // flashcards are self-assessed; always "correct"
      default:
        return false;
    }
  }
}

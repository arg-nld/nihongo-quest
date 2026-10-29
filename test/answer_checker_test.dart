import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_quest/core/answer_checker.dart';
import 'package:nihongo_quest/models/curriculum_models.dart';

void main() {
  group('normalize', () {
    test('lowercases and strips punctuation/spaces', () {
      expect(AnswerChecker.normalize('Hai, Wakarimasu.'), 'haiwakarimasu');
      expect(AnswerChecker.normalize('  hachi juu nana '), 'hachijuunana');
      expect(AnswerChecker.normalize("iie"), 'iie');
    });
  });

  group('check: multiple_choice', () {
    final ex = const Exercise(
      id: 't_mc',
      type: 'multiple_choice',
      prompt: 'pick',
      explanation: 'x',
      verified: true,
      choices: ['a', 'b', 'c'],
      answerIndex: 2,
    );
    test('correct index', () {
      expect(AnswerChecker.check(ex, 2), isTrue);
    });
    test('wrong index', () {
      expect(AnswerChecker.check(ex, 0), isFalse);
    });
  });

  group('check: fill_blank', () {
    final ex = const Exercise(
      id: 't_fb',
      type: 'fill_blank',
      prompt: '___ desu',
      explanation: 'x',
      verified: true,
      accepted: ['wakarimasu', 'wakari masu'],
    );
    test('accepted answer with punctuation', () {
      expect(AnswerChecker.check(ex, 'Wakarimasu.'), isTrue);
    });
    test('any accepted alternative', () {
      expect(AnswerChecker.check(ex, 'wakari masu'), isTrue);
    });
    test('wrong answer', () {
      expect(AnswerChecker.check(ex, 'wakarimasen'), isFalse);
    });
    test('empty answer', () {
      expect(AnswerChecker.check(ex, '  '), isFalse);
    });
    test('supports multiple-choice blanks whose answer is stored by index', () {
      const choiceBlank = Exercise(
        id: 't_fb_choice',
        type: 'fill_blank',
        prompt: 'Choose the particle: watashi ___ gakusei desu.',
        explanation: 'The topic particle is wa.',
        verified: true,
        choices: ['ga', 'wa', 'ni', 'de'],
        answerIndex: 1,
      );
      expect(AnswerChecker.check(choiceBlank, 'wa'), isTrue);
      expect(AnswerChecker.check(choiceBlank, 'ga'), isFalse);
    });
  });

  group('check: translation en_to_ja', () {
    final ex = const Exercise(
      id: 't_tr',
      type: 'translation',
      direction: 'en_to_ja',
      prompt: 'Type 87',
      explanation: 'x',
      verified: true,
      accepted: ['hachi juu nana', 'hachi juu shichi'],
    );
    test('first accepted', () => expect(AnswerChecker.check(ex, 'hachi juu nana'), isTrue));
    test('alternate accepted', () => expect(AnswerChecker.check(ex, 'Hachi juu shichi.'), isTrue));
    test('rejected', () => expect(AnswerChecker.check(ex, 'hachi juu go'), isFalse));
  });

  group('check: translation ja_to_en', () {
    final ex = const Exercise(
      id: 't_tr2',
      type: 'translation',
      direction: 'ja_to_en',
      prompt: 'なんですか',
      explanation: 'x',
      verified: true,
      choices: ['What is it?', 'Who is it?'],
      answerIndex: 0,
    );
    test('correct', () => expect(AnswerChecker.check(ex, 0), isTrue));
    test('wrong', () => expect(AnswerChecker.check(ex, 1), isFalse));
  });

  group('check: word_order', () {
    final ex = const Exercise(
      id: 't_wo',
      type: 'word_order',
      prompt: 'build',
      explanation: 'x',
      verified: true,
      tokens: ['ni sen', 'go hyaku', 'juu ni'],
    );
    test('correct order (token indices)', () {
      expect(AnswerChecker.check(ex, [0, 1, 2]), isTrue);
    });
    test('wrong order', () {
      expect(AnswerChecker.check(ex, [1, 0, 2]), isFalse);
    });
  });

  group('check: match', () {
    final ex = const Exercise(
      id: 't_m',
      type: 'match',
      prompt: 'match',
      explanation: 'x',
      verified: true,
      pairs: [
        const MatchPair(left: 'inu', right: 'dog'),
        const MatchPair(left: 'neko', right: 'cat'),
      ],
    );
    test('all correct', () {
      expect(AnswerChecker.check(ex, {'0': 'dog', '1': 'cat'}), isTrue);
    });
    test('swapped', () {
      expect(AnswerChecker.check(ex, {'0': 'cat', '1': 'dog'}), isFalse);
    });
  });
}

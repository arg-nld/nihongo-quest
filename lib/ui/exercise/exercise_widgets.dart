import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/curriculum_models.dart';
import '../../core/answer_checker.dart';
import '../theme.dart';

/// A widget that presents one [Exercise] and reports an answer via callback.
/// Each concrete widget handles its own type.

typedef OnAnswer = void Function(dynamic answer);

class ExerciseView extends StatefulWidget {
  const ExerciseView({
    super.key,
    required this.exercise,
    required this.onAnswer,
    required this.showFeedback,
    this.wasCorrect,
  });

  final Exercise exercise;
  final OnAnswer onAnswer;

  /// When true, interaction is disabled and correctness is shown
  /// (learning mode immediate feedback / review of a submitted exam).
  final bool showFeedback;
  final bool? wasCorrect;

  @override
  State<ExerciseView> createState() => _ExerciseViewState();
}

class _ExerciseViewState extends State<ExerciseView> {
  dynamic _draft; // selected index / typed text / token order / pair map
  late final TextEditingController _typedController;
  String? _matchExerciseId;
  List<String> _matchRightsShuffled = const [];
  List<String> _fillBlankChoices = const [];
  int _fillBlankAnswerIndex = 0;

  @override
  void initState() {
    super.initState();
    _typedController = TextEditingController();
    _resetExerciseDraft(widget.exercise);
  }

  @override
  void didUpdateWidget(covariant ExerciseView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exercise.id != widget.exercise.id) {
      _resetExerciseDraft(widget.exercise);
    }
  }

  @override
  void dispose() {
    _typedController.dispose();
    super.dispose();
  }

  void _resetExerciseDraft(Exercise exercise) {
    _draft = null;
    _typedController.clear();
    _matchExerciseId = exercise.id;
    _matchRightsShuffled = exercise.pairs.map((p) => p.right).toList()..shuffle();

    if (exercise.type != 'fill_blank') {
      _fillBlankChoices = const [];
      _fillBlankAnswerIndex = 0;
      return;
    }

    final hasIndexedAnswer = exercise.choices.isNotEmpty &&
        exercise.answerIndex != null &&
        exercise.answerIndex! >= 0 &&
        exercise.answerIndex! < exercise.choices.length;
    final acceptedAnswer = exercise.accepted.isNotEmpty ? exercise.accepted.first : '';
    final choiceAcceptedIndex = exercise.choices.indexWhere((choice) =>
        exercise.accepted.any((accepted) =>
            AnswerChecker.normalize(choice) == AnswerChecker.normalize(accepted)));
    final answer = hasIndexedAnswer
        ? exercise.choices[exercise.answerIndex!]
        : choiceAcceptedIndex >= 0
            ? exercise.choices[choiceAcceptedIndex]
            : acceptedAnswer;

    if (exercise.choices.isNotEmpty) {
      _fillBlankChoices = [...exercise.choices];
      if (answer.isNotEmpty &&
          !_fillBlankChoices.any((choice) =>
              AnswerChecker.normalize(choice) == AnswerChecker.normalize(answer))) {
        _fillBlankChoices.insert(0, answer);
      }
    } else {
      final choices = <String>[];
      if (answer.trim().isNotEmpty) choices.add(answer);
      for (final option in _fillBlankDistractors(exercise)) {
        if (choices.length >= 4) break;
        if (option.trim().isEmpty) continue;
        final normalized = AnswerChecker.normalize(option);
        final isCorrectAlternative = exercise.accepted.any(
          (accepted) => AnswerChecker.normalize(accepted) == normalized,
        );
        if (!isCorrectAlternative &&
            !choices.any((existing) => AnswerChecker.normalize(existing) == normalized)) {
          choices.add(option);
        }
      }
      _fillBlankChoices = choices;
    }

    // Keep a minimum of two useful options even for old authored blanks that
    // did not include a distractor bank. Avoid introducing duplicate choices.
    for (final fallback in const ['desu', 'wa', 'to', 'ka', 'ne', 'no']) {
      if (_fillBlankChoices.length >= 4) break;
      if (!_fillBlankChoices.any((option) =>
          AnswerChecker.normalize(option) == AnswerChecker.normalize(fallback))) {
        _fillBlankChoices.add(fallback);
      }
    }
    _fillBlankChoices = _fillBlankChoices.toSet().toList();

    final correctChoice = answer.isNotEmpty
        ? answer
        : (exercise.answerIndex != null &&
                exercise.answerIndex! >= 0 &&
                exercise.answerIndex! < exercise.choices.length
            ? exercise.choices[exercise.answerIndex!]
            : '');
    final options = [..._fillBlankChoices]..shuffle(math.Random(exercise.id.hashCode));
    _fillBlankChoices = options;
    _fillBlankAnswerIndex = _fillBlankChoices.indexWhere((choice) =>
        AnswerChecker.normalize(choice) == AnswerChecker.normalize(correctChoice));
    if (_fillBlankAnswerIndex < 0) _fillBlankAnswerIndex = 0;
  }

  List<String> _fillBlankDistractors(Exercise exercise) {
    const grammar = ['wa', 'ga', 'no', 'to', 'ni', 'de', 'o', 'ka', 'mo', 'desu', 'masu'];
    const phrases = ['sou', 'kimasu', 'moushimasu', 'kudasai', 'sumimasen', 'arigatou', 'konnichiwa', 'desu'];
    const numbers = ['ichi', 'ni', 'san', 'yon', 'go', 'juu', 'han', 'mittsu', 'futatsu'];
    const reading = ['a', 'i', 'u', 'e', 'o', 'ka', 'ki', 'ku', 'ke', 'ko', 'hiragana', 'katakana', 'kanji'];
    const vocabulary = [
      'grandfather', 'grandmother', 'aunt', 'uncle', 'house', 'red', 'life', 'horse',
      'shrimp', 'man', 'cat', 'yes', 'no', 'when', 'where', 'which one',
    ];
    final skill = exercise.skill ?? '';
    final preferred = switch (skill) {
      'grammar' || 'sentences' => grammar,
      'counting' || 'counters' || 'age' => numbers,
      'pronunciation' || 'long_short' || 'double_consonants' || 'hiragana' || 'writing_systems' => reading,
      'phrases' || 'greetings' || 'leave_return' || 'dialogue' => phrases,
      'vocab' || 'vocab_body' || 'vocab_bedbath' => vocabulary,
      _ => [...grammar, ...phrases, ...numbers, ...vocabulary],
    };
    return [...preferred, ...grammar, ...phrases, ...numbers, ...vocabulary];
  }

  @override
  Widget build(BuildContext context) {
    final ex = widget.exercise;
    switch (ex.type) {
      case 'multiple_choice':
        return _choicesList(context, ex, _mcTile);
      case 'translation' when ex.direction == 'ja_to_en':
        return _choicesList(context, ex, _mcTile);
      case 'translation' when ex.direction == 'en_to_ja':
        return _typed(context, ex);
      case 'fill_blank':
        return _choicesList(context, ex, _mcTile);
      case 'word_order':
        return _wordOrder(context, ex);
      case 'match':
        return _matchView(context, ex);
      case 'flashcard':
        return _flashcard(context, ex);
      default:
        return Text('Unsupported exercise type: ${ex.type}');
    }
  }

  Widget _choicesList(BuildContext context, Exercise ex,
      Widget Function(BuildContext, Exercise, int) tileBuilder) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (ex.prompt.trim().isNotEmpty) ...[
          Text(ex.prompt, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 18, height: 1.35)),
          const SizedBox(height: 12),
        ],
        for (var i = 0; i < _choicesFor(ex).length; i++)
          tileBuilder(context, ex, i),
        if (!widget.showFeedback && _draft is int) ...[
          const SizedBox(height: 10),
          FilledButton(
            onPressed: () => widget.onAnswer(
              ex.type == 'fill_blank' ? _fillBlankChoices[_draft as int] : _draft,
            ),
            child: const Text('Confirm answer'),
          ),
        ],
      ],
    );
  }

  List<String> _choicesFor(Exercise ex) =>
      ex.type == 'fill_blank' ? _fillBlankChoices : ex.choices;

  Widget _mcTile(BuildContext context, Exercise ex, int i) {
    final choices = _choicesFor(ex);
    final selected = _draft == i;
    final correct = i == (ex.type == 'fill_blank' ? _fillBlankAnswerIndex : ex.answerIndex);
    final Color background;
    final Color border;
    if (widget.showFeedback && correct) {
      background = const Color(0xFFE5F4DB);
      border = AppTheme.matchaDark;
    } else if (widget.showFeedback && selected) {
      background = const Color(0xFFFCE8E3);
      border = AppTheme.shu;
    } else if (selected) {
      background = const Color(0xFFE7F4DE);
      border = AppTheme.matchaDark;
    } else {
      background = AppTheme.surface;
      border = AppTheme.outline;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: widget.showFeedback ? null : () => setState(() => _draft = i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: border, width: selected || (widget.showFeedback && correct) ? 1.6 : 1),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? AppTheme.matchaDark : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: selected ? AppTheme.matchaDark : AppTheme.outline),
                  ),
                  child: widget.showFeedback && correct
                      ? const Icon(Icons.check_rounded, size: 17, color: Colors.white)
                      : Text(
                          String.fromCharCode(65 + i),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: selected ? Colors.white : AppTheme.inkMuted,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    choices[i],
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.ink,
                    ),
                  ),
                ),
                if (widget.showFeedback && selected && !correct)
                  const Icon(Icons.close_rounded, color: AppTheme.shu, size: 21)
                else if (selected && !widget.showFeedback)
                  const Icon(Icons.radio_button_checked_rounded,
                      color: AppTheme.matchaDark, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _typed(BuildContext context, Exercise ex) {
    final controller = _typedController;
    if (_draft is String && controller.text != _draft) {
      controller.value = controller.value.copyWith(
        text: _draft as String,
        selection: TextSelection.collapsed(offset: (_draft as String).length),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(ex.prompt, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 18, height: 1.35)),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          enabled: !widget.showFeedback,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: 'Your answer',
            errorText: widget.showFeedback && widget.wasCorrect == false
                ? 'Correct: ${ex.accepted.first}'
                : null,
          ),
          onChanged: (v) => _draft = v,
          onSubmitted: (v) {
            setState(() => _draft = v);
            widget.onAnswer(v);
          },
        ),
        if (ex.hint != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Hint: ${ex.hint}',
                style: const TextStyle(color: Colors.black54, fontSize: 13)),
          ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: widget.showFeedback
              ? null
              : () {
                  setState(() => _draft = controller.text);
                  widget.onAnswer(controller.text);
                },
          child: const Text('Check'),
        ),
      ],
    );
  }

  Widget _wordOrder(BuildContext context, Exercise ex) {
    // _draft holds the ordered list of token indices.
    final order = (_draft as List?)?.cast<int>() ?? <int>[];
    final used = order.toSet();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(ex.prompt, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 18, height: 1.35)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minHeight: 56),
          decoration: BoxDecoration(
            color: AppTheme.surfaceRaised,
            border: Border.all(color: AppTheme.outline),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final idx in order)
                InputChip(
                  label: Text(ex.tokens[idx]),
                  onPressed: widget.showFeedback
                      ? null
                      : () => setState(() {
                            order.remove(idx);
                            _draft = order;
                          }),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var i = 0; i < ex.tokens.length; i++)
              if (!used.contains(i))
                ActionChip(
                  label: Text(ex.tokens[i]),
                  onPressed: widget.showFeedback
                      ? null
                      : () => setState(() {
                            order.add(i);
                            _draft = order;
                          }),
                ),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: widget.showFeedback || order.length != ex.tokens.length
              ? null
              : () {
                  widget.onAnswer(List<int>.from(order));
                },
          child: const Text('Check'),
        ),
      ],
    );
  }

  Widget _matchView(BuildContext context, Exercise ex) {
    // _draft is a Map<String leftIndex, String rightValue>.
    final Map map = _draft is Map ? _draft as Map : {};
    // Keep the ordering stable while the parent rebuilds (for example once
    // per second during a timed boss question).
    final rightsShuffled = _matchExerciseId == ex.id
        ? _matchRightsShuffled
        : (ex.pairs.map((p) => p.right).toList()..shuffle());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(ex.prompt, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 18, height: 1.35)),
        const SizedBox(height: 12),
        for (var i = 0; i < ex.pairs.length; i++)
          Row(
            children: [
              Expanded(child: Text(ex.pairs[i].left)),
              const Icon(Icons.arrow_forward, size: 16),
              Expanded(
                child: DropdownButton<String>(
                  value: map['$i'] as String?,
                  isExpanded: true,
                  hint: const Text('choose'),
                  items: [
                    for (final r in rightsShuffled)
                      DropdownMenuItem(value: r, child: Text(r)),
                  ],
                  onChanged: widget.showFeedback
                      ? null
                      : (v) => setState(() {
                            final m = {...map};
                            m['$i'] = v;
                            _draft = m;
                          }),
                ),
              ),
              if (widget.showFeedback)
                Icon(
                  map['$i'] == ex.pairs[i].right ? Icons.check : Icons.close,
                  color: map['$i'] == ex.pairs[i].right ? Colors.green : Colors.red,
                ),
            ],
          ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: widget.showFeedback || map.length != ex.pairs.length
              ? null
              : () => widget.onAnswer({...map}),
          child: const Text('Check'),
        ),
      ],
    );
  }

  Widget _flashcard(BuildContext context, Exercise ex) {
    return Column(
      children: [
        Text(ex.prompt, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        if (_draft == 'revealed') ...[
          const SizedBox(height: 12),
          Text(ex.explanation, style: Theme.of(context).textTheme.titleMedium),
        ],
        const SizedBox(height: 16),
        FilledButton.tonal(
          onPressed: () => setState(() => _draft = 'revealed'),
          child: Text(_draft == 'revealed' ? 'Got it — continue' : 'Reveal'),
        ),
      ],
    );
  }
}

/// Static helper for checking correctness without widget state.
class ExerciseAnswers {
  static bool isCorrect(Exercise ex, dynamic answer) => AnswerChecker.check(ex, answer);
}

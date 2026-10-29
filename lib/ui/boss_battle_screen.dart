import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/answer_checker.dart';
import '../core/lesson_stage_plan.dart';
import '../models/curriculum_models.dart';
import '../providers/providers.dart';
import 'artwork_catalog.dart';
import 'exercise/exercise_widgets.dart';
import 'theme.dart';

enum _BossMotion { idle, hit, attack, victory, defeat }

/// Timed boss battle: correct answers damage the boss; wrong answers and
/// timeouts cost a heart. Every question is used at most once per battle.
class BossBattleScreen extends ConsumerStatefulWidget {
  const BossBattleScreen({
    super.key,
    required this.sectionId,
    required this.lesson,
    required this.stage,
  });

  final String sectionId;
  final Lesson lesson;
  final LessonStage stage;

  @override
  ConsumerState<BossBattleScreen> createState() => _BossBattleScreenState();
}

class _BossBattleScreenState extends ConsumerState<BossBattleScreen>
    with SingleTickerProviderStateMixin {
  static const int _maxBossHp = 100;
  static const int _baseDamagePerCorrect = 5;
  static const int _startingLives = 3;
  static const int _baseSecondsPerQuestion = 12;

  late final int _secondsPerQuestion;
  late final int _damagePerCorrect;
  late final AnimationController _questionClock;

  final Set<String> _firstCorrectSeen = {};
  List<Exercise> _challenge = [];
  int _index = 0;
  int _bossHp = _maxBossHp;
  int _lives = _startingLives;
  int _startingLivesThisAttempt = _startingLives;
  int _secondsLeft = _baseSecondsPerQuestion;
  int _motionVersion = 0;
  bool _answered = false;
  bool _finishing = false;
  bool? _battleWon;
  bool _lastAnswerCorrect = false;
  String _feedback = '';
  _BossMotion _motion = _BossMotion.idle;

  Exercise get _currentExercise => _challenge[_index];

  @override
  void initState() {
    super.initState();
    final upgrades = ref.read(progressProvider).upgrades;
    _secondsPerQuestion = _baseSecondsPerQuestion +
        ((upgrades['timer_crystal'] ?? 0) * 2);
    _damagePerCorrect = (_baseDamagePerCorrect +
            ((upgrades['power_rune'] ?? 0) * 2))
        .clamp(_baseDamagePerCorrect, 15)
        .toInt();
    _startingLivesThisAttempt = _livesForNewAttempt();
    _lives = _startingLivesThisAttempt;
    _secondsLeft = _secondsPerQuestion;
    _challenge = _prepareChallenge(widget.stage.exercises);
    _questionClock = AnimationController(
      vsync: this,
      duration: Duration(seconds: _secondsPerQuestion),
    )
      ..addListener(_syncTimerLabel)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _handleTimeout();
      });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _challenge.isNotEmpty) _startQuestionTimer();
    });
  }

  int _livesForNewAttempt() {
    final hasHeart = ref.read(progressProvider.notifier)
        .consumeInventoryItem('extra_heart');
    return _startingLives + (hasHeart ? 1 : 0);
  }

  List<Exercise> _prepareChallenge(List<Exercise> source) {
    final questions = <Exercise>[];
    for (final exercise in source.where((e) => e.verified && e.type != 'flashcard')) {
      if (exercise.type != 'match' || exercise.pairs.isEmpty) {
        questions.add(exercise);
        continue;
      }

      // Dropdown-based matching questions become one clear multiple-choice
      // question per item during boss fights (e.g. あ has which vowel sound?).
      final rights = exercise.pairs.map((pair) => pair.right).toSet().toList();
      for (var i = 0; i < exercise.pairs.length; i++) {
        final pair = exercise.pairs[i];
        final distractors = rights.where((right) => right != pair.right).toList()
          ..shuffle(math.Random('${exercise.id}_$i'.hashCode));
        final options = <String>[
          pair.right,
          ...distractors.take(rights.length <= 5 ? rights.length : 3),
        ]..shuffle(math.Random('${exercise.id}_options_$i'.hashCode));
        questions.add(Exercise(
          id: '${exercise.id}_boss_pair_$i',
          type: 'multiple_choice',
          prompt: '${pair.left} — which sound or meaning matches?',
          choices: options,
          answerIndex: options.indexOf(pair.right),
          explanation: exercise.explanation.isNotEmpty
              ? exercise.explanation
              : '${pair.left} matches ${pair.right}.',
          verified: true,
          source: exercise.source,
          skill: exercise.skill,
        ));
      }
    }
    questions.shuffle(math.Random());
    return questions;
  }

  void _syncTimerLabel() {
    if (!mounted) return;
    final remaining = ((_secondsPerQuestion * (1 - _questionClock.value)).ceil())
        .clamp(0, _secondsPerQuestion)
        .toInt();
    if (remaining != _secondsLeft) {
      setState(() => _secondsLeft = remaining);
    }
  }

  @override
  void dispose() {
    _questionClock.dispose();
    super.dispose();
  }

  void _triggerMotion(_BossMotion motion) {
    if (!mounted) return;
    setState(() {
      _motion = motion;
      _motionVersion++;
    });
  }

  void _startQuestionTimer() {
    if (_battleWon != null || _finishing || _answered || !mounted) return;
    _questionClock
      ..stop()
      ..duration = Duration(seconds: _secondsPerQuestion)
      ..value = 0;
    setState(() => _secondsLeft = _secondsPerQuestion);
    _questionClock.forward();
  }

  void _recordProgress(Exercise exercise, bool correct) {
    final firstTime = _firstCorrectSeen.add(exercise.id);
    ref.read(progressProvider.notifier).recordExercise(
          sectionId: widget.sectionId,
          correct: correct,
          firstTime: firstTime,
          isReview: true,
          vocabId: exercise.vocabId,
        );
  }

  void _answer(Exercise exercise, dynamic answer) {
    if (_answered || _battleWon != null || _finishing) return;
    _questionClock.stop();
    final correct = AnswerChecker.check(exercise, answer);
    _recordProgress(exercise, correct);
    final updatedHp = correct ? math.max(0, _bossHp - _damagePerCorrect).toInt() : _bossHp;
    final updatedLives = correct ? _lives : _lives - 1;
    setState(() {
      _answered = true;
      _lastAnswerCorrect = correct;
      _bossHp = updatedHp;
      _lives = updatedLives;
      _feedback = correct
          ? 'Direct hit. The guardian loses $_damagePerCorrect HP.'
          : 'The guardian strikes back. You lose one heart.';
    });

    if (updatedHp <= 0) {
      _finishBattle(true);
    } else if (updatedLives <= 0) {
      _finishBattle(false);
    } else {
      _triggerMotion(correct ? _BossMotion.hit : _BossMotion.attack);
    }
  }

  void _handleTimeout() {
    if (_answered || _battleWon != null || _finishing || !mounted) return;
    final exercise = _currentExercise;
    _recordProgress(exercise, false);
    final updatedLives = _lives - 1;
    setState(() {
      _answered = true;
      _lastAnswerCorrect = false;
      _lives = updatedLives;
      _feedback = 'Time ran out. The guardian hits you for one heart.';
    });
    if (updatedLives <= 0) {
      _finishBattle(false);
    } else {
      _triggerMotion(_BossMotion.attack);
    }
  }

  void _finishBattle(bool won) {
    _questionClock.stop();
    if (_battleWon != null || _finishing) return;
    _finishing = true;
    _motion = won ? _BossMotion.victory : _BossMotion.defeat;
    _motionVersion++;
    setState(() {});

    // Let the final impact/reaction play before switching to the results view.
    Future<void>.delayed(const Duration(milliseconds: 760), () {
      if (!mounted) return;
      if (won) {
        ref.read(progressProvider.notifier).completeStage(widget.stage.id);
        ref.read(progressProvider.notifier).recordBossVictory(widget.sectionId);
      }
      setState(() => _battleWon = won);
    });
  }

  void _nextQuestion() {
    if (_battleWon != null || _finishing) return;
    if (_index >= _challenge.length - 1) {
      _finishBattle(false);
      return;
    }
    setState(() {
      _index++;
      _answered = false;
      _feedback = '';
      _lastAnswerCorrect = false;
      _secondsLeft = _secondsPerQuestion;
      _motion = _BossMotion.idle;
    });
    _startQuestionTimer();
  }

  void _restartBattle() {
    _questionClock.stop();
    final newChallenge = _prepareChallenge(widget.stage.exercises);
    final newStartingLives = _livesForNewAttempt();
    setState(() {
      _challenge = newChallenge;
      _index = 0;
      _bossHp = _maxBossHp;
      _startingLivesThisAttempt = newStartingLives;
      _lives = _startingLivesThisAttempt;
      _secondsLeft = _secondsPerQuestion;
      _answered = false;
      _finishing = false;
      _battleWon = null;
      _feedback = '';
      _lastAnswerCorrect = false;
      _motion = _BossMotion.idle;
      _motionVersion++;
    });
    _startQuestionTimer();
  }

  @override
  Widget build(BuildContext context) {
    if (_challenge.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Boss Battle')),
        body: const Center(child: Text('This boss has no verified questions yet.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.stage.levelLabel} · ${ChapterArtwork.bossNameForSection(widget.sectionId)}',
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.outline),
                ),
                child: Text('${math.min(_index + 1, _challenge.length)}/${_challenge.length}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: _battleWon != null
              ? _buildOutcome(context)
              : ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 26),
              children: [
                _AnimatedBossArena(
                  key: const ValueKey('active-boss-arena'),
                  sectionId: widget.sectionId,
                  motion: _motion,
                  eventKey: _motionVersion,
                  height: 290,
                ),
                const SizedBox(height: 12),
                _buildBossHud(context),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text('YOUR TURN',
                        style: AppTheme.caption(context).copyWith(
                          color: AppTheme.indigoInk,
                          fontSize: 10,
                          letterSpacing: 1.4,
                          fontWeight: FontWeight.w900,
                        )),
                    const Spacer(),
                    Icon(Icons.timer_rounded,
                        size: 17,
                        color: _secondsLeft <= 4 ? AppTheme.shu : AppTheme.indigoInk),
                    const SizedBox(width: 5),
                    Text('$_secondsLeft s',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: _secondsLeft <= 4 ? AppTheme.shu : AppTheme.indigoInk,
                        )),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AnimatedBuilder(
                    animation: _questionClock,
                    builder: (context, _) => LinearProgressIndicator(
                      value: (1 - _questionClock.value).clamp(0.0, 1.0).toDouble(),
                      minHeight: 7,
                      color: _secondsLeft <= 4 ? AppTheme.shu : AppTheme.matchaDark,
                      backgroundColor: AppTheme.paperAlt,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 17, 18, 18),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppTheme.outline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('YOUR MOVE',
                          style: AppTheme.caption(context).copyWith(
                            fontSize: 10,
                            letterSpacing: 1.3,
                            color: AppTheme.matchaDark,
                            fontWeight: FontWeight.w900,
                          )),
                      const SizedBox(height: 12),
                      ExerciseView(
                        key: ValueKey(_currentExercise.id),
                        exercise: _currentExercise,
                        onAnswer: (answer) => _answer(_currentExercise, answer),
                        showFeedback: _answered,
                        wasCorrect: _lastAnswerCorrect,
                      ),
                      if (_answered && _battleWon == null && !_finishing) ...[
                        const SizedBox(height: 14),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: Row(
                            key: ValueKey(_lastAnswerCorrect),
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                _lastAnswerCorrect ? Icons.check_circle_rounded : Icons.shield_rounded,
                                size: 20,
                                color: _lastAnswerCorrect ? AppTheme.matchaDark : AppTheme.shu,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _feedback,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    height: 1.3,
                                    color: _lastAnswerCorrect ? AppTheme.matchaDeep : AppTheme.shu,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _nextQuestion,
                            icon: const Icon(Icons.arrow_forward_rounded),
                            label: const Text('Continue'),
                          ),
                        ),
                      ],
                      if (_finishing && _battleWon == null) ...[
                        const SizedBox(height: 16),
                        const Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Correct answers weaken the guardian. A mistake or timeout costs one heart.',
                  style: AppTheme.caption(context),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
        ),
      ),
    );
  }

  Widget _buildBossHud(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDEFF5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.shield_rounded, color: Color(0xFF2E6F8A)),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ChapterArtwork.bossNameForSection(widget.sectionId),
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                    SizedBox(height: 2),
                    Text(ChapterArtwork.regionNameForSection(widget.sectionId),
                        style: TextStyle(fontSize: 11, color: AppTheme.inkMuted)),
                  ],
                ),
              ),
              Text('$_bossHp',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.indigoInk)),
              const Text(' / 100',
                  style: TextStyle(fontSize: 11, color: AppTheme.inkMuted, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: _bossHp / _maxBossHp),
              duration: const Duration(milliseconds: 520),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 11,
                color: _bossHp <= 25 ? AppTheme.shu : const Color(0xFF4B9AC3),
                backgroundColor: const Color(0xFFDDECF0),
              ),
            ),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Text('YOUR HEARTS',
                  style: AppTheme.caption(context).copyWith(
                    fontSize: 10,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w900,
                  )),
              const Spacer(),
              for (var i = 0; i < _startingLivesThisAttempt; i++)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                    child: Icon(
                      i < _lives ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      key: ValueKey(i < _lives),
                      size: 22,
                      color: i < _lives ? AppTheme.shu : AppTheme.locked,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOutcome(BuildContext context) {
    final won = _battleWon == true;
    return SafeArea(
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          _AnimatedBossArena(
            key: ValueKey('outcome-$_motionVersion'),
            sectionId: widget.sectionId,
            motion: won ? _BossMotion.victory : _BossMotion.defeat,
            eventKey: _motionVersion,
            height: 300,
          ),
          const SizedBox(height: 22),
          Icon(
            won ? Icons.workspace_premium_rounded : Icons.favorite_border_rounded,
            size: 55,
            color: won ? AppTheme.matchaDark : AppTheme.shu,
          ),
          const SizedBox(height: 12),
          Text(
            won ? 'Guardian defeated!' : 'The guardian stands firm',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            won
                ? 'You depleted the guardian’s HP. The next unit is now unlocked.'
                : 'You ran out of hearts. Review the lesson levels and challenge the guardian again.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.inkMuted, height: 1.4),
          ),
          const SizedBox(height: 24),
          if (!won)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _restartBattle,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            ),
          if (!won) const SizedBox(height: 9),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.route_rounded),
              label: const Text('Back to the path'),
            ),
          ),
        ],
      ),
    );
  }
}

/// The scene and character are independent SVG assets; canvas effects retain
/// the existing idle and combat animation timing.
class _AnimatedBossArena extends StatefulWidget {
  const _AnimatedBossArena({
    super.key,
    required this.sectionId,
    required this.motion,
    required this.eventKey,
    required this.height,
  });

  final String sectionId;
  final _BossMotion motion;
  final int eventKey;
  final double height;

  @override
  State<_AnimatedBossArena> createState() => _AnimatedBossArenaState();
}

class _AnimatedBossArenaState extends State<_AnimatedBossArena>
    with TickerProviderStateMixin {
  late final AnimationController _idle;
  late final AnimationController _event;

  @override
  void initState() {
    super.initState();
    _idle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
    _event = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
    );
    if (widget.eventKey > 0 && widget.motion != _BossMotion.idle) {
      _event.forward();
    }
  }

  @override
  void didUpdateWidget(covariant _AnimatedBossArena oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.eventKey != widget.eventKey) {
      _event.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _idle.dispose();
    _event.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: widget.height,
        child: LayoutBuilder(
          builder: (context, constraints) => Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: SvgPicture.asset(
                  ChapterArtwork.arenaAssetForSection(widget.sectionId) ??
                      'assets/artwork/arenas/17.svg',
                  fit: BoxFit.cover,
                  semanticsLabel:
                      ChapterArtwork.regionNameForSection(widget.sectionId),
                ),
              ),
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x24101B31),
                        Color(0x10101B31),
                        Color(0x74101B31),
                      ],
                    ),
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: Listenable.merge([_idle, _event]),
                builder: (context, _) => CustomPaint(
                  painter: _BossArenaEffectsPainter(
                    idleProgress: _idle.value,
                    eventProgress: _event.value,
                    motion: widget.motion,
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: Listenable.merge([_idle, _event]),
                builder: (context, _) {
                  final p = Curves.easeOutCubic.transform(_event.value);
                  final bob = math.sin(_idle.value * math.pi * 2) * 3.2;
                  var dx = 0.0;
                  var dy = bob;
                  var rotation = math.sin(_idle.value * math.pi * 2) * 0.006;
                  var scale = 1.12 + math.sin(_idle.value * math.pi * 2) * 0.008;
                  switch (widget.motion) {
                    case _BossMotion.hit:
                      dx = math.sin(_event.value * math.pi * 8) * (1 - _event.value) * 11;
                      rotation += math.sin(_event.value * math.pi * 4) * (1 - _event.value) * 0.035;
                      scale -= math.sin(p * math.pi) * 0.065;
                      break;
                    case _BossMotion.attack:
                      dx = -math.sin(p * math.pi) * 13;
                      dy -= math.sin(p * math.pi) * 17;
                      rotation -= math.sin(p * math.pi) * 0.025;
                      scale += math.sin(p * math.pi) * 0.075;
                      break;
                    case _BossMotion.victory:
                      dy -= math.sin(p * math.pi) * 8;
                      scale += math.sin(p * math.pi) * 0.065;
                      break;
                    case _BossMotion.defeat:
                      dy += math.sin(p * math.pi / 2) * 17;
                      rotation += math.sin(p * math.pi / 2) * 0.07;
                      scale -= math.sin(p * math.pi / 2) * 0.035;
                      break;
                    case _BossMotion.idle:
                      break;
                  }
                  return Transform.translate(
                    offset: Offset(dx, dy),
                    child: Transform.rotate(
                      angle: rotation,
                      child: Transform.scale(
                        scale: scale,
                        child: Center(
                          child: SizedBox(
                            width: constraints.maxWidth * 0.94,
                            height: widget.height * 1.02,
                            child: SvgPicture.asset(
                              ChapterArtwork.bossAssetForSection(
                                    widget.sectionId,
                                  ) ??
                                  'assets/artwork/bosses/17.svg',
                              fit: BoxFit.contain,
                              semanticsLabel: ChapterArtwork.bossNameForSection(
                                widget.sectionId,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.84),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('BOSS ENCOUNTER',
                          style: TextStyle(
                            fontSize: 9,
                            letterSpacing: 1.35,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.indigoInk,
                          )),
                      const SizedBox(height: 2),
                      Text(
                        ChapterArtwork.bossNameForSection(widget.sectionId),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (widget.motion == _BossMotion.hit && _event.value < 0.92)
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _event,
                      builder: (context, _) => Opacity(
                        opacity: (1 - _event.value).clamp(0.0, 0.55).toDouble(),
                        child: const DecoratedBox(
                          decoration: BoxDecoration(color: Color(0x66FFFFFF)),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BossArenaEffectsPainter extends CustomPainter {
  const _BossArenaEffectsPainter({
    required this.idleProgress,
    required this.eventProgress,
    required this.motion,
  });

  final double idleProgress;
  final double eventProgress;
  final _BossMotion motion;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.58);
    final pulse = math.sin(eventProgress * math.pi).abs();

    // Subtle encounter sigils let the chapter illustration remain the backdrop.
    for (var i = 0; i < 3; i++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: center.translate(0, size.height * 0.025 * i),
          width: size.width * (0.38 + i * 0.095),
          height: size.height * (0.36 + i * 0.09),
        ),
        Paint()
          ..color = const Color(0xFFF7DDAA).withValues(alpha: 0.12 - i * 0.025)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1,
      );
    }
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.95),
        width: size.width * 0.62,
        height: 22,
      ),
      Paint()..color = const Color(0x66101C31),
    );

    // Deterministic glowing motes drift at different rates without random rebuilds.
    for (var i = 0; i < 24; i++) {
      final x = (i * 71.0 + 19) % size.width;
      final baseY = (i * 43.0 + 11) % size.height;
      final drift = (idleProgress * (14 + i % 4) + i * 2.3) % 28;
      final y = (baseY + drift) % size.height;
      final radius = 0.9 + (i % 3) * 0.55;
      final color = i.isEven ? const Color(0xFFFFE6A7) : const Color(0xFFB7E8E2);
      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()..color = color.withValues(alpha: 0.35 + (i % 4) * 0.09),
      );
      if (i % 6 == 0) {
        canvas.drawLine(
          Offset(x - radius * 2.4, y),
          Offset(x + radius * 2.4, y),
          Paint()
            ..color = color.withValues(alpha: 0.35)
            ..strokeWidth = 1,
        );
      }
    }

    if (motion == _BossMotion.hit && eventProgress < 0.98) {
      final burstPaint = Paint()
        ..color = const Color(0xFFFFF3D1).withValues(alpha: 0.72 * pulse)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.1;
      canvas.drawCircle(
        center.translate(0, -size.height * 0.07),
        26 + 36 * pulse,
        burstPaint,
      );
      for (var i = 0; i < 10; i++) {
        final angle = i * math.pi * 2 / 10;
        final from = center.translate(
          math.cos(angle) * 24,
          math.sin(angle) * 24 - size.height * 0.07,
        );
        final to = center.translate(
          math.cos(angle) * (37 + pulse * 17),
          math.sin(angle) * (37 + pulse * 17) - size.height * 0.07,
        );
        canvas.drawLine(from, to, burstPaint..strokeWidth = 2.5);
      }
    } else if (motion == _BossMotion.attack && eventProgress < 0.98) {
      final slash = Paint()
        ..color = const Color(0xFFFFE5B2).withValues(alpha: 0.78 * pulse)
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 6;
      final start = Offset(size.width * 0.70, size.height * 0.30);
      final end = Offset(size.width * 0.37, size.height * 0.63);
      canvas.drawLine(start, end, slash);
      canvas.drawLine(
        start.translate(11, 6),
        end.translate(11, 6),
        slash..strokeWidth = 2,
      );
    } else if (motion == _BossMotion.victory && eventProgress < 0.98) {
      final glow = Paint()
        ..color = const Color(0xAAFFE1A0).withValues(alpha: 0.52 * pulse)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      for (var i = 0; i < 3; i++) {
        canvas.drawCircle(center.translate(0, -size.height * 0.06), 42 + i * 18 + pulse * 18, glow);
      }
      for (var i = 0; i < 14; i++) {
        final angle = i * math.pi * 2 / 14;
        final x = center.dx + math.cos(angle) * (70 + pulse * 35);
        final y = center.dy - size.height * 0.06 + math.sin(angle) * (70 + pulse * 35);
        canvas.drawCircle(Offset(x, y), 2.2, Paint()..color = const Color(0xFFFFE8AF).withValues(alpha: 0.8 * pulse));
      }
    } else if (motion == _BossMotion.defeat && eventProgress < 0.98) {
      for (var i = 0; i < 9; i++) {
        final x = size.width * (0.16 + i * 0.085);
        final y = size.height * (0.17 + ((i * 13) % 7) * 0.07) + eventProgress * 35;
        final shard = Path()
          ..moveTo(x, y - 5)
          ..lineTo(x + 4, y + 2)
          ..lineTo(x - 3, y + 5)
          ..close();
        canvas.drawPath(shard, Paint()..color = const Color(0xFFD9E5E0).withValues(alpha: 0.5 * (1 - eventProgress)));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BossArenaEffectsPainter oldDelegate) =>
      oldDelegate.idleProgress != idleProgress ||
      oldDelegate.eventProgress != eventProgress ||
      oldDelegate.motion != motion;
}


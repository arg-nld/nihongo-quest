import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/answer_checker.dart';
import '../../core/lesson_stage_plan.dart';
import '../../models/curriculum_models.dart';
import '../../providers/providers.dart';
import '../exercise/exercise_widgets.dart';
import '../theme.dart';
import 'lesson_results_screen.dart';

enum LessonPhase { practice, quiz }

/// Player for a category-based level. The optional legacy flow remains usable
/// by existing routes/tests, while the map path launches one [LessonStage] at
/// a time and enforces its accuracy gate.
class LessonPlayerScreen extends ConsumerStatefulWidget {
  const LessonPlayerScreen({
    super.key,
    required this.sectionId,
    required this.lesson,
    this.stage,
  });

  final String sectionId;
  final Lesson lesson;
  final LessonStage? stage;

  @override
  ConsumerState<LessonPlayerScreen> createState() => _LessonPlayerScreenState();
}

class _LessonPlayerScreenState extends ConsumerState<LessonPlayerScreen> {
  static const double _passAccuracy = 0.8;

  int _phaseIndex = 0;
  int _exerciseIndex = 0;
  int _attemptNumber = 0;
  final Map<String, dynamic> _answers = {};
  final Map<String, bool> _results = {};
  bool _submitted = false;
  bool _stageResultsShown = false;
  bool _stagePassed = false;
  int _stageCorrect = 0;
  final Set<String> _firstCorrectSeen = {};
  late final List<Exercise>? _shuffledStageExercises;

  @override
  void initState() {
    super.initState();
    if (widget.stage != null) {
      _shuffledStageExercises = [...widget.stage!.exercises]
        ..shuffle(Random());
    } else {
      _shuffledStageExercises = null;
    }
  }

  bool get _isStaged => widget.stage != null;

  List<Exercise> get _currentList {
    if (widget.stage != null) {
      return (_shuffledStageExercises ?? const <Exercise>[])
          .where((e) => e.verified && e.type != 'flashcard')
          .toList();
    }
    return _phaseIndex == 1
        ? widget.lesson.quiz
        : widget.lesson.exercises.where((e) => e.type != 'flashcard').toList();
  }

  LessonPhase get _phase =>
      _phaseIndex == 1 ? LessonPhase.quiz : LessonPhase.practice;

  void _record(Exercise ex, dynamic answer) {
    // A staged level accepts exactly one answer per question, including misses.
    if (_isStaged && _results.containsKey(ex.id)) return;
    final correct = AnswerChecker.check(ex, answer);
    setState(() {
      _answers[ex.id] = answer;
      _results[ex.id] = correct;
    });
    final firstTime = _firstCorrectSeen.add(ex.id);
    ref.read(progressProvider.notifier).recordExercise(
          sectionId: widget.sectionId,
          correct: correct,
          firstTime: firstTime,
          isReview: widget.stage?.isReview ?? false,
          vocabId: ex.vocabId,
        );
  }

  void _next() {
    final list = _currentList;
    if (_exerciseIndex < list.length - 1) {
      setState(() => _exerciseIndex++);
    } else if (_isStaged) {
      _finishStage();
    } else if (_phaseIndex == 0) {
      setState(() {
        _phaseIndex = 1;
        _exerciseIndex = 0;
        _submitted = false;
      });
    } else {
      _finishLegacyLesson();
    }
  }

  void _finishStage() {
    final list = _currentList;
    final correct = list.where((e) => _results[e.id] == true).length;
    final passed = list.isNotEmpty && correct / list.length >= _passAccuracy;
    if (passed) {
      ref.read(progressProvider.notifier).completeStage(widget.stage!.id);
    }
    setState(() {
      _stageCorrect = correct;
      _stagePassed = passed;
      _stageResultsShown = true;
    });
  }

  void _restartStage() {
    setState(() {
      _attemptNumber++;
      _exerciseIndex = 0;
      _answers.clear();
      _results.clear();
      _stageResultsShown = false;
      _stagePassed = false;
      _stageCorrect = 0;
    });
  }

  void _finishLegacyLesson() {
    final quiz = widget.lesson.quiz;
    final score = quiz.where((q) => _results[q.id] == true).length;
    final unlocked = ref
        .read(progressProvider.notifier)
        .recordQuizResult(widget.sectionId, score, quiz.length);
    Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => LessonResultsScreen(
            sectionId: widget.sectionId,
            title: widget.lesson.title,
            score: score,
            total: quiz.length,
            practiceCorrect: _results.values.where((r) => r).length,
            practiceTotal: _results.length,
            unlockedAchievements: unlocked)));
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(progressProvider.select((p) => p.settings));
    final immediateFeedback = settings.immediateFeedback;
    final isQuiz = !_isStaged && _phaseIndex == 1;
    final list = _currentList;

    if (_isStaged && _stageResultsShown) return _buildStageResults(context, list);

    if (list.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_isStaged) {
          _finishStage();
        } else {
          _next();
        }
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final ex = list[_exerciseIndex];
    final answered = _results.containsKey(ex.id);
    final correct = _results[ex.id] ?? false;
    // Staged learning always locks an answered question, independent of the
    // user's optional immediate-feedback setting. Legacy quiz settings remain.
    final showFeedback = _isStaged
        ? answered
        : answered && (immediateFeedback || (isQuiz && _submitted));

    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isStaged
              ? '${widget.stage!.levelLabel} — ${widget.stage!.title}'
              : '${widget.lesson.title} — ${_phase == LessonPhase.quiz ? "Quiz" : "Practice"}'),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 780),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
            Text(
              _isStaged
                  ? 'Question ${_exerciseIndex + 1} / ${list.length}'
                  : 'Exercise ${_exerciseIndex + 1} / ${list.length}',
              style: AppTheme.caption(context),
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: (_exerciseIndex + 1) / list.length,
              minHeight: 4,
            ),
            if (_isStaged) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.all_inclusive, size: 16),
                  const SizedBox(width: 6),
                  Text('No timer · No lives', style: AppTheme.caption(context)),
                  const Spacer(),
                  Text('Pass with 80% accuracy', style: AppTheme.caption(context)),
                ],
              ),
            ],
            const SizedBox(height: 16),
            ExerciseView(
              key: ValueKey('${ex.id}-$_attemptNumber'),
              exercise: ex,
              onAnswer: (answer) => _record(ex, answer),
              showFeedback: showFeedback,
              wasCorrect: correct,
            ),
            if (showFeedback) ...[
              const SizedBox(height: 12),
              Card(
                color: correct
                    ? AppTheme.matcha.withValues(alpha: 0.18)
                    : AppTheme.shuSoft,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            correct ? Icons.check_circle : Icons.cancel,
                            color: correct ? AppTheme.matchaDark : AppTheme.shu,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            correct ? 'Correct!' : 'Not quite',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      if (ex.explanation.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(ex.explanation),
                      ],
                      if (ex.source != null) ...[
                        const SizedBox(height: 6),
                        Text('Source: ${ex.source}',
                            style: AppTheme.caption(context)),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                if (isQuiz && answered && !_submitted && immediateFeedback)
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: () => setState(() => _submitted = true),
                      child: const Text('Submit quiz'),
                    ),
                  )
                else
                  Expanded(
                    child: FilledButton(
                      onPressed: answered || ex.type == 'flashcard' ? _next : null,
                      child: Text(_isStaged && _exerciseIndex == list.length - 1
                          ? 'Check Accuracy'
                          : (!_isStaged && _exerciseIndex == list.length - 1 && _phaseIndex == 1
                              ? 'Finish'
                              : 'Continue')),
                    ),
                  ),
                if (!_isStaged) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Retry this exercise',
                    onPressed: answered
                        ? () => setState(() {
                              _attemptNumber++;
                              _results.remove(ex.id);
                              _answers.remove(ex.id);
                            })
                        : null,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ],
            ),
            if (!answered && !isQuiz && !_isStaged)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Answer to continue. You can retry without restarting the lesson.',
                  style: AppTheme.caption(context),
                ),
              ),
            if (_isStaged && answered)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'This answer is locked. Continue to the next question; missed questions cannot be repeated in this run.',
                  style: AppTheme.caption(context),
                ),
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStageResults(BuildContext context, List<Exercise> list) {
    final total = list.length;
    final accuracy = total == 0 ? 0.0 : _stageCorrect / total;
    return Scaffold(
      appBar: AppBar(title: Text('${widget.stage!.levelLabel} Results')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _stagePassed ? Icons.check_circle : Icons.replay_circle_filled,
                  size: 76,
                  color: _stagePassed ? AppTheme.matchaDark : AppTheme.sakuraDeep,
                ),
                const SizedBox(height: 12),
                Text(
                  _stagePassed ? 'Level cleared!' : 'Not enough accuracy yet',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text('${_stageCorrect} / $total correct · ${(accuracy * 100).round()}% accuracy'),
                const SizedBox(height: 8),
                const Text('You need at least 80% to unlock the next level.',
                    textAlign: TextAlign.center),
                const SizedBox(height: 24),
                if (_stagePassed)
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.route),
                    label: const Text('Back to Level Path'),
                  )
                else ...[
                  FilledButton.icon(
                    onPressed: _restartStage,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Restart Level'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Return to Level Path'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

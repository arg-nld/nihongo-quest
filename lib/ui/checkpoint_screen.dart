import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/answer_checker.dart';
import '../models/curriculum_models.dart';
import '../providers/providers.dart';
import 'exercise/exercise_widgets.dart';
import 'lesson/lesson_results_screen.dart';
import 'theme.dart';
import 'widgets/common.dart';

/// Cumulative Review: an optional cumulative exam mixed from every completed lesson's
/// scored exercises. It is optional by design — it never gates progression,
/// unlocks nothing, and pays review-style rewards only.
class CheckpointScreen extends ConsumerStatefulWidget {
  const CheckpointScreen({super.key});

  @override
  ConsumerState<CheckpointScreen> createState() => _CheckpointScreenState();
}

class _CheckpointScreenState extends ConsumerState<CheckpointScreen> {
  static const int _targetItems = 12;
  static const int _minCompletedLessons = 2;

  List<Exercise> _challenge = [];
  final Map<String, dynamic> _answers = {};
  final Map<String, bool> _results = {};
  final Set<String> _firstCorrectSeen = {};
  int _index = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(curriculumRepositoryProvider);
    final sections = await repo.loadSections();
    final lessons = await repo.loadAllLessons();
    final progress = ref.read(progressProvider).lessons;
    final completed = sections
        .where((s) =>
            s.type != 'reference' &&
            (progress[s.id]?.completed ?? false))
        .map((s) => s.id)
        .toList();
    // One shuffled pool of scored exercises per completed lesson...
    final pools = [
      for (final id in completed)
        (lessons[id]?.scoredExercises ?? const <Exercise>[])
            .where((e) => e.type != 'flashcard')
            .toList()
          ..shuffle(),
    ];
    // ...then pick round-robin so the mix stays cumulative across lessons.
    final picked = <Exercise>[];
    outer:
    for (var round = 0; picked.length < _targetItems; round++) {
      var gotAny = false;
      for (final pool in pools) {
        if (round < pool.length) {
          picked.add(pool[round]);
          gotAny = true;
          if (picked.length >= _targetItems) break outer;
        }
      }
      if (!gotAny) break;
    }
    if (mounted) {
      setState(() {
        _challenge = picked;
        _loading = false;
      });
    }
  }

  void _answer(Exercise ex, dynamic answer) {
    final correct = AnswerChecker.check(ex, answer);
    _answers[ex.id] = answer;
    _results[ex.id] = correct;
    final firstTime = _firstCorrectSeen.add(ex.id);
    // Cumulative replay of already-taught material: review-style rewards,
    // and linked vocab gets a fresh SRS datapoint.
    ref.read(progressProvider.notifier).recordExercise(
          sectionId: 'checkpoint',
          correct: correct,
          firstTime: firstTime,
          isReview: true,
          vocabId: ex.vocabId,
        );
  }

  void _finish() {
    final score = _results.values.where((r) => r).length;
    final unlocked = ref
        .read(progressProvider.notifier)
        .recordCheckpointResult(score, _challenge.length);
    Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => LessonResultsScreen(
            sectionId: 'checkpoint',
            title: 'Cumulative Review',
            score: score,
            total: _challenge.length,
            practiceCorrect: score,
            practiceTotal: _challenge.length,
            unlockedAchievements: unlocked)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          body: AppLoadingState(message: 'Preparing the cumulative review…'));
    }
    if (_challenge.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cumulative Review')),
        body: AppEmptyState(
          icon: Icons.sports_martial_arts,
          title: 'The review is not ready',
          message:
              'Complete at least $_minCompletedLessons lessons to unlock this review. '
              'Keep studying!',
          actionLabel: 'Back',
          onAction: () => Navigator.of(context).pop(),
        ),
      );
    }
    final ex = _challenge[_index];
    final answered = _results.containsKey(ex.id);
    final correct = _results[ex.id] ?? false;
    // Exam-style review: no feedback while answering; the results screen
    // delivers the verdict. The per-exercise retry stays available.
    return Scaffold(
      appBar: AppBar(
        title: Text('Cumulative Review — ${_index + 1}/${_challenge.length}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          LinearProgressIndicator(
            value: (_index + 1) / _challenge.length,
            minHeight: 4,
          ),
          const SizedBox(height: 16),
          ExerciseView(
            exercise: ex,
            onAnswer: (answer) => _answer(ex, answer),
            showFeedback: false,
            wasCorrect: correct,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: answered
                      ? (_index == _challenge.length - 1 ? _finish : _next)
                      : null,
                  child: Text(_index == _challenge.length - 1
                      ? 'Finish Review'
                      : 'Continue'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Retry this exercise',
                onPressed: answered
                    ? () => setState(() {
                          _results.remove(ex.id);
                          _answers.remove(ex.id);
                        })
                    : null,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          if (!answered)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Exam rules: no feedback until the results screen — '
                'one answer per question.',
                style: AppTheme.caption(context),
              ),
            ),
        ],
      ),
    );
  }

  void _next() {
    setState(() => _index++);
  }
}

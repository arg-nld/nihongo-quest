import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/lesson_stage_plan.dart';
import '../../models/curriculum_models.dart';
import '../../providers/providers.dart';
import 'stage_briefing_screen.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Section overview and its sequential, category-based level path.
class LessonOverviewScreen extends ConsumerStatefulWidget {
  const LessonOverviewScreen({super.key, required this.sectionId});
  final String sectionId;

  @override
  ConsumerState<LessonOverviewScreen> createState() =>
      _LessonOverviewScreenState();
}

class _LessonOverviewScreenState extends ConsumerState<LessonOverviewScreen> {
  Section? _section;
  Lesson? _lesson;
  List<String> _problems = const [];
  bool _loading = true;
  bool _isReference = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(curriculumRepositoryProvider);
    final sections = await repo.loadSections();
    final section = sections.where((s) => s.id == widget.sectionId).firstOrNull;
    final lesson = await repo.loadLesson(widget.sectionId);
    final problems = await repo.problemsFor(widget.sectionId);
    if (mounted) {
      setState(() {
        _section = section;
        _isReference = section?.type == 'reference';
        _lesson = lesson;
        _problems = problems;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(progressProvider.select((p) => p.settings));
    final progress = ref.watch(progressProvider);
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final lesson = _lesson;
    if (lesson == null) {
      return Scaffold(
        appBar: AppBar(title: Text(_section?.title ?? widget.sectionId)),
        body: const Center(child: Text('This section has no interactive content.')),
      );
    }
    final stages = _isReference || _section == null
        ? const <LessonStage>[]
        : LessonStagePlan.build(section: _section!, lesson: lesson);
    final sectionComplete = progress.lessons[widget.sectionId]?.completed ?? false;
    final clearedStageCount = sectionComplete
        ? stages.length
        : stages.where((stage) => progress.completedStageIds.contains(stage.id)).length;

    return Scaffold(
      appBar: AppBar(title: Text(lesson.title)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
          if (_problems.isNotEmpty)
            Card(
              color: Colors.orange.shade50,
              child: ListTile(
                leading: const Icon(Icons.warning_amber),
                title: const Text('Content warnings'),
                subtitle: Text(_problems.join('\n')),
              ),
            ),
          SectionHeader(_isReference ? 'About this library' : 'Goals'),
          if (_isReference)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Browse useful reference material at any time. This area has no scored levels and never affects lesson unlocks or review scheduling.',
              ),
            )
          else
            ...lesson.objectives.map((objective) => ListTile(
                  leading: const Icon(Icons.check_circle_outline, size: 20),
                  title: Text(objective),
                  dense: true,
                )),
          if (!_isReference) ...[
            const SizedBox(height: 8),
            SectionHeader('Level Path · $clearedStageCount/${stages.length} cleared'),
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Learn one category at a time, pass the mastery review, then defeat the boss to unlock the next unit.',
              ),
            ),
            for (var i = 0; i < stages.length; i++)
              _StagePathTile(
                stage: stages[i],
                isCompleted: progress.completedStageIds.contains(stages[i].id),
                isUnlocked: i == 0 ||
                    sectionComplete ||
                    progress.completedStageIds.contains(stages[i - 1].id),
                onTap: () => _openStage(lesson, stages[i]),
              ),
            const SizedBox(height: 12),
            ExpansionTile(
              leading: const Icon(Icons.translate),
              title: Text('Vocabulary (${lesson.vocab.length})'),
              subtitle: const Text('Browse words from this unit'),
              children: _vocabularyChildren(lesson, settings.showRomaji),
            ),
            ExpansionTile(
              leading: const Icon(Icons.auto_stories),
              title: Text('Grammar (${lesson.grammar.length})'),
              subtitle: const Text('Review patterns and examples'),
              children: _grammarChildren(lesson),
            ),
          ] else ...[
            SectionHeader('Vocabulary (${lesson.vocab.length})'),
            ..._vocabularyChildren(lesson, settings.showRomaji),
            SectionHeader('Grammar (${lesson.grammar.length})'),
            ..._grammarChildren(lesson),
          ],
          if (_isReference)
            Card(
              color: Colors.blue.shade50,
              child: const ListTile(
                leading: Icon(Icons.menu_book),
                title: Text('Reference material'),
                subtitle: Text(
                  'Browse freely — nothing here is scored, scheduled for review, or required to unlock lessons.',
                ),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _vocabularyChildren(Lesson lesson, bool showRomaji) => [
        for (final vocab in lesson.vocab)
          ListTile(
            title: JapaneseText(
              japanese: vocab.kanji != null
                  ? '${vocab.japanese} (${vocab.kanji})'
                  : vocab.japanese,
              romaji: vocab.romaji,
              showRomaji: showRomaji,
            ),
            subtitle: Text(vocab.english),
            trailing: vocab.verified ? null : const Icon(Icons.help_outline),
          ),
      ];

  List<Widget> _grammarChildren(Lesson lesson) => [
        for (final grammar in lesson.grammar)
          Card(
            margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(grammar.title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(grammar.pattern,
                      style: const TextStyle(
                          fontStyle: FontStyle.italic, color: Colors.black54)),
                  const SizedBox(height: 4),
                  Text(grammar.explanation),
                  for (final example in grammar.examples) ...[
                    const SizedBox(height: 6),
                    Text('${example.japanese}  ·  ${example.romaji}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(example.english),
                  ],
                ],
              ),
            ),
          ),
      ];

  void _openStage(Lesson lesson, LessonStage stage) {
    if (_section == null) return;
    ref.read(progressProvider.notifier).registerVocab(
          lesson.vocab.map((v) => v.id).toList(),
          sectionId: widget.sectionId,
        );
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => StageBriefingScreen(
        sectionId: widget.sectionId,
        lesson: lesson,
        stage: stage,
      ),
    ));
  }
}

class _StagePathTile extends StatelessWidget {
  const _StagePathTile({
    required this.stage,
    required this.isCompleted,
    required this.isUnlocked,
    required this.onTap,
  });

  final LessonStage stage;
  final bool isCompleted;
  final bool isUnlocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final boss = stage.kind == LessonStageKind.boss;
    final review = stage.kind == LessonStageKind.review;
    final color = isCompleted
        ? AppTheme.matchaDark
        : boss
            ? AppTheme.shu
            : AppTheme.indigoInk;
    final icon = isCompleted
        ? Icons.check_circle
        : !isUnlocked
            ? Icons.lock_outline
            : boss
                ? Icons.sports_martial_arts
                : review
                    ? Icons.auto_awesome
                    : Icons.school_outlined;

    return Opacity(
      opacity: isUnlocked ? 1 : 0.58,
      child: Card(
        color: boss && isUnlocked ? const Color(0xFFFFF0E8) : null,
        margin: const EdgeInsets.symmetric(vertical: 5),
        child: ListTile(
          onTap: isUnlocked ? onTap : null,
          leading: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              border: Border.all(color: color.withValues(alpha: 0.65)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: boss
                ? Icon(icon, color: color, size: 27)
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: color, size: 19),
                      const SizedBox(height: 1),
                      Text(stage.levelLabel,
                          style: TextStyle(
                              color: color,
                              fontSize: 9,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
          ),
          title: Row(
            children: [
              Expanded(child: Text(stage.title)),
              if (boss)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.shu.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('BOSS',
                      style: TextStyle(
                          color: AppTheme.shu,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.7)),
                ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              isCompleted
                  ? 'Cleared · ${stage.exercises.length} questions'
                  : !isUnlocked
                      ? 'Complete the previous level to unlock'
                      : boss
                          ? 'Defeat the guardian · ${stage.exercises.length} possible questions'
                          : '${stage.exercises.length} questions · ${stage.subtitle}',
            ),
          ),
          trailing: Icon(
            isUnlocked ? Icons.chevron_right : Icons.lock,
            color: isUnlocked ? color : AppTheme.locked,
          ),
        ),
      ),
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/lesson_stage_plan.dart';
import '../../models/curriculum_models.dart';
import '../../providers/providers.dart';
import '../theme.dart';
import 'lesson_overview_screen.dart';
import 'stage_briefing_screen.dart';

/// A winding, tappable map of every level inside one curriculum unit.
class LevelMapScreen extends ConsumerStatefulWidget {
  const LevelMapScreen({super.key, required this.sectionId});
  final String sectionId;

  @override
  ConsumerState<LevelMapScreen> createState() => _LevelMapScreenState();
}

class _LevelMapScreenState extends ConsumerState<LevelMapScreen> {
  late Future<(Section?, Lesson?)> _data;

  @override
  void initState() {
    super.initState();
    _data = _load();
  }

  Future<(Section?, Lesson?)> _load() async {
    final repo = ref.read(curriculumRepositoryProvider);
    final sections = await repo.loadSections();
    final matches = sections.where((s) => s.id == widget.sectionId);
    if (matches.isEmpty) return (null, null);
    final section = matches.first;
    return (section, await repo.loadLesson(section.id));
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(progressProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Level Map')),
      body: FutureBuilder<(Section?, Lesson?)>(
        future: _data,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final (section, lesson) = snapshot.data!;
          if (section == null || lesson == null) {
            return const Center(child: Text('This section has no level content.'));
          }
          final stages = LessonStagePlan.build(section: section, lesson: lesson);
          final sectionComplete = progress.lessons[section.id]?.completed ?? false;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(section.title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text('Follow the path, clear the review, then defeat the boss.',
                  style: AppTheme.caption(context)),
              const SizedBox(height: 18),
              for (var i = 0; i < stages.length; i++) ...[
                Align(
                  alignment: i.isEven ? Alignment.centerLeft : Alignment.centerRight,
                  child: SizedBox(
                    width: math.min(300.0, MediaQuery.sizeOf(context).width * .76),
                    child: _LevelNode(
                      stage: stages[i],
                      completed: sectionComplete || progress.completedStageIds.contains(stages[i].id),
                      unlocked: i == 0 || sectionComplete || progress.completedStageIds.contains(stages[i - 1].id),
                      onTap: () => _open(section.id, lesson, stages[i]),
                    ),
                  ),
                ),
                if (i != stages.length - 1)
                  Padding(
                    padding: EdgeInsets.only(left: i.isEven ? 64 : 0, right: i.isEven ? 0 : 64),
                    child: const SizedBox(height: 34, child: Icon(Icons.south, color: AppTheme.indigoSoft)),
                  ),
              ],
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => LessonOverviewScreen(sectionId: section.id))),
                icon: const Icon(Icons.menu_book),
                label: const Text('View lesson content'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _open(String sectionId, Lesson lesson, LessonStage stage) {
    final progress = ref.read(progressProvider);
    final sectionComplete = progress.lessons[sectionId]?.completed ?? false;
    final stages = LessonStagePlan.build(
      section: Section(
        id: sectionId, order: 0, title: lesson.title, subtitle: '', type: 'lesson',
        area: '', pages: '', contentFile: ''),
      lesson: lesson,
    );
    final index = stages.indexWhere((s) => s.id == stage.id);
    final unlocked = index <= 0 || sectionComplete ||
        progress.completedStageIds.contains(stages[index - 1].id);
    if (!unlocked) return;
    ref.read(progressProvider.notifier).registerVocab(
      lesson.vocab.map((v) => v.id).toList(), sectionId: sectionId);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => StageBriefingScreen(
        sectionId: sectionId,
        lesson: lesson,
        stage: stage,
      ),
    ));
  }
}

class _LevelNode extends StatelessWidget {
  const _LevelNode({required this.stage, required this.completed, required this.unlocked, required this.onTap});
  final LessonStage stage;
  final bool completed;
  final bool unlocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final boss = stage.isBoss;
    final review = stage.isReview;
    final color = completed ? AppTheme.matchaDark : boss ? AppTheme.shu : AppTheme.indigoInk;
    return Opacity(
      opacity: unlocked ? 1 : .48,
      child: Card(
        color: boss ? const Color(0xFFFFF0E8) : null,
        child: ListTile(
          onTap: unlocked ? onTap : null,
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: .14),
            child: Icon(completed ? Icons.check_circle : boss ? Icons.sports_martial_arts : review ? Icons.auto_awesome : Icons.school, color: color),
          ),
          title: Text('${stage.levelLabel} · ${stage.title}'),
          subtitle: Text(completed ? 'Cleared' : unlocked ? '${stage.exercises.length} questions' : 'Locked'),
          trailing: Icon(unlocked ? Icons.chevron_right : Icons.lock_outline, color: color),
        ),
      ),
    );
  }
}

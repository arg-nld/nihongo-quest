import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/lesson_stage_plan.dart';
import '../models/curriculum_models.dart';
import '../providers/providers.dart';
import 'lesson/stage_briefing_screen.dart';

/// Developer-only stage picker. It bypasses stage locks without changing saves.
class DevStagePickerScreen extends ConsumerStatefulWidget {
  const DevStagePickerScreen({super.key});

  @override
  ConsumerState<DevStagePickerScreen> createState() => _DevStagePickerScreenState();
}

class _DevStagePickerScreenState extends ConsumerState<DevStagePickerScreen> {
  List<Section> _sections = [];
  Section? _section;
  Lesson? _lesson;
  List<LessonStage> _stages = [];
  String? _stageId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final sections = await ref.read(curriculumRepositoryProvider).loadSections();
    final playable = sections.where((s) => s.type != 'reference').toList();
    if (!mounted) return;
    setState(() { _sections = playable; _loading = false; });
    if (playable.isNotEmpty) await _selectSection(playable.first.id);
  }

  Future<void> _selectSection(String id) async {
    final section = _sections.firstWhere((s) => s.id == id);
    final lesson = await ref.read(curriculumRepositoryProvider).loadLesson(id);
    if (!mounted) return;
    final stages = lesson == null ? <LessonStage>[] : LessonStagePlan.build(section: section, lesson: lesson);
    setState(() {
      _section = section;
      _lesson = lesson;
      _stages = stages;
      _stageId = stages.isEmpty ? null : stages.first.id;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Developer Stage Picker')),
    body: _loading
      ? const Center(child: CircularProgressIndicator())
      : ListView(padding: const EdgeInsets.all(20), children: [
          const Text('Developer tools', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('Launch any stage directly without unlocking earlier levels. This does not mark stages complete.'),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: _section?.id,
            decoration: const InputDecoration(labelText: 'Lesson / chapter', border: OutlineInputBorder()),
            items: [for (final s in _sections) DropdownMenuItem(value: s.id, child: Text(s.title, overflow: TextOverflow.ellipsis))],
            onChanged: (id) { if (id != null) _selectSection(id); },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _stageId,
            decoration: const InputDecoration(labelText: 'Stage', border: OutlineInputBorder()),
            items: [for (final s in _stages) DropdownMenuItem(value: s.id, child: Text('${s.levelLabel} · ${s.title}', overflow: TextOverflow.ellipsis))],
            onChanged: (id) => setState(() => _stageId = id),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _section == null || _lesson == null || _stageId == null ? null : _launch,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Launch selected stage'),
          ),
        ]),
  );

  void _launch() {
    final section = _section!;
    final lesson = _lesson!;
    final stage = _stages.firstWhere((s) => s.id == _stageId);
    ref.read(progressProvider.notifier).registerVocab(lesson.vocab.map((v) => v.id).toList(), sectionId: section.id);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => StageBriefingScreen(
      sectionId: section.id,
      lesson: lesson,
      stage: stage,
    )));
  }
}

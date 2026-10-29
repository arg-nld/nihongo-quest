import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_quest/core/lesson_stage_plan.dart';
import 'package:nihongo_quest/models/curriculum_models.dart';

void main() {
  late List<Map<String, dynamic>> sectionData;

  setUpAll(() {
    sectionData = (jsonDecode(
      File('assets/curriculum/curriculum.json').readAsStringSync(),
    ) as List)
        .cast<Map<String, dynamic>>();
  });

  Section sectionFor(String id) =>
      Section.fromJson(sectionData.firstWhere((section) => section['id'] == id));

  Lesson lessonFor(String id) {
    final section = sectionFor(id);
    final data = jsonDecode(
      File('assets/curriculum/${section.contentFile}').readAsStringSync(),
    ) as Map<String, dynamic>;
    return Lesson.fromJson(data);
  }

  test('Pre-Lesson A is split into category levels, review, then boss', () {
    final section = sectionFor('pre_a');
    final lesson = lessonFor('pre_a');
    final stages = LessonStagePlan.build(section: section, lesson: lesson);

    expect(stages.length, greaterThanOrEqualTo(5));
    expect(stages.first.levelLabel, '1-1');
    expect(stages.first.title, 'Writing Systems');
    expect(stages.any((stage) => stage.title.startsWith('Pronunciation')), isTrue);
    expect(stages.any((stage) => stage.title.startsWith('Sound Patterns')), isTrue);
    expect(stages[stages.length - 2].kind, LessonStageKind.review);
    expect(stages.last.kind, LessonStageKind.boss);
    expect(stages.last.levelLabel, endsWith('-${stages.length}'));
  });

  test('practice items retain their stages and short levels get reinforcement questions', () {
    final section = sectionFor('lesson_01');
    final lesson = lessonFor('lesson_01');
    final stages = LessonStagePlan.build(section: section, lesson: lesson);
    final practice = stages.where((s) => s.kind == LessonStageKind.practice).toList();
    final stagedIds = practice.expand((s) => s.exercises).map((e) => e.id).toList();
    final eligibleIds = lesson.exercises
        .where((e) => e.verified && e.type != 'flashcard')
        .map((e) => e.id)
        .toSet();

    expect(stagedIds.toSet(), containsAll(eligibleIds),
        reason: 'every authored practice question must remain in the stage path');
    expect(practice.every((stage) => stage.exercises.length >= 5 && stage.exercises.length <= 9), isTrue,
        reason: 'short stages need reinforcement questions so 80% accuracy is attainable');
    expect(stagedIds.length, greaterThan(eligibleIds.length),
        reason: 'supplemental reinforcement questions should be allowed to recur across stages');
    expect(
      LessonStagePlan.build(section: section, lesson: lesson).map((s) => s.id),
      stages.map((s) => s.id),
      reason: 'stage IDs should remain stable across app loads',
    );
    expect(stages.last.isBoss, isTrue);
  });

  test('every learning unit ends with review then boss and has usable practice nodes', () {
    for (final sectionJson in sectionData.where((s) => s['type'] != 'reference')) {
      final section = Section.fromJson(sectionJson);
      final lesson = lessonFor(section.id);
      final stages = LessonStagePlan.build(section: section, lesson: lesson);
      final practice = stages.where((s) => s.kind == LessonStageKind.practice);

      expect(stages, isNotEmpty, reason: '${section.id} has no level path');
      expect(stages[stages.length - 2].kind, LessonStageKind.review,
          reason: '${section.id} must place mastery review before boss');
      expect(stages.last.kind, LessonStageKind.boss,
          reason: '${section.id} must end with a boss');
      expect(
        practice.every((stage) => stage.exercises.length >= 5 && stage.exercises.length <= 9),
        isTrue,
        reason: '${section.id} has a practice level with poor accuracy precision',
      );
    }
  });

  test('curriculum sections retain the original generated map-stage count', () {
    var totalStages = 0;
    for (final sectionJson in sectionData.where((s) => s['type'] != 'reference')) {
      final section = Section.fromJson(sectionJson);
      final lesson = lessonFor(section.id);
      totalStages += LessonStagePlan.build(section: section, lesson: lesson).length;
    }
    // The Reference Library contributes one non-stage map stop, making the visible total 163.
    expect(totalStages, 162);
  });

  test('Reference Library never generates scored levels or a boss', () {
    final section = sectionFor('reference');
    final lesson = lessonFor('reference');
    expect(LessonStagePlan.build(section: section, lesson: lesson), isEmpty);
  });
}

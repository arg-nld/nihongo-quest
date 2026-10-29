import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nihongo_quest/core/lesson_stage_plan.dart';
import 'package:nihongo_quest/data/progress_repository.dart';
import 'package:nihongo_quest/models/curriculum_models.dart';
import 'package:nihongo_quest/providers/providers.dart';
import 'package:nihongo_quest/ui/boss_battle_screen.dart';
import 'package:nihongo_quest/ui/exercise/exercise_widgets.dart';
import 'package:nihongo_quest/ui/lesson/lesson_player_screen.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<SharedPreferences> preferences() => SharedPreferences.getInstance();

  testWidgets('a staged level locks each answer and restarts after a failed score',
      (tester) async {
    final prefs = await preferences();
    const first = Exercise(
      id: 'stage_q1',
      type: 'multiple_choice',
      prompt: 'Choose the correct answer for question one.',
      choices: ['Correct one', 'Wrong one'],
      answerIndex: 0,
      explanation: 'The first choice is correct.',
      verified: true,
    );
    const second = Exercise(
      id: 'stage_q2',
      type: 'multiple_choice',
      prompt: 'Choose the correct answer for question two.',
      choices: ['Correct two', 'Wrong two'],
      answerIndex: 0,
      explanation: 'The first choice is correct.',
      verified: true,
    );
    const lesson = Lesson(
      sectionId: 'test_lesson',
      title: 'Test Lesson',
      subtitle: '',
      pages: '',
      vocab: [],
      grammar: [],
      exercises: [first, second],
      quiz: [],
      summary: '',
    );
    const stage = LessonStage(
      id: 'test_lesson_stage_1',
      levelLabel: '1-1',
      title: 'Word Meanings',
      subtitle: '',
      kind: LessonStageKind.practice,
      exercises: [first, second],
    );

    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      progressRepositoryProvider.overrideWith(
        (ref) => SharedPreferencesProgressRepository(prefs),
      ),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: LessonPlayerScreen(
          sectionId: 'test_lesson',
          lesson: lesson,
          stage: stage,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('1-1 — Word Meanings'), findsOneWidget);
    expect(find.text('No timer · No lives'), findsOneWidget);
    await tester.tap(find.text('Wrong one'));
    await tester.pumpAndSettle();
    expect(find.textContaining('This answer is locked.'), findsNothing);
    final pendingContinue = find.widgetWithText(FilledButton, 'Continue');
    expect(tester.widget<FilledButton>(pendingContinue).onPressed, isNull);
    await tester.tap(find.widgetWithText(FilledButton, 'Confirm answer'));
    await tester.pumpAndSettle();

    expect(find.textContaining('This answer is locked.'), findsOneWidget);
    expect(find.byTooltip('Retry this exercise'), findsNothing);
    final continueButton = find.widgetWithText(FilledButton, 'Continue');
    expect(tester.widget<FilledButton>(continueButton).onPressed, isNotNull);
    await tester.tap(continueButton);
    await tester.pumpAndSettle();
    expect(find.text('Choose the correct answer for question two.'), findsOneWidget);

    await tester.tap(find.text('Correct two'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Confirm answer'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Check Accuracy'));
    await tester.pumpAndSettle();
    expect(find.text('Not enough accuracy yet'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Restart Level'));
    await tester.pumpAndSettle();
    expect(find.text('Choose the correct answer for question one.'), findsOneWidget);
  });

  testWidgets('boss needs 20 correct hits, shows HP and hearts, and completes section',
      (tester) async {
    final prefs = await preferences();
    final questions = List<Exercise>.generate(
      25,
      (i) => Exercise(
        id: 'boss_q$i',
        type: 'multiple_choice',
        prompt: 'Boss question ${i + 1}?',
        choices: ['Right ${i + 1}', 'Wrong ${i + 1}'],
        answerIndex: 0,
        explanation: 'Correct.',
        verified: true,
      ),
    );
    final lesson = Lesson(
      sectionId: 'pre_a',
      title: 'Pre-Lesson A',
      subtitle: '',
      pages: '',
      vocab: const [],
      grammar: const [],
      exercises: questions,
      quiz: const [],
      summary: '',
    );
    final stage = LessonStage(
      id: 'pre_a_stage_boss',
      levelLabel: '1-5',
      title: 'Boss Battle',
      subtitle: '',
      kind: LessonStageKind.boss,
      exercises: questions,
    );
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      progressRepositoryProvider.overrideWith(
        (ref) => SharedPreferencesProgressRepository(prefs),
      ),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: BossBattleScreen(
          sectionId: 'pre_a',
          lesson: lesson,
          stage: stage,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Frost Shrine Guardian'), findsOneWidget);
    expect(find.text('100 / 100 HP'), findsOneWidget);
    expect(find.text('YOUR HEARTS'), findsOneWidget);
    await tester.scrollUntilVisible(find.byType(ExerciseView), 220);
    await tester.pumpAndSettle();

    for (var hit = 0; hit < 20; hit++) {
      final question = tester.widget<ExerciseView>(find.byType(ExerciseView)).exercise;
      await tester.tap(find.text(question.choices[question.answerIndex!]));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Confirm answer'));
      await tester.pumpAndSettle();
      if (hit == 0) {
        expect(find.text('95 / 100 HP'), findsOneWidget);
      }
      if (hit < 19) {
        await tester.tap(find.widgetWithText(FilledButton, 'Next Question'));
        await tester.pumpAndSettle();
      }
    }

    expect(find.text('Guardian defeated!'), findsOneWidget);
    expect(container.read(progressProvider).lessons['pre_a']?.completed, isTrue);
  });
}


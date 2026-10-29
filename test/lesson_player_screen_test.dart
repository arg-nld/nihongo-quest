import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nihongo_quest/data/progress_repository.dart';
import 'package:nihongo_quest/models/curriculum_models.dart';
import 'package:nihongo_quest/providers/providers.dart';
import 'package:nihongo_quest/ui/lesson/lesson_player_screen.dart';

void main() {
  testWidgets(
    'practice prompt is visible, answer enables Continue, and quiz follows practice',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      const practice = Exercise(
        id: 'test_practice_1',
        type: 'multiple_choice',
        prompt: 'Which writing system is mostly used for words of foreign origin?',
        choices: ['Hiragana', 'Katakana', 'Kanji', 'Romaji'],
        answerIndex: 1,
        explanation: 'Katakana is commonly used for words of foreign origin.',
        verified: true,
      );
      const quiz = Exercise(
        id: 'test_quiz_1',
        type: 'multiple_choice',
        prompt: 'What is the correct answer?',
        choices: ['Correct', 'Incorrect'],
        answerIndex: 0,
        explanation: 'Test question.',
        verified: true,
      );
      const lesson = Lesson(
        sectionId: 'test_lesson',
        title: 'Test Lesson',
        subtitle: '',
        pages: '',
        vocab: [],
        grammar: [],
        exercises: [practice],
        quiz: [quiz],
        summary: '',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            progressRepositoryProvider.overrideWith(
              (ref) => SharedPreferencesProgressRepository(prefs),
            ),
          ],
          child: const MaterialApp(
            home: LessonPlayerScreen(sectionId: 'test_lesson', lesson: lesson),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Which writing system is mostly used for words of foreign origin?'),
        findsOneWidget,
      );
      expect(find.text('Test Lesson — Practice'), findsOneWidget);

      await tester.tap(find.text('Katakana'));
      await tester.pumpAndSettle();

      final continueButton = find.widgetWithText(FilledButton, 'Continue');
      expect(continueButton, findsOneWidget);
      final button = tester.widget<FilledButton>(continueButton);
      expect(button.onPressed, isNotNull);

      await tester.tap(continueButton);
      await tester.pumpAndSettle();
      expect(find.text('Test Lesson — Quiz'), findsOneWidget);
      expect(find.text('What is the correct answer?'), findsOneWidget);
    },
  );
}

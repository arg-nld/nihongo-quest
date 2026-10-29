import 'package:flutter/material.dart';

import '../../core/lesson_stage_plan.dart';
import '../../models/curriculum_models.dart';
import '../artwork_catalog.dart';
import '../boss_battle_screen.dart';
import '../theme.dart';
import 'lesson_player_screen.dart';

/// A small pre-level debrief that teaches the key idea before the quiz starts.
class StageBriefingScreen extends StatelessWidget {
  const StageBriefingScreen({
    super.key,
    required this.sectionId,
    required this.lesson,
    required this.stage,
  });

  final String sectionId;
  final Lesson lesson;
  final LessonStage stage;

  @override
  Widget build(BuildContext context) {
    final isBoss = stage.isBoss;
    final questions = stage.exercises.where((e) => e.verified && e.type != 'flashcard').take(3).toList();
    final tip = _tipForStage();

    return Scaffold(
      appBar: AppBar(title: const Text('Lesson Debrief')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 780),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 26),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFE4F3D9), Color(0xFFF7FAEF)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFCFE5BE)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${stage.levelLabel}  ·  ${isBoss ? 'BOSS PREP' : 'QUICK TUTORIAL'}',
                        style: const TextStyle(
                          color: AppTheme.matchaDeep,
                          fontSize: 11,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        stage.title,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: AppTheme.indigoInk,
                            ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        isBoss
                            ? 'Review the important patterns before you face ${ChapterArtwork.bossNameForSection(sectionId)}.'
                            : 'Learn the trick first. Then answer the questions using what you just reviewed.',
                        style: const TextStyle(height: 1.4, color: AppTheme.inkMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _TutorCard(title: isBoss ? 'Boss strategy' : 'Your tutor says', body: tip),
                if (lesson.vocab.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  const _SectionHeading(title: 'Quick review', subtitle: 'A few words to keep in mind'),
                  const SizedBox(height: 8),
                  for (final item in _vocabularyForStage().take(4))
                    Container(
                      margin: const EdgeInsets.only(bottom: 7),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: AppTheme.outline),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.japanese, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                                Text(item.romaji, style: const TextStyle(fontSize: 12, color: AppTheme.inkMuted)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(item.english, textAlign: TextAlign.end,
                                style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.indigoInk)),
                          ),
                        ],
                      ),
                    ),
                ],
                if (questions.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  const _SectionHeading(title: 'What the questions look like', subtitle: 'Examples from this level'),
                  const SizedBox(height: 8),
                  for (final exercise in questions)
                    Container(
                      margin: const EdgeInsets.only(bottom: 9),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(color: AppTheme.outline),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppTheme.paperAlt,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _questionTypeLabel(exercise.type, isBoss),
                              style: const TextStyle(fontSize: 10, letterSpacing: 0.5, fontWeight: FontWeight.w900, color: AppTheme.indigoInk),
                            ),
                          ),
                          const SizedBox(height: 9),
                          Text(exercise.prompt, style: const TextStyle(fontWeight: FontWeight.w800, height: 1.35)),
                          if (exercise.explanation.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(exercise.explanation, style: const TextStyle(color: AppTheme.inkMuted, height: 1.35)),
                          ],
                        ],
                      ),
                    ),
                ],
                if (lesson.grammar.isNotEmpty && !isBoss) ...[
                  const SizedBox(height: 8),
                  ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 8),
                    childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    title: const Text('Need one more example?', style: TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text(lesson.grammar.first.title),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(lesson.grammar.first.explanation,
                            style: const TextStyle(color: AppTheme.inkMuted, height: 1.4)),
                      ),
                      for (final example in lesson.grammar.first.examples.take(2))
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('${example.japanese}  ·  ${example.romaji}',
                              style: const TextStyle(fontWeight: FontWeight.w800)),
                          subtitle: Text(example.english),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(MaterialPageRoute(
                        builder: (_) => isBoss
                            ? BossBattleScreen(sectionId: sectionId, lesson: lesson, stage: stage)
                            : LessonPlayerScreen(sectionId: sectionId, lesson: lesson, stage: stage),
                      ));
                    },
                    icon: Icon(isBoss ? Icons.sports_martial_arts_rounded : Icons.play_arrow_rounded),
                    label: Text(isBoss ? 'Enter Boss Battle' : 'Start Level'),
                  ),
                ),
                const SizedBox(height: 7),
                Center(
                  child: TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('Back to the path'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<VocabItem> _vocabularyForStage() {
    final vocab = lesson.vocab.where((item) => item.verified).toList();
    if (vocab.length <= 4) return vocab;
    final title = stage.title.toLowerCase();
    if (title.contains('meaning') || title.contains('word')) return vocab.take(4).toList();
    final skills = stage.exercises.map((exercise) => exercise.vocabId).whereType<String>().toSet();
    final linked = vocab.where((item) => skills.contains(item.id)).toList();
    return linked.isEmpty ? vocab.take(4).toList() : linked.take(4).toList();
  }

  String _tipForStage() {
    if (stage.isBoss) {
      return 'Read the whole prompt before choosing. Each matching pair becomes its own multiple-choice question here. Correct answers damage the guardian; a wrong answer or a timeout costs one heart.';
    }
    final title = stage.title.toLowerCase();
    if (title.contains('writing system')) {
      return 'Hiragana and katakana represent sounds. Kanji carries meaning, and katakana is commonly used for words borrowed from other languages. Look for the clue in the question before picking a script.';
    }
    if (title.contains('pronunciation') || title.contains('sound pattern')) {
      return 'Japanese vowels are clean, short sounds: a (ah), i (ee), u (oo), e (eh), and o (oh). A longer vowel or a doubled consonant can change a word, so listen to each sound carefully.';
    }
    if (title.contains('meaning') || title.contains('reading kana')) {
      return 'Say the word in your head first, then connect the reading to its meaning. Long vowels matter: for example, obaasan means grandmother while obasan means aunt.';
    }
    if (title.contains('grammar') || title.contains('particle') || title.contains('sentence')) {
      final note = lesson.grammar.isEmpty ? null : lesson.grammar.first;
      return note == null
          ? 'Look for the word that links the parts of the sentence. Read the entire sentence before deciding which answer fits.'
          : '${note.title}: ${note.explanation}';
    }
    if (title.contains('number') || title.contains('counter') || title.contains('age')) {
      return 'Separate the number from the counter or time expression. The question often tests the small ending that makes the whole answer correct.';
    }
    return 'Read the complete sentence, find the key word, and eliminate choices that do not fit its meaning. You can review each answer explanation after you respond.';
  }

  String _questionTypeLabel(String type, bool isBoss) {
    if (isBoss && type == 'match') return 'INDIVIDUAL MULTIPLE CHOICE';
    return switch (type) {
      'multiple_choice' => 'MULTIPLE CHOICE',
      'fill_blank' => 'FILL IN THE BLANK · CHOOSE ONE',
      'word_order' => 'BUILD THE SENTENCE',
      'match' => 'MATCH THE PAIRS',
      'translation' => 'TRANSLATION',
      _ => type.toUpperCase(),
    };
  }
}

class _TutorCard extends StatelessWidget {
  const _TutorCard({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: AppTheme.outline),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFE4F3D9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.school_rounded, color: AppTheme.matchaDeep, size: 25),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title.toUpperCase(), style: const TextStyle(fontSize: 10, letterSpacing: 0.9, fontWeight: FontWeight.w900, color: AppTheme.matchaDeep)),
                  const SizedBox(height: 5),
                  Text(body, style: const TextStyle(height: 1.45, color: AppTheme.ink)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 3),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.inkMuted)),
        ],
      );
}

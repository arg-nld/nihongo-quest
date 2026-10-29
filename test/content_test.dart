import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Curriculum completeness + content validation tests.
///
/// These read the built JSON assets directly (no SharedPreferences needed) so
/// malformed content is caught by `flutter test` before it can crash the app.
void main() {
  final assetDir = Directory('assets/curriculum');
  final files = assetDir.existsSync()
      ? assetDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList()
      : <File>[];

  group('curriculum assets exist', () {
    test('curriculum index exists', () {
      expect(assetDir.existsSync(), isTrue,
          reason: 'assets/curriculum/ directory missing — run tools/content_builder/build.py');
    });

    test('curriculum.json lists 18 sections', () {
      final index = File('assets/curriculum/curriculum.json');
      expect(index.existsSync(), isTrue);
      final data = jsonDecode(index.readAsStringSync()) as List;
      expect(data.length, 18);
      final ids = data.map((s) => s['id']).toSet();
      expect(ids, containsAll(['pre_a', 'pre_d', 'lesson_01', 'lesson_13', 'reference']));
      for (final i in [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]) {
        expect(ids, contains('lesson_${i.toString().padLeft(2, '0')}'),
            reason: 'lesson $i missing from curriculum.json');
      }
    });

    test('every contentFile declared by curriculum.json exists on disk', () {
      final index = File('assets/curriculum/curriculum.json');
      final sections = (jsonDecode(index.readAsStringSync()) as List)
          .cast<Map<String, dynamic>>();
      for (final s in sections) {
        final f = File('assets/curriculum/${s['contentFile']}');
        expect(f.existsSync(), isTrue,
            reason:
                '${s['id']} declares ${s['contentFile']} but the asset is missing — '
                'run tools/content_builder/build.py');
      }
    });

    test('every contentFile parses and matches its section id', () {
      final index = File('assets/curriculum/curriculum.json');
      final sections = (jsonDecode(index.readAsStringSync()) as List)
          .cast<Map<String, dynamic>>();
      for (final s in sections) {
        final f = File('assets/curriculum/${s['contentFile']}');
        final data = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
        expect(data['sectionId'], s['id'],
            reason:
                '${s['contentFile']} has sectionId ${data['sectionId']} but is '
                'registered as ${s['id']} in curriculum.json');
      }
    });

    test('numbered lessons 1-13 have a builder module and a built asset', () {
      for (var i = 1; i <= 13; i++) {
        final id = 'lesson_${i.toString().padLeft(2, '0')}';
        expect(File('tools/content_builder/$id.py').existsSync(), isTrue,
            reason: '$id builder module missing');
        expect(File('assets/curriculum/$id.json').existsSync(), isTrue,
            reason: '$id JSON asset missing');
      }
    });

    test('Lesson 10 covers requests and compound kana with a verified quiz', () {
      final f = File('assets/curriculum/lesson_10.json');
      expect(f.existsSync(), isTrue);
      final data = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
      expect((data['quiz'] as List).length, greaterThanOrEqualTo(5));
      expect((data['grammar'] as List).any((g) =>
          (g['title'] as String).toLowerCase().contains('request')), isTrue);
      expect((data['grammar'] as List).any((g) =>
          (g['title'] as String).toLowerCase().contains('compound')), isTrue);
      expect((data['quiz'] as List).every((q) => q['verified'] == true), isTrue);
    });

    test('reference section is reference-only (no scored content)', () {
      final f = File('assets/curriculum/reference.json');
      expect(f.existsSync(), isTrue,
          reason: 'reference.json missing — the Reference Library entry in '
              'curriculum.json would open a blank page');
      final data = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
      expect((data['exercises'] as List? ?? []), isEmpty,
          reason: 'reference must not add scored practice');
      expect((data['quiz'] as List? ?? []), isEmpty,
          reason: 'reference must not have a scored quiz');
      expect((data['vocab'] as List? ?? []).length, greaterThan(0),
          reason: 'the Reference Library should contain browseable lookup entries');
      expect((data['grammar'] as List? ?? []).length, greaterThan(0),
          reason: 'the Reference Library should expose its phrasebook/glossary categories');
      for (final vocab in (data['vocab'] as List? ?? [])) {
        expect((vocab['source'] as String?)?.startsWith('reference p.'), isTrue,
            reason: '${vocab['id']} missing back-matter provenance');
      }
    });
  });

  group('every section JSON validates', () {
    for (final f in files.where((f) => !f.path.endsWith('curriculum.json'))) {
      test(f.uri.pathSegments.last, () {
        final data = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
        final problems = validateLessonJson(data);
        expect(problems, isEmpty, reason: problems.join('\n'));
      });
    }
  });

  group('curriculum completeness', () {
    test('exercise IDs are globally unique across all sections', () {
      final seen = <String>{};
      final dups = <String>{};
      for (final f in files) {
        final data = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
        for (final kind in ['exercises', 'quiz']) {
          for (final ex in (data[kind] as List? ?? [])) {
            final id = ex['id'] as String?;
            if (id == null) continue;
            if (!seen.add(id)) dups.add(id);
          }
        }
      }
      expect(dups, isEmpty);
    });

    test('vocab IDs are unique within each section', () {
      for (final f in files) {
        final data = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
        final ids = (data['vocab'] as List? ?? [])
            .map((v) => v['id'] as String?)
            .whereType<String>()
            .toList();
        expect(ids.toSet().length, ids.length,
            reason: 'duplicate vocab ids in ${f.uri.pathSegments.last}');
      }
    });

    test('every vocabId reference points to vocab in the same section', () {
      for (final f in files) {
        final data = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
        final vocabIds = (data['vocab'] as List? ?? [])
            .map((v) => v['id'] as String)
            .toSet();
        for (final kind in ['exercises', 'quiz']) {
          for (final ex in (data[kind] as List? ?? [])) {
            final vid = ex['vocabId'] as String?;
            if (vid != null) {
              expect(vocabIds, contains(vid),
                  reason: '${ex['id']} references unknown vocab $vid');
            }
          }
        }
      }
    });

    test('every vocabulary entry has source page provenance', () {
      for (final f in files) {
        final data = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
        for (final vocab in (data['vocab'] as List? ?? [])) {
          expect((vocab['source'] as String?)?.isNotEmpty, isTrue,
              reason: '${vocab['id']} missing source page provenance');
        }
      }
    });

    test('quiz vocabulary links never target unverified entries', () {
      for (final f in files) {
        final data = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
        final vocabById = {
          for (final vocab in (data['vocab'] as List? ?? []))
            vocab['id'] as String: vocab as Map<String, dynamic>,
        };
        for (final quiz in (data['quiz'] as List? ?? [])) {
          final vid = quiz['vocabId'] as String?;
          if (vid != null) {
            expect(vocabById[vid]?['verified'] != false, isTrue,
                reason: '${quiz['id']} references unverified vocab $vid');
          }
        }
      }
    });

    test('every exercise has a source attribution', () {
      for (final f in files) {
        final data = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
        for (final kind in ['exercises', 'quiz']) {
          for (final ex in (data[kind] as List? ?? [])) {
            expect((ex['source'] as String?)?.isNotEmpty, isTrue,
                reason: '${ex['id']} missing source');
          }
        }
      }
    });

    test('unverified items never appear in scored quizzes', () {
      for (final f in files) {
        final data = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
        for (final ex in (data['quiz'] as List? ?? [])) {
          expect(ex['verified'], isTrue,
              reason: '${ex['id']} in quiz but not verified');
        }
      }
    });

    test('every lesson_* section has a quiz', () {
      for (final f in files) {
        final data = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
        if ((data['sectionId'] as String).startsWith('lesson_')) {
          expect((data['quiz'] as List).length, greaterThanOrEqualTo(5),
              reason: '${data['sectionId']} quiz too short');
        }
      }
    });

    test('source pages reference sections that exist in the archive', () {
      // Spot-check: sources should name a known section prefix + a page.
      final known = RegExp(r'^(pre_[a-d]|lesson_\d+|reference) p\.');
      for (final f in files) {
        final data = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
        for (final kind in ['exercises', 'quiz']) {
          for (final ex in (data[kind] as List? ?? [])) {
            expect(known.hasMatch(ex['source'] as String), isTrue,
                reason: '${ex['id']} has odd source ${ex['source']}');
          }
        }
      }
    });
  });
}

/// Re-implementation of the build-time validator so tests fail on the same
/// problems the content pipeline rejects.
List<String> validateLessonJson(Map<String, dynamic> data) {
  final problems = <String>[];
  final vocabIds = (data['vocab'] as List? ?? [])
      .map((v) => v['id'] as String)
      .toSet();
  for (final kind in ['exercises', 'quiz']) {
    for (final ex in (data[kind] as List? ?? [])) {
      final id = ex['id'] ?? '<no id>';
      final t = ex['type'] as String?;
      final choices = (ex['choices'] as List?) ?? [];
      final ai = ex['answerIndex'] as int?;
      if (t == 'multiple_choice' || (t == 'translation' && ex['direction'] == 'ja_to_en')) {
        if (choices.length < 2) problems.add('$id: needs >=2 choices');
        if (ai == null || ai < 0 || ai >= choices.length) {
          problems.add('$id: answerIndex out of range');
        }
      }
      if (t == 'fill_blank') {
        if ((ex['accepted'] as List?) == null || (ex['accepted'] as List).isEmpty) {
          problems.add('$id: fill_blank needs accepted');
        }
        if (!(ex['prompt'] as String).contains('___')) {
          problems.add('$id: fill_blank prompt needs ___');
        }
      }
      if (t == 'word_order' && (ex['tokens'] as List).length < 2) {
        problems.add('$id: word_order needs >=2 tokens');
      }
      if (t == 'match') {
        final pairs = (ex['pairs'] as List?) ?? [];
        if (pairs.length < 2) problems.add('$id: match needs >=2 pairs');
        final rights = pairs.map((p) => p['right']).toSet();
        if (rights.length != pairs.length) problems.add('$id: duplicate match rights');
      }
      if (t == 'translation' && ex['direction'] == 'en_to_ja' && (ex['accepted'] as List?) == null) {
        problems.add('$id: en_to_ja needs accepted');
      }
      if (kind == 'quiz' && ex['verified'] != true) {
        problems.add('$id: unverified item in quiz');
      }
      final vid = ex['vocabId'] as String?;
      if (vid != null && !vocabIds.contains(vid)) {
        problems.add('$id: unknown vocabId $vid');
      } else if (kind == 'quiz' &&
          vid != null &&
          ((data['vocab'] as List? ?? []).cast<Map<String, dynamic>>()
                  .firstWhere((v) => v['id'] == vid)['verified'] ==
              false)) {
        problems.add('$id: quiz references unverified vocab $vid');
      }
    }
  }
  if (data['sectionId'] == 'reference' &&
      (((data['exercises'] as List?) ?? []).isNotEmpty ||
          ((data['quiz'] as List?) ?? []).isNotEmpty)) {
    problems.add('reference must be browse-only');
  }
  return problems;
}

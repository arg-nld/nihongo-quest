import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_quest/ui/artwork_catalog.dart';

void main() {
  const sections = <String, String>{
    'pre_a': '01',
    'pre_b': '02',
    'pre_c': '03',
    'pre_d': '04',
    'lesson_01': '05',
    'lesson_02': '06',
    'lesson_03': '07',
    'lesson_04': '08',
    'lesson_05': '09',
    'lesson_06': '10',
    'lesson_07': '11',
    'lesson_08': '12',
    'lesson_09': '13',
    'lesson_10': '14',
    'lesson_11': '15',
    'lesson_12': '16',
    'lesson_13': '17',
  };

  test('all 17 learning sections map to portrait map art, arena art, and bosses', () {
    expect(sections, hasLength(17));
    for (final entry in sections.entries) {
      expect(ChapterArtwork.numberForSection(entry.key), entry.value);
      expect(
        ChapterArtwork.regionAssetForSection(entry.key),
        'assets/artwork/regions/${entry.value}.svg',
      );
      expect(
        ChapterArtwork.arenaAssetForSection(entry.key),
        'assets/artwork/arenas/${entry.value}.svg',
      );
      expect(
        ChapterArtwork.bossAssetForSection(entry.key),
        'assets/artwork/bosses/${entry.value}.svg',
      );
      expect(ChapterArtwork.regionNameForSection(entry.key), isNotEmpty);
      expect(ChapterArtwork.bossNameForSection(entry.key), isNotEmpty);

      final regionFile = File('assets/artwork/regions/${entry.value}.svg');
      final arenaFile = File('assets/artwork/arenas/${entry.value}.svg');
      final bossFile = File('assets/artwork/bosses/${entry.value}.svg');
      expect(regionFile.existsSync(), isTrue, reason: regionFile.path);
      expect(arenaFile.existsSync(), isTrue, reason: arenaFile.path);
      expect(bossFile.existsSync(), isTrue, reason: bossFile.path);
      expect(regionFile.readAsStringSync(), contains('viewBox="0 0 720 1280"'));
      expect(regionFile.readAsStringSync(), isNot(contains('<rect x="0" y="0" width="720" height="1280"')));
      expect(arenaFile.readAsStringSync(), contains('viewBox="0 0 1280 720"'));
      expect(bossFile.readAsStringSync(), contains('viewBox="0 0 1024 1024"'));
    }
  });

  test('the reference library does not have a boss assignment', () {
    expect(ChapterArtwork.numberForSection('reference'), isNull);
    expect(ChapterArtwork.regionAssetForSection('reference'), isNull);
    expect(ChapterArtwork.arenaAssetForSection('reference'), isNull);
    expect(ChapterArtwork.bossAssetForSection('reference'), isNull);
  });
}

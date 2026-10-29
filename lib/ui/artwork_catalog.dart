/// Canonical chapter-to-artwork mapping for the 17 learning units.
///
/// Asset numbers follow the curriculum's `order` field (1–17): four pre-lessons
/// followed by Lessons 1–13. The reference library intentionally has no boss.
class ChapterArtwork {
  const ChapterArtwork._();

  static const Map<String, String> _numberBySection = {
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

  static const Map<String, String> _regionNames = {
    '01': 'Echo Village',
    '02': 'Counting Creek',
    '03': 'Greeting Bridge',
    '04': 'Crossroads Station',
    '05': 'Hiragana Plains',
    '06': 'Topic Terraces',
    '07': 'Umbrella Lane',
    '08': 'Koi Pond Hills',
    '09': 'Sakura Hill',
    '10': 'Treasure Peak',
    '11': 'Kodama Grove',
    '12': 'Maple Memory Trail',
    '13': 'Moonlit Garden',
    '14': 'Festival Street',
    '15': 'Counter Cove',
    '16': 'Verb Volcano',
    '17': 'Time Temple',
  };

  static const Map<String, String> _bossNames = {
    '01': 'Yamabiko',
    '02': 'Soroban Golem',
    '03': 'Tanuki Gatekeeper',
    '04': 'Kitsune Stationmaster',
    '05': 'Kakashi Scribe',
    '06': 'Daruma of Wa',
    '07': 'Karakasa Collector',
    '08': 'Nishikigoi Dragon',
    '09': 'Konohana Spirit',
    '10': 'Gold Oni',
    '11': 'Kodama Elder',
    '12': 'Nue of Yesterday',
    '13': 'Tsuki Usagi',
    '14': 'Oni Shopkeeper',
    '15': 'Giant Tako',
    '16': 'Magma Ryu',
    '17': 'Tokei Karakuri',
  };

  static String? numberForSection(String sectionId) =>
      _numberBySection[sectionId];

  /// Portrait-native transparent environment vignette used on the continuous map.
  static String? regionAssetForSection(String sectionId) {
    final number = numberForSection(sectionId);
    return number == null ? null : 'assets/artwork/regions/$number.svg';
  }

  /// Original 16:9 scene used as a full-bleed backdrop in the battle arena.
  /// Combat scenes deliberately stay landscape; only the map artwork is portrait.
  static String? arenaAssetForSection(String sectionId) {
    final number = numberForSection(sectionId);
    return number == null ? null : 'assets/artwork/arenas/$number.svg';
  }

  static String? bossAssetForSection(String sectionId) {
    final number = numberForSection(sectionId);
    return number == null ? null : 'assets/artwork/bosses/$number.svg';
  }

  static String regionNameForSection(String sectionId) {
    final number = numberForSection(sectionId);
    return number == null ? 'Japanese fantasy region' : _regionNames[number]!;
  }

  static String bossNameForSection(String sectionId) {
    final number = numberForSection(sectionId);
    return number == null ? 'Chapter Guardian' : _bossNames[number]!;
  }
}

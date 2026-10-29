import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../core/content_validator.dart';
import '../models/curriculum_models.dart';

/// Loads and validates the curriculum from `assets/curriculum/`.
class CurriculumRepository {
  CurriculumRepository();

  static const String _basePath = 'assets/curriculum';

  List<Section>? _sections;
  final Map<String, Lesson> _lessonCache = {};
  final Map<String, List<String>> _lessonProblems = {};

  /// Ordered sections (the map spine). Throws on malformed curriculum.json.
  Future<List<Section>> loadSections() async {
    if (_sections != null) return _sections!;
    final raw = await rootBundle.loadString('$_basePath/curriculum.json');
    final decoded = jsonDecodeList(raw, 'curriculum.json');
    _sections = decoded.map((e) => Section.fromJson(e)).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return _sections!;
  }

  /// Load a lesson by section ID. Returns null for reference-only sections
  /// (no parseable content file) or if the file cannot be parsed.
  Future<Lesson?> loadLesson(String sectionId) async {
    if (_lessonCache.containsKey(sectionId)) return _lessonCache[sectionId];
    final sections = await loadSections();
    Section? section;
    for (final s in sections) {
      if (s.id == sectionId) section = s;
    }
    if (section == null) return null;
    try {
      final raw = await rootBundle.loadString('$_basePath/${section.contentFile}');
      final lesson = Lesson.fromJson(jsonDecodeMap(raw, section.contentFile));
      final problems = ContentValidator.validateLesson(
          lesson, sections.map((s) => s.id).toSet());
      _lessonProblems[sectionId] = problems;
      _lessonCache[sectionId] = lesson;
      return lesson;
    } catch (e) {
      _lessonProblems[sectionId] = ['failed to load: $e'];
      return null;
    }
  }

  /// Validation problems found for a section (empty if clean).
  Future<List<String>> problemsFor(String sectionId) async {
    await loadLesson(sectionId);
    return _lessonProblems[sectionId] ?? const [];
  }

  /// Load every lesson (used by tests and the review engine).
  Future<Map<String, Lesson>> loadAllLessons() async {
    final sections = await loadSections();
    final out = <String, Lesson>{};
    for (final s in sections) {
      final l = await loadLesson(s.id);
      if (l != null) out[s.id] = l;
    }
    return out;
  }
}

List<Map<String, dynamic>> jsonDecodeList(String raw, String name) {
  final v = _decode(raw, name);
  if (v is! List) throw FormatException('$name: expected a JSON array');
  return v.cast<Map<String, dynamic>>();
}

Map<String, dynamic> jsonDecodeMap(String raw, String name) {
  final v = _decode(raw, name);
  if (v is! Map<String, dynamic>) {
    throw FormatException('$name: expected a JSON object');
  }
  return v;
}

dynamic _decode(String raw, String name) {
  try {
    return json.decode(raw);
  } catch (e) {
    throw FormatException('$name: invalid JSON ($e)');
  }
}

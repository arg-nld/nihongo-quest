import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/progress_models.dart';

/// Persistence contract. The app talks only to this interface; swapping the
/// storage backend (e.g. to SQLite/Drift later) touches nothing else.
abstract class ProgressRepository {
  Future<ProgressData> load();
  Future<void> save(ProgressData data);
}

/// SharedPreferences-backed store. The whole [ProgressData] document is one
/// JSON string under a versioned key — small enough for this app's needs and
/// robust to schema tweaks (missing fields default via fromJson).
class SharedPreferencesProgressRepository implements ProgressRepository {
  SharedPreferencesProgressRepository(this._prefs);

  final SharedPreferences _prefs;

  static const String _key = 'nihongo_quest_progress_v1';

  @override
  Future<ProgressData> load() async {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const ProgressData();
    try {
      final map = json.decode(raw);
      if (map is! Map<String, dynamic>) return const ProgressData();
      return ProgressData.fromJson(map);
    } catch (_) {
      // Corrupted save: start fresh rather than crash. Progress documents are
      // small; losing one bad write is acceptable for a local-first app.
      return const ProgressData();
    }
  }

  @override
  Future<void> save(ProgressData data) async {
    await _prefs.setString(_key, json.encode(data.toJson()));
  }
}

/// In-memory store for tests.
class InMemoryProgressRepository implements ProgressRepository {
  ProgressData _data = const ProgressData();

  @override
  Future<ProgressData> load() async => _data;

  @override
  Future<void> save(ProgressData data) async => _data = data;

  ProgressData get current => _data;
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/curriculum_models.dart';
import '../models/progress_models.dart';
import '../providers/providers.dart';
import 'widgets/common.dart';

/// Vocabulary collection: every vocab item from all loaded lessons, with
/// mastery status from the SRS.
class VocabCollectionScreen extends ConsumerStatefulWidget {
  const VocabCollectionScreen({super.key});

  @override
  ConsumerState<VocabCollectionScreen> createState() =>
      _VocabCollectionScreenState();
}

class _VocabCollectionScreenState extends ConsumerState<VocabCollectionScreen> {
  List<VocabItem> _all = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(curriculumRepositoryProvider);
    final lessons = await repo.loadAllLessons();
    // Reference sections hold a browsable phrasebook, not studied vocabulary:
    // keep their items out of the collection (and thus out of review).
    final referenceIds = (await repo.loadSections())
        .where((s) => s.type == 'reference')
        .map((s) => s.id)
        .toSet();
    final seen = <String>{};
    final items = <VocabItem>[];
    for (final e in lessons.entries) {
      if (referenceIds.contains(e.key)) continue;
      for (final v in e.value.vocab) {
        if (seen.add(v.id)) items.add(v);
      }
    }
    if (mounted) setState(() { _all = items; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(progressProvider.select((p) => p.settings));
    final reviews = ref.watch(progressProvider.select((p) => p.reviews));
    if (_loading) {
      return const Scaffold(body: AppLoadingState(message: 'Loading vocabulary…'));
    }
    return Scaffold(
      appBar: AppBar(title: Text('Vocabulary (${_all.length})')),
      body: _all.isEmpty
          ? const AppEmptyState(
              icon: Icons.menu_book,
              title: 'No vocabulary yet',
              message:
                  'Finish a lesson to collect its words here. Your collection '
                  'grows as you study, and every item can be reviewed.',
            )
          : ListView(
        padding: const EdgeInsets.all(12),
        children: [
          for (final v in _all)
            Card(
              child: ListTile(
                leading: _MasteryBadge(state: reviews[v.id]),
                title: JapaneseText(
                  japanese: v.kanji != null ? '${v.japanese}（${v.kanji}）' : v.japanese,
                  romaji: v.romaji,
                  showRomaji: settings.showRomaji,
                ),
                subtitle: Text(v.english),
                trailing: v.verified
                    ? null
                    : Tooltip(message: 'Unverified OCR item', child: const Icon(Icons.help_outline)),
              ),
            ),
        ],
      ),
    );
  }
}

class _MasteryBadge extends StatelessWidget {
  const _MasteryBadge({required this.state});
  final ReviewState? state;

  @override
  Widget build(BuildContext context) {
    final tier = (state?.mastery ?? Mastery.new_).index;
    return Tooltip(
      message: masteryLabels[tier],
      child: MasteryIcon(tier),
    );
  }
}

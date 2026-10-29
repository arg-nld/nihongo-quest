import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/curriculum_models.dart';
import '../models/progress_models.dart';
import '../providers/providers.dart';
import 'theme.dart';
import 'widgets/common.dart';

/// Review Today tab: shows due items and starts a review session.
class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  Map<String, VocabItem> _vocab = {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repository = ref.read(curriculumRepositoryProvider);
    final sections = await repository.loadSections();
    final referenceIds = sections
        .where((section) => section.type == 'reference')
        .map((section) => section.id)
        .toSet();
    final lessons = await repository.loadAllLessons();
    final vocab = <String, VocabItem>{};
    for (final entry in lessons.entries) {
      // Reference entries are for lookup only; never resolve them into SRS.
      if (referenceIds.contains(entry.key)) continue;
      for (final v in entry.value.vocab) {
        vocab[v.id] = v;
      }
    }
    if (!mounted) return;
    setState(() {
      _vocab = vocab;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(progressProvider.select((p) => p.settings));
    final reviews = ref.watch(progressProvider.select((p) => p.reviews));
    final due = ref.watch(progressProvider.notifier).dueReviewIds();
    final mastered = reviews.values.where((r) => r.mastery == Mastery.mastered).length;

    if (!_loaded) {
      // A static placeholder rather than an animating spinner: this tab is
      // always built inside the app shell's IndexedStack, so a spinner here
      // would keep scheduling frames forever.
      return const SafeArea(
        child: Center(
          child: Text('Loading reviews…',
              style: TextStyle(color: AppTheme.inkMuted)),
        ),
      );
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppTheme.spaceLg),
        children: [
          Text('Review Today',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppTheme.spaceSm),
          Text(
            '$due items due · $mastered mastered · ${reviews.length} in your collection',
            style: AppTheme.caption(context),
          ),
          const SizedBox(height: AppTheme.spaceLg),
          FilledButton.icon(
            onPressed: due.isEmpty
                ? null
                : () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const ReviewScreenSession(dueOnly: true))),
            icon: const Icon(Icons.style),
            label: Text('Start review (${due.length})'),
          ),
          const SizedBox(height: AppTheme.spaceMd),
          FilledButton.tonalIcon(
            onPressed: reviews.isEmpty
                ? null
                : () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const ReviewScreenSession(dueOnly: false))),
            icon: const Icon(Icons.shuffle),
            label: const Text('Mixed review (everything)'),
          ),
          const SizedBox(height: AppTheme.spaceLg),
          if (reviews.isEmpty)
            const AppEmptyState(
              icon: Icons.style,
              title: 'No items to review yet',
              message:
                  'Study a lesson to add its vocabulary here. Reviews use spaced '
                  'repetition, so items come back right when you are about to '
                  'forget them.',
            )
          else
            ...reviews.values.map((r) => _ReviewTile(
                  state: r,
                  vocab: _vocab[r.itemId],
                  showRomaji: settings.showRomaji,
                )),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.state, required this.vocab, required this.showRomaji});

  final ReviewState state;
  final VocabItem? vocab;
  final bool showRomaji;

  @override
  Widget build(BuildContext context) {
    final v = vocab;
    return Card(
      child: ListTile(
        leading: Tooltip(
          message: masteryLabels[state.mastery.index],
          child: MasteryIcon(state.mastery.index),
        ),
        title: v == null
            ? Text(state.itemId)
            : JapaneseText(
                japanese: v.kanji != null ? '${v.japanese}（${v.kanji}）' : v.japanese,
                romaji: v.romaji,
                showRomaji: showRomaji,
              ),
        subtitle: Text(v == null
            ? 'streak ${state.streak} · accuracy ${(state.accuracy * 100).round()}% · next ${_nextLabel(state)}'
            : '${v.english} · streak ${state.streak} · '
                'accuracy ${(state.accuracy * 100).round()}% · next ${_nextLabel(state)}'),
      ),
    );
  }

  String _nextLabel(ReviewState s) {
    if (s.nextReviewOn == null) return 'now';
    final d = DateTime.fromMillisecondsSinceEpoch(s.nextReviewOn!);
    final now = DateTime.now();
    final days = DateTime(d.year, d.month, d.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
    return days <= 0 ? 'today' : 'in ${days}d';
  }
}

/// A running review session over vocabulary items.
class ReviewScreenSession extends ConsumerStatefulWidget {
  const ReviewScreenSession({super.key, required this.dueOnly});
  final bool dueOnly;

  @override
  ConsumerState<ReviewScreenSession> createState() => _ReviewScreenSessionState();
}

class _ReviewScreenSessionState extends ConsumerState<ReviewScreenSession> {
  List<_ReviewItem> _items = [];
  int _index = 0;
  bool _loaded = false;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(curriculumRepositoryProvider);
    final sections = await repo.loadSections();
    final referenceIds = sections
        .where((section) => section.type == 'reference')
        .map((section) => section.id)
        .toSet();
    final lessons = await repo.loadAllLessons();
    final vocab = <String, VocabItem>{};
    for (final entry in lessons.entries) {
      // The review session must only contain vocabulary from sequential lessons.
      if (referenceIds.contains(entry.key)) continue;
      for (final v in entry.value.vocab) {
        vocab[v.id] = v;
      }
    }
    final controller = ref.read(progressProvider.notifier);
    var ids = controller.dueReviewIds();
    if (!widget.dueOnly) {
      ids = (ref.read(progressProvider).reviews.keys.toList());
    }
    // Newest-last so a full session covers everything; cap length for comfort.
    final items = ids
        .map((id) => vocab[id])
        .whereType<VocabItem>()
        .map((v) => _ReviewItem(v))
        .toList();
    if (mounted) {
      setState(() {
        _items = items;
        _loaded = true;
      });
    }
  }

  void _answer(VocabItem v, bool remembered) {
    ref
        .read(progressProvider.notifier)
        .recordReview(itemId: v.id, itemType: 'vocab', wasCorrect: remembered);
    setState(() => _index++);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: AppLoadingState());
    }
    if (_items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Review')),
        body: const AppEmptyState(
          icon: Icons.event_available,
          title: 'Nothing due right now',
          message:
              'Every scheduled item has been reviewed. Come back when the next '
              'items are due, or start a mixed review.',
        ),
      );
    }
    if (_index >= _items.length) {
      return Scaffold(
        appBar: AppBar(title: const Text('Review complete')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.celebration, size: 64, color: AppTheme.matcha),
              const SizedBox(height: AppTheme.spaceMd),
              Text('Reviewed ${_items.length} items!',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      );
    }
    final item = _items[_index];
    return Scaffold(
      appBar: AppBar(
        title: Text('Review ${_index + 1}/${_items.length}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            JapaneseText(
              japanese: item.vocab.japanese,
              romaji: null, // hidden during recall; revealed after answering
              showRomaji: false,
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            AnimatedCrossFade(
              crossFadeState: _revealed ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
              firstChild: FilledButton.tonal(
                onPressed: () => setState(() => _revealed = true),
                child: const Text('Show answer'),
              ),
              secondChild: Column(
                children: [
                  Text(item.vocab.romaji,
                      style: const TextStyle(fontSize: 22, color: AppTheme.inkMuted)),
                  Text(item.vocab.english,
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: () => _answer(item.vocab, false),
                        icon: const Icon(Icons.close),
                        label: const Text('Missed it'),
                      ),
                      const SizedBox(width: 16),
                      FilledButton.icon(
                        onPressed: () => _answer(item.vocab, true),
                        icon: const Icon(Icons.check),
                        label: const Text('Got it'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewItem {
  const _ReviewItem(this.vocab);
  final VocabItem vocab;
}

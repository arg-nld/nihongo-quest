import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import 'checkpoint_screen.dart';
import 'lesson/lesson_overview_screen.dart';
import 'review_screen.dart';
import 'theme.dart';
import 'widgets/common.dart';

/// Home dashboard: a clear next step, useful progress, and lightweight daily goals.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(progressProvider.select((p) => p.player));
    final reviews = ref.watch(progressProvider.select((p) => p.reviews));
    final dueCount = reviews.values.where((r) => r.isDue).length;
    final nextAsync = ref.watch(nextSectionDetailsProvider);
    final quest = ref.watch(progressProvider.notifier).currentQuest(reviewsDone: 0);
    final completedLessons = ref
        .watch(progressProvider.select((p) => p.lessons))
        .values
        .where((l) => l.completed)
        .length;
    final questProgress = quest.goal == 0 ? 0.0 : (quest.progress / quest.goal).clamp(0.0, 1.0).toDouble();

    return SafeArea(
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDF2CE),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.spa_rounded, color: AppTheme.matchaDark, size: 27),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('NIHONGO QUEST',
                        style: AppTheme.caption(context).copyWith(
                          color: AppTheme.matchaDark,
                          fontSize: 10,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w900,
                        )),
                    const SizedBox(height: 2),
                    Text(
                      'Welcome back, ${player.displayName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: AppTheme.outline),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stars_rounded,
                        color: AppTheme.matchaDark, size: 18),
                    const SizedBox(width: 5),
                    Text('Lv ${player.level}',
                        style: const TextStyle(
                            color: AppTheme.ink, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text('Your journey', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text('Small steps every day add up.', style: AppTheme.caption(context)),
          const SizedBox(height: 14),
          StatRow(player: player, dueCount: dueCount),
          const SizedBox(height: 20),
          _NextLessonCard(nextAsync: nextAsync),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE7C9),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(Icons.flag_rounded, color: Color(0xFFB56B27)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Daily quest',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text(quest.title, style: AppTheme.caption(context)),
                        ],
                      ),
                    ),
                    Text('${quest.progress}/${quest.goal}',
                        style: const TextStyle(
                            color: AppTheme.indigoInk, fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(end: questProgress),
                    duration: const Duration(milliseconds: 650),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: 9,
                      backgroundColor: AppTheme.paperAlt,
                      color: quest.done ? AppTheme.matchaDark : AppTheme.matcha,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  quest.done ? 'Daily goal complete. Nice work.' : 'A little practice is enough to keep moving.',
                  style: AppTheme.caption(context),
                ),
              ],
            ),
          ),
          if (completedLessons >= 2) ...[
            const SizedBox(height: 18),
            _ActionCard(
              icon: Icons.fact_check_outlined,
              color: AppTheme.shu,
              title: 'Cumulative review',
              subtitle: 'Test what you have learned so far',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CheckpointScreen()),
              ),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: dueCount == 0
                  ? null
                  : () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const ReviewScreenSession(dueOnly: true),
                      )),
              icon: const Icon(Icons.style_rounded),
              label: Text(dueCount == 0 ? 'You are all caught up' : 'Review today · $dueCount due'),
            ),
          ),
        ],
      ),
    );
  }
}

class _NextLessonCard extends StatelessWidget {
  const _NextLessonCard({required this.nextAsync});
  final AsyncValue<({String id, String title, String subtitle})?> nextAsync;

  @override
  Widget build(BuildContext context) {
    return nextAsync.when(
      loading: () => const _JourneyPlaceholder(),
      error: (e, _) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.outline),
        ),
        child: const Text('Could not load the next lesson.'),
      ),
      data: (next) => _JourneyHero(
        title: next?.title ?? 'Keep your Japanese sharp',
        subtitle: next?.subtitle ?? 'Review vocabulary to strengthen your memory.',
        sectionId: next?.id,
      ),
    );
  }
}

class _JourneyHero extends StatelessWidget {
  const _JourneyHero({
    required this.title,
    required this.subtitle,
    required this.sectionId,
  });

  final String title;
  final String subtitle;
  final String? sectionId;

  @override
  Widget build(BuildContext context) {
    final hasNext = sectionId != null;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE4F5D7), Color(0xFFF4F8E9)],
        ),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: const Color(0xFFCFE5BE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  hasNext ? 'CONTINUE LEARNING' : 'JOURNEY COMPLETE',
                  style: const TextStyle(
                    color: AppTheme.matchaDeep,
                    fontSize: 10,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.route_rounded, color: AppTheme.matchaDark, size: 25),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 23),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(subtitle, style: AppTheme.caption(context)),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: hasNext
                  ? () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => LessonOverviewScreen(sectionId: sectionId!),
                      ))
                  : () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const ReviewScreenSession(dueOnly: false),
                      )),
              icon: Icon(hasNext ? Icons.play_arrow_rounded : Icons.refresh_rounded),
              label: Text(hasNext ? 'Start lesson' : 'Review vocabulary'),
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyPlaceholder extends StatelessWidget {
  const _JourneyPlaceholder();

  @override
  Widget build(BuildContext context) => Container(
        height: 190,
        decoration: BoxDecoration(
          color: AppTheme.paperAlt,
          borderRadius: BorderRadius.circular(23),
        ),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 3)),
      );
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.outline),
            ),
            child: Row(
              children: [
                Icon(icon, size: 28, color: color),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 3),
                      Text(subtitle, style: AppTheme.caption(context)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppTheme.inkMuted),
              ],
            ),
          ),
        ),
      );
}

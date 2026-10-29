import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import 'theme.dart';
import 'widgets/common.dart';
import 'vocab_collection_screen.dart';
import 'dev_stage_picker_screen.dart';

/// Profile: player stats, achievements, settings.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(progressProvider);
    final player = data.player;
    final settings = data.settings;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor:
                    player.avatar == 'tanuki' ? AppTheme.sakura : AppTheme.matcha,
                child: Icon(
                  player.avatar == 'tanuki' ? Icons.pets : Icons.account_circle,
                  size: 32,
                  color: AppTheme.indigoInk,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(player.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge),
                    Text('Level ${player.level} · ${player.xp} total XP'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StatRow(player: player, dueCount: 0),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const VocabCollectionScreen())),
            icon: const Icon(Icons.menu_book),
            label: const Text('Vocabulary collection'),
          ),
          const SizedBox(height: 16),
          SectionHeader('Achievements'),
          _AchievementTile(
            id: 'level_5',
            title: 'Rising Traveler',
            desc: 'Reach level 5',
            earned: player.achievements.contains('level_5'),
          ),
          _AchievementTile(
            id: 'level_10',
            title: 'Seasoned Explorer',
            desc: 'Reach level 10',
            earned: player.achievements.contains('level_10'),
          ),
          _AchievementTile(
            id: 'perfect_quiz',
            title: 'Flawless Victory',
            desc: 'Score 100% on a quiz (5+ questions)',
            earned: player.achievements.contains('perfect_quiz'),
          ),
          _AchievementTile(
            id: 'checkpoint_clear',
            title: 'Cumulative Challenger',
            desc: 'Pass the cumulative review (70%+ on the exam)',
            earned: player.achievements.contains('checkpoint_clear'),
          ),
          SectionHeader('Settings'),
          ExpansionTile(
            leading: const Icon(Icons.developer_mode),
            title: const Text('Developer options'),
            subtitle: const Text('Testing tools; bypass level locks'),
            children: [
              ListTile(
                leading: const Icon(Icons.route),
                title: const Text('Choose any stage'),
                subtitle: const Text('Jump directly to any lesson level or boss'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const DevStagePickerScreen())),
              ),
            ],
          ),
          SwitchListTile(
            title: const Text('Show romaji'),
            subtitle: const Text('Hide it to challenge your kana reading'),
            value: settings.showRomaji,
            onChanged: (v) => ref
                .read(progressProvider.notifier)
                .updateSettings((s) => s.copyWith(showRomaji: v)),
          ),
          SwitchListTile(
            title: const Text('Immediate feedback'),
            subtitle: const Text('Off = exam-style (feedback held until submission)'),
            value: settings.immediateFeedback,
            onChanged: (v) => ref
                .read(progressProvider.notifier)
                .updateSettings((s) => s.copyWith(immediateFeedback: v)),
          ),
          ListTile(
            title: const Text('Rename traveler'),
            subtitle: Text(player.displayName),
            trailing: const Icon(Icons.edit),
            onTap: () async {
              final controller = TextEditingController(text: player.displayName);
              final name = await showDialog<String>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Your name'),
                  content: TextField(controller: controller, autofocus: true),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel')),
                    FilledButton(
                        onPressed: () => Navigator.pop(ctx, controller.text),
                        child: const Text('Save')),
                  ],
                ),
              );
              if (name != null && name.trim().isNotEmpty) {
                ref.read(progressProvider.notifier).setDisplayName(name.trim());
              }
            },
          ),
        ],
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({
    required this.id,
    required this.title,
    required this.desc,
    required this.earned,
  });
  final String id;
  final String title;
  final String desc;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          earned ? Icons.emoji_events : Icons.lock_outline,
          size: 28,
          color: earned ? AppTheme.matchaDark : AppTheme.locked,
        ),
        title: Text(title,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: earned ? AppTheme.ink : AppTheme.inkMuted)),
        subtitle: Text(desc),
      ),
    );
  }
}

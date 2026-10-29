import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/progress_models.dart';
import '../theme.dart';

/// Small shared UI pieces. Everything here uses Material icons — no emoji —
/// so the app reads as one visual system.

/// Mastery tier names for a vocabulary item, indexed by tier (0..3).
const List<String> masteryLabels = ['New', 'Learning', 'Familiar', 'Mastered'];

/// The icon for a mastery tier. A clear progression: an empty circle grows
/// into a marked medal, so state is readable at a glance and in greyscale.
IconData masteryIcon(int tier) => switch (tier) {
      0 => Icons.circle_outlined,
      1 => Icons.local_florist,
      2 => Icons.spa,
      _ => Icons.workspace_premium,
    };

/// Mastery icon in the tier's color, sized for list rows.
class MasteryIcon extends StatelessWidget {
  const MasteryIcon(this.tier, {super.key, this.size = 22});
  final int tier;
  final double size;

  @override
  Widget build(BuildContext context) => Icon(
        masteryIcon(tier),
        size: size,
        color: AppTheme.masteryColor(tier),
      );
}

/// A curriculum node's state on the adventure map, as an icon.
IconData nodeStateIcon(String state) => switch (state) {
      'completed' => Icons.check_circle,
      'current' => Icons.play_circle_fill,
      'locked' => Icons.lock_outline,
      'reference' => Icons.menu_book,
      _ => Icons.circle_outlined,
    };

class StatChip extends StatelessWidget {
  const StatChip({
    super.key,
    required this.icon,
    required this.label,
    required this.sub,
    this.color,
  });

  final IconData icon;
  final String label;
  final String sub;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: c, size: 28),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(sub, style: const TextStyle(fontSize: 11, color: Colors.black54)),
          ],
        ),
      ],
    );
  }
}

/// Japanese text with optional romaji underneath (respects the romaji setting
/// via [showRomaji]; pass null to always show).
class JapaneseText extends StatelessWidget {
  const JapaneseText({
    super.key,
    required this.japanese,
    this.romaji,
    this.showRomaji = true,
    this.style,
    this.romajiStyle,
    this.textAlign,
  });

  final String japanese;
  final String? romaji;
  final bool showRomaji;
  final TextStyle? style;
  final TextStyle? romajiStyle;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final ja = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(japanese,
            style: style ?? const TextStyle(fontSize: 20), textAlign: textAlign),
        if (showRomaji && romaji != null && romaji!.isNotEmpty)
          Text(romaji!,
              style: romajiStyle ??
                  const TextStyle(fontSize: 14, color: Colors.black54),
              textAlign: textAlign),
      ],
    );
    return ja;
  }
}

/// A section header used across lesson screens.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(text,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold)),
    );
  }
}

/// XP / level / coins / due-reviews stat row (shared by home + results).
class StatRow extends ConsumerWidget {
  const StatRow({super.key, required this.player, required this.dueCount});
  final PlayerState player;
  final int dueCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final xpGoal = PlayerState.xpForLevel(player.level);
    final xpProgress = xpGoal == 0 ? 0.0 : (player.xpIntoLevel / xpGoal).clamp(0.0, 1.0).toDouble();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        children: [
          Expanded(
            child: _MiniStat(
              icon: Icons.stars_rounded,
              iconColor: AppTheme.matchaDark,
              value: 'Lv ${player.level}',
              label: 'LEVEL',
              footer: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 7),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: xpProgress,
                      minHeight: 5,
                      color: AppTheme.matcha,
                      backgroundColor: AppTheme.paperAlt,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('${player.xpIntoLevel}/$xpGoal XP',
                      style: const TextStyle(fontSize: 10, color: AppTheme.inkMuted)),
                ],
              ),
            ),
          ),
          const _StatDivider(),
          Expanded(
            child: _MiniStat(
              icon: Icons.toll_rounded,
              iconColor: const Color(0xFFC58A31),
              value: '${player.coins}',
              label: 'COINS',
            ),
          ),
          const _StatDivider(),
          Expanded(
            child: _MiniStat(
              icon: Icons.style_rounded,
              iconColor: dueCount > 0 ? AppTheme.shu : AppTheme.indigoSoft,
              value: '$dueCount',
              label: 'DUE TODAY',
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    this.footer,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final Widget? footer;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 19),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.indigoInk)),
            ),
            const SizedBox(height: 2),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 9, letterSpacing: 0.6, fontWeight: FontWeight.w800,
                    color: AppTheme.inkMuted)),
            if (footer != null) footer!,
          ],
        ),
      );
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 56,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        color: AppTheme.outline,
      );
}

/// Centered loading state with an optional message.
class AppLoadingState extends StatelessWidget {
  const AppLoadingState({super.key, this.message});
  final String? message;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (message != null) ...[
              const SizedBox(height: AppTheme.spaceMd),
              Text(message!, style: AppTheme.caption(context)),
            ],
          ],
        ),
      );
}

/// Centered error state with a retry action.
class AppErrorState extends StatelessWidget {
  const AppErrorState({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceXl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppTheme.shu),
              const SizedBox(height: AppTheme.spaceMd),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.ink)),
              if (onRetry != null) ...[
                const SizedBox(height: AppTheme.spaceMd),
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
      );
}

/// Centered empty state: icon, title, explanation, optional action.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceXl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: AppTheme.indigoSoft),
              const SizedBox(height: AppTheme.spaceMd),
              Text(title,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.indigoInk)),
              const SizedBox(height: AppTheme.spaceSm),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.inkMuted)),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppTheme.spaceLg),
                FilledButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      );
}

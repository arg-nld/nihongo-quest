import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import 'theme.dart';

/// Coin shop for consumable boss items and permanent upgrades.
class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  static const _items = <_ShopItem>[
    _ShopItem(
      id: 'extra_heart',
      title: 'Heart Elixir',
      description: 'Adds one extra heart to your next boss attempt. One use per purchase; buy it again whenever you need it.',
      effect: '+1 heart for one battle',
      cost: 40,
      icon: Icons.favorite_rounded,
      consumable: true,
    ),
    _ShopItem(
      id: 'timer_crystal',
      title: 'Time Crystal',
      description: 'Permanently adds two seconds to every boss question. This upgrade can be stacked up to four times.',
      effect: '+2 seconds per question',
      cost: 60,
      icon: Icons.hourglass_bottom_rounded,
      maxRank: 4,
    ),
    _ShopItem(
      id: 'power_rune',
      title: 'Power Rune',
      description: 'Permanently adds two damage to every correct boss answer. This upgrade can be stacked up to five times.',
      effect: '+2 damage per correct answer',
      cost: 75,
      icon: Icons.bolt_rounded,
      maxRank: 5,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(progressProvider);
    final controller = ref.read(progressProvider.notifier);
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Adventure Shop', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        const Text('Prepare for boss battles with items and permanent upgrades.',
                            style: TextStyle(color: AppTheme.inkMuted, height: 1.4)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: AppTheme.outline),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.toll_rounded, color: Color(0xFFC58A31), size: 21),
                        const SizedBox(width: 7),
                        Text('${data.player.coins}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: AppTheme.indigoInk)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 820 ? 3 : constraints.maxWidth >= 560 ? 2 : 1;
                  const spacing = 12.0;
                  final cardWidth = (constraints.maxWidth - spacing * (columns - 1)) / columns;
                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: [
                      for (final item in _items)
                        SizedBox(
                          width: cardWidth,
                          child: _ShopItemCard(
                            item: item,
                            rank: data.upgrades[item.id] ?? 0,
                            stock: data.inventory[item.id] ?? 0,
                            coins: data.player.coins,
                            onPurchase: () {
                              final success = item.consumable
                                  ? controller.purchaseInventoryItem(itemId: item.id, cost: item.cost)
                                  : controller.purchasePermanentUpgrade(
                                      upgradeId: item.id,
                                      cost: item.cost,
                                      maxRank: item.maxRank,
                                    );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(success
                                      ? '${item.title} purchased.'
                                      : (data.player.coins < item.cost
                                          ? 'Not enough coins for ${item.title}.'
                                          : '${item.title} is already fully upgraded.')),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.paperAlt,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Your current battle setup', style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.indigoInk)),
                    const SizedBox(height: 8),
                    Text('Base hearts: 3 · Heart Elixirs in stock: ${data.inventory['extra_heart'] ?? 0}', style: const TextStyle(height: 1.4)),
                    Text('Boss timer: ${12 + (data.upgrades['timer_crystal'] ?? 0) * 2} seconds per question', style: const TextStyle(height: 1.4)),
                    Text('Damage: ${5 + (data.upgrades['power_rune'] ?? 0) * 2} HP for each correct answer', style: const TextStyle(height: 1.4)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text('Earn coins by answering lesson and review questions correctly, completing units, and claiming rewards.',
                  style: TextStyle(fontSize: 12, height: 1.4, color: AppTheme.inkMuted)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShopItem {
  const _ShopItem({
    required this.id,
    required this.title,
    required this.description,
    required this.effect,
    required this.cost,
    required this.icon,
    this.consumable = false,
    this.maxRank = 1,
  });

  final String id;
  final String title;
  final String description;
  final String effect;
  final int cost;
  final IconData icon;
  final bool consumable;
  final int maxRank;
}

class _ShopItemCard extends StatelessWidget {
  const _ShopItemCard({
    required this.item,
    required this.rank,
    required this.stock,
    required this.coins,
    required this.onPurchase,
  });

  final _ShopItem item;
  final int rank;
  final int stock;
  final int coins;
  final VoidCallback onPurchase;

  @override
  Widget build(BuildContext context) {
    final maxed = !item.consumable && rank >= item.maxRank;
    final canAfford = coins >= item.cost;
    final ownedLabel = item.consumable ? 'In stock: $stock' : 'Upgrade rank: $rank/${item.maxRank}';
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 47,
                height: 47,
                decoration: BoxDecoration(
                  color: item.id == 'extra_heart' ? AppTheme.shuSoft : const Color(0xFFE2F2D8),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(item.icon, color: item.id == 'extra_heart' ? AppTheme.shu : AppTheme.matchaDeep, size: 25),
              ),
              const SizedBox(width: 11),
              Expanded(child: Text(item.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppTheme.indigoInk))),
            ],
          ),
          const SizedBox(height: 12),
          Text(item.effect, style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.matchaDeep)),
          const SizedBox(height: 7),
          Text(item.description, style: const TextStyle(fontSize: 13, height: 1.4, color: AppTheme.inkMuted)),
          const SizedBox(height: 13),
          Text(ownedLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: maxed || !canAfford ? null : onPurchase,
              icon: Icon(maxed ? Icons.check_circle_rounded : Icons.toll_rounded, size: 18),
              label: Text(maxed ? 'Fully upgraded' : 'Buy · ${item.cost} coins'),
            ),
          ),
          if (!canAfford && !maxed)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('Earn more coins to purchase this.', style: TextStyle(fontSize: 11, color: AppTheme.inkMuted)),
            ),
        ],
      ),
    );
  }
}

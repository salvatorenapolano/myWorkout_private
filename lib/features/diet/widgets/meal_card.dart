import 'package:flutter/material.dart';

import 'package:my_workout/models/diet.dart';

/// Un pasto: "PRANZO · 13:00", il titolo e gli ingredienti con le grammature.
class MealCard extends StatelessWidget {
  const MealCard({super.key, required this.diet, required this.meal});

  final Diet diet;
  final Meal meal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final description = meal.description;
    final alternative = meal.alternative;
    final slot = diet.slotFor(meal);
    final tint = _SlotTint.of(context, slot.id);
    final emoji = slot.emoji;

    return Card(
      margin: EdgeInsets.zero,
      // Sfondo tenue: giallo a pranzo, blu a cena.
      color: tint?.background,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              // `?emoji`: mette l'emoji nella lista solo se non è null.
              [?emoji, slot.label.toUpperCase()].join('  '),
              style: theme.textTheme.labelMedium?.copyWith(
                color: tint?.accent ?? colors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(meal.title, style: theme.textTheme.titleMedium),
            if (meal.items.isNotEmpty) const SizedBox(height: 8),
            for (final item in meal.items) _ItemRow(food: diet.foodFor(item), item: item),
            if (description != null) ...[
              const SizedBox(height: 6),
              Text(description, style: theme.textTheme.bodyMedium),
            ],
            // Regole numerate: .indexed dà (posizione, regola).
            for (final (index, rule) in meal.rules.indexed)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('${index + 1}. $rule', style: theme.textTheme.bodyMedium),
              ),
            if (alternative != null)
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  alternative,
                  style: theme.textTheme.bodySmall?.copyWith(color: colors.onSecondaryContainer),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// I colori di un momento della giornata: sfondo della card e colore
/// dell'etichetta. Ce n'è una versione per il tema chiaro e una per lo scuro.
class _SlotTint {
  const _SlotTint({required this.background, required this.accent});

  final Color background;
  final Color accent;

  /// null = nessuna tinta speciale (es. "Pranzo e cena" della domenica).
  static _SlotTint? of(BuildContext context, String slotId) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return switch (slotId) {
      'pranzo' => dark
          ? const _SlotTint(background: Color(0xFF3A3115), accent: Color(0xFFFFD25E))
          : const _SlotTint(background: Color(0xFFFFF5D6), accent: Color(0xFF8A5A00)),
      'cena' => dark
          ? const _SlotTint(background: Color(0xFF1B2440), accent: Color(0xFFA9C2FF))
          : const _SlotTint(background: Color(0xFFE6EDFF), accent: Color(0xFF2747A8)),
      _ => null,
    };
  }
}

/// "Tonno al naturale (sgocciolato) ........ 80 g"
class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.food, required this.item});

  final Food food;
  final MealItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondary = theme.colorScheme.onSurfaceVariant;
    final note = item.note;
    final amount = item.amountLabel;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            // Text.rich: un solo testo con pezzi in stili diversi.
            child: Text.rich(
              TextSpan(
                text: food.name,
                children: [
                  if (note != null)
                    TextSpan(text: ' · $note', style: TextStyle(color: secondary)),
                ],
              ),
              style: theme.textTheme.bodyLarge,
            ),
          ),
          if (amount != null) ...[
            const SizedBox(width: 12),
            Text(amount, style: theme.textTheme.bodyLarge?.copyWith(color: secondary)),
          ],
        ],
      ),
    );
  }
}

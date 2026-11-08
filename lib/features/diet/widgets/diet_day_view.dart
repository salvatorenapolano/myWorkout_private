import 'package:flutter/material.dart';

import 'package:my_workout/features/diet/widgets/meal_card.dart';
import 'package:my_workout/models/diet.dart';

/// Un giorno della dieta: palestra/riposo, i pasti e le note utili.
class DietDayView extends StatelessWidget {
  const DietDayView({super.key, required this.diet, required this.day});

  final Diet diet;
  final DietDay day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Row(
          children: [
            Expanded(child: Text(day.name, style: theme.textTheme.headlineSmall)),
            Chip(
              avatar: Icon(day.training ? Icons.fitness_center : Icons.self_improvement, size: 18),
              label: Text(day.training ? 'Palestra' : 'Riposo'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (final meal in day.meals)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: MealCard(diet: diet, meal: meal),
          ),
        // Il riquadro dei legumi compare solo nei giorni che li usano.
        if (day.usesFood('legumi')) _LegumesCard(info: diet.legumes),
        _InfoCard(
          title: 'Da sapere',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final note in diet.notes)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('• $note', style: theme.textTheme.bodyMedium),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegumesCard extends StatelessWidget {
  const _LegumesCard({required this.info});

  final LegumesInfo info;

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      title: info.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(info.description, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final option in info.options) Chip(label: Text(option))],
          ),
        ],
      ),
    );
  }
}

/// Riquadro informativo con lo sfondo leggermente colorato.
class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      // Senza ombra (elevation 0) e con uno sfondo tenue preso dal tema:
      // si distingue dalle card dei pasti senza rubare l'attenzione.
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

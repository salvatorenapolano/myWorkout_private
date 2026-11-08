import 'package:flutter/material.dart';

import 'package:my_workout/models/workout_plan.dart';
import 'package:my_workout/utils/formatters.dart';

/// La riga in alto che ti dice cosa tocca oggi, in base al calendario.
///
/// Riceve `now` invece di chiamare DateTime.now() da sola: così nei test
/// possiamo fingere che sia lunedì, domenica o dopo la fine della scheda.
class TodayBanner extends StatelessWidget {
  const TodayBanner({super.key, required this.plan, required this.now});

  final WorkoutPlan plan;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final next = plan.nextSessionFrom(now);

    // I record (a, b, c) permettono di restituire più valori insieme.
    // Lo `switch` sceglie il caso giusto e li assegna in un colpo solo.
    final (IconData icon, String title, String subtitle, bool isToday) = switch (next) {
      null => (
          Icons.flag_outlined,
          'Scheda terminata',
          "L'ultima seduta era ${formatDayMonth(plan.endDate)}: è ora della prossima scheda.",
          false,
        ),
      _ when DateUtils.isSameDay(next.date, now) => (
          Icons.fitness_center,
          'Oggi: ${plan.workoutById(next.workoutId).name}',
          'Alle ${plan.schedule.time} · ${plan.name}',
          true,
        ),
      _ => (
          Icons.self_improvement,
          'Oggi riposo',
          'Prossimo allenamento ${formatRelativeDay(next.date, now: now)} '
              'alle ${plan.schedule.time}: ${plan.workoutById(next.workoutId).name}',
          false,
        ),
    };

    // Nei giorni di allenamento il riquadro è colorato, a riposo è neutro.
    final background = isToday ? colors.primaryContainer : colors.surfaceContainerHighest;
    final foreground = isToday ? colors.onPrimaryContainer : colors.onSurfaceVariant;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: foreground),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.titleMedium?.copyWith(color: foreground)),
                Text(subtitle, style: textTheme.bodySmall?.copyWith(color: foreground)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

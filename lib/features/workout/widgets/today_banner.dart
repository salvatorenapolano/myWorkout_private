import 'package:flutter/material.dart';

import 'package:my_workout/app_theme.dart';
import 'package:my_workout/models/workout_plan.dart';
import 'package:my_workout/utils/formatters.dart';
import 'package:my_workout/widgets/status_banner.dart';

/// Il riquadro in alto che ti dice cosa tocca oggi, in base al calendario.
///
/// Riceve `now` invece di chiamare DateTime.now() da sola: così nei test
/// possiamo fingere che sia lunedì, domenica o dopo la fine della scheda.
class TodayBanner extends StatelessWidget {
  const TodayBanner({super.key, required this.plan, required this.now});

  final WorkoutPlan plan;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
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
          // Niente orario: l'ora (plan.schedule.time) resta nel JSON
          // ma non la mostriamo.
          plan.name,
          true,
        ),
      _ => (
          Icons.self_improvement,
          'Oggi riposo',
          'Prossimo allenamento ${formatRelativeDay(next.date, now: now)}: '
              '${plan.workoutById(next.workoutId).name}',
          false,
        ),
    };

    // La lettera gigante della scheda ("A" o "B"), solo nei giorni di palestra.
    final letter = isToday ? next?.workoutId : null;

    // L'aspetto (colori, forma, watermark) lo decide StatusBanner:
    // qui scegliamo solo cosa scriverci.
    return StatusBanner(
      icon: icon,
      title: title,
      subtitle: subtitle,
      highlighted: isToday,
      watermark: letter == null
          ? null
          : Text(
              letter,
              style: const TextStyle(
                fontFamily: AppTheme.displayFont,
                fontWeight: FontWeight.w700,
                fontSize: 150,
                height: 1,
              ),
            ),
    );
  }
}

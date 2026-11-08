import 'package:flutter/material.dart';

import 'package:my_workout/app_theme.dart';

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

    // Nei giorni di allenamento il riquadro è petrolio pieno; a riposo è
    // neutro, col colore delle card e un bordo sottile.
    // In tema scuro il "primary" è un azzurro chiaro: per restare sul
    // petrolio scuro usiamo primaryContainer (e il suo colore di testo).
    final dark = Theme.of(context).brightness == Brightness.dark;
    final todayBackground = dark ? colors.primaryContainer : colors.primary;
    final onToday = dark ? colors.onPrimaryContainer : colors.onPrimary;

    final background = isToday ? todayBackground : Theme.of(context).cardTheme.color ?? colors.surface;
    final foreground = isToday ? onToday : colors.onSurface;
    final secondary = isToday ? onToday.withValues(alpha: 0.85) : colors.onSurfaceVariant;

    // La lettera gigante della scheda ("A" o "B"), solo nei giorni di palestra.
    final letter = isToday ? next?.workoutId : null;

    return Container(
      // clipBehavior: taglia tutto ciò che esce dagli angoli arrotondati
      // (qui la lettera gigante, che "sborda" apposta in basso a destra).
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppTheme.radiusHero),
        border: isToday ? null : Border.all(color: colors.outlineVariant),
      ),
      child: Stack(
        children: [
          if (letter != null)
            Positioned(
              right: 12,
              bottom: -34,
              // ExcludeSemantics: è solo decorazione, VoiceOver la salta
              // (il titolo dice già "Oggi: Scheda A").
              child: ExcludeSemantics(
                child: Text(
                  letter,
                  style: TextStyle(
                    fontFamily: AppTheme.displayFont,
                    fontWeight: FontWeight.w700,
                    fontSize: 150,
                    height: 1,
                    color: foreground.withValues(alpha: 0.2),
                  ),
                ),
              ),
            ),
          Padding(
            // A destra lasciamo spazio alla lettera, così il testo non ci finisce sopra.
            padding: EdgeInsets.fromLTRB(20, 20, letter != null ? 96 : 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: isToday ? foreground : colors.primary),
                const SizedBox(height: 12),
                Text(title, style: textTheme.headlineSmall?.copyWith(color: foreground)),
                const SizedBox(height: 2),
                Text(subtitle, style: textTheme.bodyMedium?.copyWith(color: secondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

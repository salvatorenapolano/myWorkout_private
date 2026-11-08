import 'package:flutter/material.dart';

import 'package:my_workout/data/workout_repository.dart';
import 'package:my_workout/features/workout/widgets/exercise_block_tile.dart';
import 'package:my_workout/features/workout/widgets/planned_exercise_tile.dart';
import 'package:my_workout/features/workout/widgets/today_banner.dart';

/// Tab "Allenamento": cosa tocca oggi, scelta A/B e i 4 blocchi della seduta.
class WorkoutPage extends StatefulWidget {
  const WorkoutPage({super.key});

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  // Il caricamento parte UNA volta, quando la pagina nasce.
  // Se lo scrivessimo dentro build() ripartirebbe a ogni ridisegno!
  // `late` = "inizializzalo la prima volta che lo uso".
  late final Future<WorkoutData> _dataFuture = WorkoutRepository().load();

  // La scheda scelta col selettore A/B.
  // null = mostra quella del prossimo allenamento.
  String? _selectedWorkoutId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Allenamento')),
      // FutureBuilder ridisegna la pagina quando il Future cambia stato:
      // in attesa → completato con i dati, oppure → errore.
      body: FutureBuilder<WorkoutData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Non riesco a leggere la scheda:\n${snapshot.error}'),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return _buildContent(snapshot.requireData);
        },
      ),
    );
  }

  Widget _buildContent(WorkoutData data) {
    final plan = data.plan;
    final now = DateTime.now();
    // La seduta di oggi (o la prossima, se oggi è riposo): all'apertura
    // il selettore parte proprio su quella scheda.
    final next = plan.nextSessionFrom(now);

    // L'operatore ?? sceglie il primo valore non null, da sinistra a destra.
    final workout = plan.workoutById(
      _selectedWorkoutId ?? next?.workoutId ?? plan.workouts.first.id,
    );

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        TodayBanner(plan: plan, now: now),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SegmentedButton<String>(
            // Niente spunta sul segmento scelto: al suo posto mostriamo
            // l'icona del calendario sulla scheda di turno.
            showSelectedIcon: false,
            segments: [
              for (final w in plan.workouts)
                ButtonSegment(
                  value: w.id,
                  label: Text(w.name),
                  icon: w.id == next?.workoutId ? const Icon(Icons.today) : null,
                ),
            ],
            selected: {workout.id},
            onSelectionChanged: (selection) {
              setState(() => _selectedWorkoutId = selection.first);
            },
          ),
        ),
        const SizedBox(height: 8),

        // 1 · Riscaldamento
        ExerciseBlockTile(number: 1, block: plan.warmup, data: data),

        // 2 · Pesi: sempre visibile, è la parte principale.
        _SectionTitle('2 · Pesi · ${workout.name}'),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            plan.generalNotes,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        // .indexed dà coppie (posizione, esercizio): la posizione parte da 0.
        for (final (index, planned) in workout.exercises.indexed)
          PlannedExerciseTile(
            number: index + 1,
            planned: planned,
            exercise: data.exerciseFor(planned),
            sectionTitle: workout.name,
          ),

        // 3 · Addominali
        ExerciseBlockTile(number: 3, block: plan.abs, data: data),

        // 4 · Cardio
        ListTile(
          leading: const Icon(Icons.directions_walk),
          title: Text('4 · ${plan.cardio.title}'),
          subtitle: Text('${plan.cardio.durationMinutes} min · ${plan.cardio.description}'),
        ),
      ],
    );
  }
}

/// Titolo di sezione. È privato (inizia con _) perché serve solo qui.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

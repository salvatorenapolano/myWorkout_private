import 'package:flutter/material.dart';

import 'package:my_workout/data/workout_repository.dart';
import 'package:my_workout/features/workout/widgets/exercise_block_tile.dart';
import 'package:my_workout/features/workout/widgets/planned_exercise_tile.dart';
import 'package:my_workout/features/workout/widgets/step_number.dart';
import 'package:my_workout/features/workout/widgets/today_banner.dart';
import 'package:my_workout/utils/formatters.dart';
import 'package:my_workout/widgets/dividers.dart';

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
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        TodayBanner(plan: plan, now: now),
        const SizedBox(height: 16),

        SegmentedButton<String>(
          // Niente spunta sul segmento scelto: al suo posto mostriamo
          // l'icona del calendario sulla scheda di turno.
          showSelectedIcon: false,
          // expandedInsets: il selettore si allarga a tutta la larghezza
          // disponibile (qui con zero margini extra).
          expandedInsets: EdgeInsets.zero,
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
        const SizedBox(height: 24),

        // 1 · Riscaldamento
        ExerciseBlockTile(number: 1, block: plan.warmup, data: data),
        const SizedBox(height: 24),

        // 2 · Pesi: sempre visibile, è la parte principale.
        // Il titolo sta fuori dalla card, le righe dentro.
        _SectionTitle(number: 2, text: 'Pesi · ${workout.name}'),
        const SizedBox(height: 8),
        Card(
          child: Column(
            // withDividers mette una linea sottile tra una riga e l'altra.
            children: withDividers(indent: 80, [
              // .indexed dà coppie (posizione, esercizio): la posizione parte da 0.
              for (final (index, planned) in workout.exercises.indexed)
                PlannedExerciseTile(
                  number: index + 1,
                  planned: planned,
                  exercise: data.exerciseFor(planned),
                  sectionTitle: workout.name,
                ),
            ]),
          ),
        ),
        const SizedBox(height: 24),

        // 3 · Addominali
        ExerciseBlockTile(number: 3, block: plan.abs, data: data),
        const SizedBox(height: 12),

        // 4 · Cardio: ⏱️ 30 min  ⛰️ 10%  💨 5,5 km/h
        Card(
          child: ListTile(
            leading: const StepNumber(4),
            title: Text(plan.cardio.title, style: Theme.of(context).textTheme.titleLarge),
            // Wrap: i tre dati stanno su una riga e vanno a capo
            // da soli se lo schermo è stretto.
            subtitle: Wrap(
              spacing: 16,
              children: [
                Text('⏱️ ${plan.cardio.durationMinutes} min'),
                Text('⛰️ ${formatNumber(plan.cardio.inclinePercent)}%'),
                Text('💨 ${formatNumber(plan.cardio.speedKmh)} km/h'),
              ],
            ),
            trailing: const Icon(Icons.directions_walk),
          ),
        ),
      ],
    );
  }
}

/// Titolo di sezione col numero della parte di seduta, allineato
/// ai numeri che stanno dentro le card (stesso rientro del ListTile).
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          StepNumber(number),
          const SizedBox(width: 16),
          Text(text, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}

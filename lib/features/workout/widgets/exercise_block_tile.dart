import 'package:flutter/material.dart';

import 'package:my_workout/data/workout_repository.dart';
import 'package:my_workout/features/workout/widgets/planned_exercise_tile.dart';
import 'package:my_workout/models/workout_plan.dart';

/// Riscaldamento e addominali: un blocco che si apre e si chiude.
class ExerciseBlockTile extends StatelessWidget {
  const ExerciseBlockTile({
    super.key,
    required this.number,
    required this.block,
    required this.data,
  });

  final int number;
  final ExerciseBlock block;
  final WorkoutData data;

  @override
  Widget build(BuildContext context) {
    final intro = block.intro;
    final minutes = block.durationMinutes;
    return ExpansionTile(
      title: Text('$number · ${block.title}'),
      subtitle: Text([
        if (minutes != null) '$minutes min',
        '${block.exercises.length} esercizi',
      ].join(' · ')),
      children: [
        if (intro != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(intro),
          ),
        for (final planned in block.exercises)
          PlannedExerciseTile(
            planned: planned,
            exercise: data.exerciseFor(planned),
            sectionTitle: block.title,
          ),
      ],
    );
  }
}

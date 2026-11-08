import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_workout/data/workout_repository.dart';
import 'package:my_workout/features/workout/widgets/today_banner.dart';

void main() {
  final plan = WorkoutRepository.parse(
    planJson: File('assets/data/workout_plan.json').readAsStringSync(),
    exercisesJson: File('assets/data/exercises.json').readAsStringSync(),
  ).plan;

  // Disegna solo il banner, fingendo che oggi sia `now`.
  Future<void> pumpBanner(WidgetTester tester, DateTime now) {
    return tester.pumpWidget(
      MaterialApp(home: Scaffold(body: TodayBanner(plan: plan, now: now))),
    );
  }

  testWidgets('giorno di allenamento: mostra la scheda di oggi', (tester) async {
    await pumpBanner(tester, DateTime(2026, 11, 9, 8)); // lunedì
    expect(find.text('Oggi: Scheda B'), findsOneWidget);
  });

  testWidgets('giorno di riposo: dice quando è il prossimo', (tester) async {
    await pumpBanner(tester, DateTime(2026, 11, 8)); // domenica
    expect(find.text('Oggi riposo'), findsOneWidget);
    expect(find.textContaining('domani alle 15:00: Scheda B'), findsOneWidget);
  });

  testWidgets('dopo il 27/11 la scheda è terminata', (tester) async {
    await pumpBanner(tester, DateTime(2026, 11, 30));
    expect(find.text('Scheda terminata'), findsOneWidget);
  });
}

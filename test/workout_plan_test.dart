import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import 'package:my_workout/data/workout_repository.dart';
import 'package:my_workout/utils/formatters.dart';

void main() {
  // Usiamo i file JSON veri: se li modifichi e rompi qualcosa, il test lo dice.
  final planJson = File('assets/data/workout_plan.json').readAsStringSync();
  final exercisesJson = File('assets/data/exercises.json').readAsStringSync();
  final data = WorkoutRepository.parse(planJson: planJson, exercisesJson: exercisesJson);
  final plan = data.plan;

  group('Lettura JSON', () {
    test('legge schede e blocchi', () {
      expect(plan.workouts.map((w) => w.id), ['A', 'B']);
      expect(plan.warmup.exercises, hasLength(8));
      expect(
        plan.abs.exercises.map((p) => p.exerciseId),
        ['plank', 'plank_laterale', 'leg_raise', 'heel_touch'],
      );
      expect(plan.cardio.title, 'Cardio');
      expect(plan.cardio.durationMinutes, 30);
      expect(plan.cardio.inclinePercent, 10);
      expect(plan.cardio.speedKmh, 5.5);
      // Il plank sta solo negli addominali, non più tra i pesi della Scheda A.
      expect(plan.workoutById('A').exercises.map((p) => p.exerciseId), isNot(contains('plank')));
      expect(data.exerciseFor(plan.workoutById('A').exercises.first).name, 'Leg press');
    });

    test('un id sbagliato dà un errore chiaro', () {
      final broken = planJson.replaceFirst('"leg_press"', '"leg_pres"');
      expect(
        () => WorkoutRepository.parse(planJson: broken, exercisesJson: exercisesJson),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('Calendario come nel PDF', () {
    test('18 sedute, dal 19/10 (A) al 27/11 (B)', () {
      final sessions = plan.sessions;
      expect(sessions, hasLength(18));
      expect(sessions.first.date, DateTime(2026, 10, 19));
      expect(sessions.first.workoutId, 'A');
      expect(sessions.last.date, DateTime(2026, 11, 27));
      expect(sessions.last.workoutId, 'B');
    });

    test("supera il cambio dell'ora legale (25/10)", () {
      // Settimana 2: lunedì 26/10 Scheda B.
      final session = plan.sessions[3];
      expect(session.date, DateTime(2026, 10, 26));
      expect(session.workoutId, 'B');
    });

    test('domenica 8/11 → lunedì 9/11, Scheda B', () {
      final next = plan.nextSessionFrom(DateTime(2026, 11, 8, 10, 30))!;
      expect(next.date, DateTime(2026, 11, 9));
      expect(next.workoutId, 'B');
    });

    test('nel giorno di allenamento, la seduta è oggi', () {
      final next = plan.nextSessionFrom(DateTime(2026, 11, 11, 18))!;
      expect(next.date, DateTime(2026, 11, 11));
      expect(next.workoutId, 'A');
    });

    test('dopo il 27/11 la scheda è finita', () {
      expect(plan.nextSessionFrom(DateTime(2026, 11, 28)), isNull);
    });
  });

  group('Formattazione', () {
    test('recupero', () {
      expect(formatRest(120), "2'");
      expect(formatRest(90), '90"');
      expect(formatRest(60), '60"');
    });

    test('giorni', () {
      final now = DateTime(2026, 11, 8);
      expect(formatRelativeDay(DateTime(2026, 11, 8), now: now), 'oggi');
      expect(formatRelativeDay(DateTime(2026, 11, 9), now: now), 'domani');
      expect(formatRelativeDay(DateTime(2026, 11, 11), now: now), 'mercoledì 11 novembre');
    });

    test('pesi', () {
      expect(formatWeight(16), '16 kg');
      expect(formatWeight(22.5), '22,5 kg');
      expect(parseNumber('22,5'), 22.5);
      expect(parseNumber(' 40 '), 40);
      expect(parseNumber('tanti'), isNull);
    });
  });

  test('i link YouTube sono validi e solo sugli esercizi coi pesi', () {
    final withVideo = data.exercises.values.where((e) => e.videoUrl != null).toList();
    // 13 dei 14 esercizi coi pesi: solo il goblet squat non ha una macchina gym80.
    expect(withVideo, hasLength(13));
    for (final e in withVideo) {
      expect(YoutubePlayerController.convertUrlToId(e.videoUrl!), isNotNull, reason: e.id);
      expect(e.hasWeight, isTrue, reason: e.id);
    }
  });

  test('ogni esercizio ha la sua anteprima SVG', () {
    final missing = data.exercises.values
        .where((e) => !File(e.previewAsset).existsSync())
        .map((e) => e.id)
        .toList();
    expect(missing, isEmpty, reason: 'Rilancia tool/generate_exercise_previews.py');
  });

  test('le illustrazioni dei muscoli esistono, solo sugli esercizi coi pesi', () {
    final withImage = data.exercises.values.where((e) => e.muscleAsset != null).toList();
    // Tutti e 14 gli esercizi coi pesi hanno la loro illustrazione.
    expect(withImage, hasLength(14));
    for (final e in withImage) {
      expect(File(e.muscleAsset!).existsSync(), isTrue, reason: e.muscleAsset);
      expect(e.hasWeight, isTrue, reason: e.id);
    }
  });
}

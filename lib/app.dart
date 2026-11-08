import 'package:flutter/material.dart';

import 'package:my_workout/data/weight_store.dart';
import 'package:my_workout/home_shell.dart';

/// Il widget radice: configura tema, titolo e la prima schermata.
///
/// È uno StatelessWidget perché non ha dati che cambiano nel tempo:
/// si limita a "descrivere" l'app.
class MyWorkoutApp extends StatelessWidget {
  const MyWorkoutApp({super.key, required this.weights});

  /// I pesi salvati: li mettiamo "sopra" tutta l'app con WeightScope,
  /// così ogni schermata li può leggere con WeightScope.of(context).
  final WeightStore weights;

  // Il colore "seme": Material 3 ne ricava da solo tutta la palette
  // (pulsanti, schede selezionate, sfondi tenui...) in chiaro e in scuro.
  // Verde petrolio: calmo, e non litiga coi badge colorati degli esercizi.
  // Per provarne un altro cambia solo questa riga e salva (hot reload).
  static const _seedColor = Color(0xFF0E7C86);

  @override
  Widget build(BuildContext context) {
    return WeightScope(store: weights, child: _buildApp());
  }

  Widget _buildApp() {
    return MaterialApp(
      title: 'myWorkout',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: _seedColor),
      ),
      // Tema scuro: l'app lo usa da sola se l'iPhone è in modalità scura.
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.dark,
        ),
      ),
      home: const HomeShell(),
    );
  }
}

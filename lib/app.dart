import 'package:flutter/material.dart';

import 'package:my_workout/app_theme.dart';
import 'package:my_workout/data/body_weight_store.dart';
import 'package:my_workout/data/shopping_store.dart';
import 'package:my_workout/data/weight_store.dart';
import 'package:my_workout/home_shell.dart';

/// Il widget radice: configura tema, titolo e la prima schermata.
///
/// È uno StatelessWidget perché non ha dati che cambiano nel tempo:
/// si limita a "descrivere" l'app.
class MyWorkoutApp extends StatelessWidget {
  const MyWorkoutApp({
    super.key,
    required this.weights,
    required this.bodyWeights,
    required this.shopping,
  });

  /// I pesi salvati: li mettiamo "sopra" tutta l'app con WeightScope,
  /// così ogni schermata li può leggere con WeightScope.of(context).
  final WeightStore weights;

  /// Lo storico delle pesate settimanali (tab Pesata).
  final BodyWeightStore bodyWeights;

  /// Le spunte della lista della spesa (tab Spesa).
  final ShoppingStore shopping;

  @override
  Widget build(BuildContext context) {
    // Tre "scope" uno dentro l'altro: ognuno rende disponibile il suo store.
    return WeightScope(
      store: weights,
      child: BodyWeightScope(
        store: bodyWeights,
        child: ShoppingScope(store: shopping, child: _buildApp()),
      ),
    );
  }

  Widget _buildApp() {
    return MaterialApp(
      title: 'myWorkout',
      debugShowCheckedModeBanner: false,
      // Colori, font e forme stanno tutti in app_theme.dart.
      // Per provare un altro colore seme cambia AppTheme.seedColor.
      theme: AppTheme.light(),
      // Tema scuro: l'app lo usa da sola se l'iPhone è in modalità scura.
      darkTheme: AppTheme.dark(),
      home: const HomeShell(),
    );
  }
}

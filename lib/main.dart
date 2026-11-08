import 'package:flutter/material.dart';

import 'package:my_workout/app.dart';
import 'package:my_workout/data/body_weight_store.dart';
import 'package:my_workout/data/shopping_store.dart';
import 'package:my_workout/data/weight_store.dart';

// Punto di ingresso: Dart esegue sempre main() per primo.
// È `async` perché, prima di disegnare l'app, apriamo la memoria del
// telefono dove sono salvati i pesi (esercizi e pesate) e le spunte della spesa.
Future<void> main() async {
  // Serve prima di usare plugin nativi (come shared_preferences) in main().
  WidgetsFlutterBinding.ensureInitialized();
  final weights = await WeightStore.load();
  final bodyWeights = await BodyWeightStore.load();
  final shopping = await ShoppingStore.load();
  runApp(MyWorkoutApp(weights: weights, bodyWeights: bodyWeights, shopping: shopping));
}

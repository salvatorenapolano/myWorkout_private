import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_workout/app.dart';
import 'package:my_workout/data/body_weight_store.dart';
import 'package:my_workout/data/shopping_store.dart';
import 'package:my_workout/data/weight_store.dart';

void main() {
  late WeightStore weights;
  late BodyWeightStore bodyWeights;
  late ShoppingStore shopping;

  setUp(() async {
    // rootBundle tiene in cache i file già letti. Nei test ogni testWidgets
    // ha il suo "tempo finto": un caricamento iniziato nel test precedente
    // non si completerebbe mai in quello dopo. Svuotiamo la cache ogni volta.
    rootBundle.clear();
    SharedPreferences.setMockInitialValues({'weight_goblet_squat': 16.0});
    weights = await WeightStore.load();
    bodyWeights = await BodyWeightStore.load();
    shopping = await ShoppingStore.load();
  });

  testWidgets('La tab Allenamento mostra la scheda dal JSON', (tester) async {
    await tester.pumpWidget(MyWorkoutApp(weights: weights, bodyWeights: bodyWeights, shopping: shopping));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Scheda A'));
    await tester.pumpAndSettle();
    expect(find.text('Leg press'), findsOneWidget);
    expect(find.text("3 × 10–12 · rec. 2'"), findsOneWidget);

    await tester.tap(find.text('Scheda B'));
    await tester.pumpAndSettle();
    expect(find.text('Goblet squat'), findsOneWidget);
    // Il peso salvato compare già nella riga.
    expect(find.text('16 kg'), findsOneWidget);
  });

  testWidgets('Nel dettaglio il peso cambia e la lista si aggiorna', (tester) async {
    await tester.pumpWidget(MyWorkoutApp(weights: weights, bodyWeights: bodyWeights, shopping: shopping));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scheda B'));
    await tester.pumpAndSettle();

    // Apro il dettaglio del goblet squat.
    await tester.tap(find.text('Goblet squat'));
    await tester.pumpAndSettle();
    expect(find.text('Il tuo peso'), findsOneWidget);
    expect(find.text('16 kg'), findsOneWidget);

    // + aumenta di 1 kg.
    await tester.tap(find.byTooltip('Aumenta'));
    await tester.pumpAndSettle();
    expect(find.text('17 kg'), findsOneWidget);

    // Scrivo il peso a mano nel dialog.
    await tester.tap(find.text('17 kg'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '22,5');
    await tester.tap(find.text('Salva'));
    await tester.pumpAndSettle();
    expect(find.text('22,5 kg'), findsOneWidget);

    // La card Muscoli: toccandola si apre lo schermo intero con lo zoom.
    // ensureVisible scorre la pagina finché la card è sullo schermo.
    await tester.ensureVisible(find.text('Tocca per ingrandire'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tocca per ingrandire'));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // La pagina è lunga: scorro finché compare la spiegazione.
    await tester.scrollUntilVisible(find.text('Come si esegue'), 200);
    expect(find.text('Come si esegue'), findsOneWidget);

    // Torno indietro: la riga nella lista mostra il nuovo peso.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('22,5 kg'), findsOneWidget);
    expect(weights.weightFor('goblet_squat'), 22.5);
  });

  testWidgets('La barra in basso cambia pagina', (tester) async {
    await tester.pumpWidget(MyWorkoutApp(weights: weights, bodyWeights: bodyWeights, shopping: shopping));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.restaurant_menu_outlined));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Dieta'), findsOneWidget);

    // Scelgo lunedì dalle schede in alto.
    await tester.tap(find.widgetWithText(Tab, 'Lun'));
    await tester.pumpAndSettle();
    expect(find.text('Pasta al pomodoro e tonno'), findsOneWidget);
    expect(find.text('Palestra'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.shopping_cart_outlined));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Spesa'), findsOneWidget);
  });

  testWidgets('Tab Pesata: aggiungo, correggo e cancello una pesata', (tester) async {
    await tester.pumpWidget(MyWorkoutApp(weights: weights, bodyWeights: bodyWeights, shopping: shopping));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.monitor_weight_outlined));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Pesata settimanale'), findsOneWidget);
    expect(find.textContaining('Nessuna pesata salvata'), findsOneWidget);

    // Il + apre il dialog: scrivo il peso di oggi.
    await tester.tap(find.byTooltip('Aggiungi pesata'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '78,4');
    await tester.tap(find.text('Salva'));
    await tester.pumpAndSettle();
    expect(find.text('78,4 kg'), findsOneWidget);
    expect(bodyWeights.entries.single.kg, 78.4);

    // Tocco la riga per correggerla.
    await tester.tap(find.text('78,4 kg'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '78');
    await tester.tap(find.text('Salva'));
    await tester.pumpAndSettle();
    expect(find.text('78 kg'), findsOneWidget);

    // Trascino la riga verso sinistra: sparisce, poi "Annulla" la rimette.
    await tester.drag(find.text('78 kg'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(bodyWeights.entries, isEmpty);
    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();
    expect(find.text('78 kg'), findsOneWidget);
  });

  testWidgets('Tab Spesa: spunto, Reset e Annulla', (tester) async {
    await tester.pumpWidget(MyWorkoutApp(weights: weights, bodyWeights: bodyWeights, shopping: shopping));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.shopping_cart_outlined));
    await tester.pumpAndSettle();

    // Si apre sulla spesa settimanale: spunto le uova.
    expect(find.text('Proteine e latticini'), findsOneWidget);
    await tester.tap(find.text('Uova'));
    await tester.pumpAndSettle();
    expect(shopping.isChecked('uova'), isTrue);
    expect(find.text('1/7'), findsOneWidget);

    // Reset toglie la spunta, Annulla la rimette.
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    expect(shopping.isChecked('uova'), isFalse);
    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();
    expect(shopping.isChecked('uova'), isTrue);

    // Nella scheda Mensile ci sono i prodotti della dispensa.
    await tester.tap(find.widgetWithText(Tab, 'Mensile'));
    await tester.pumpAndSettle();
    expect(find.text('Whey con creatina'), findsOneWidget);
  });
}

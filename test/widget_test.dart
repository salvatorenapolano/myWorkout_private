import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_workout/app.dart';
import 'package:my_workout/data/weight_store.dart';

void main() {
  late WeightStore weights;

  setUp(() async {
    // rootBundle tiene in cache i file già letti. Nei test ogni testWidgets
    // ha il suo "tempo finto": un caricamento iniziato nel test precedente
    // non si completerebbe mai in quello dopo. Svuotiamo la cache ogni volta.
    rootBundle.clear();
    SharedPreferences.setMockInitialValues({'weight_goblet_squat': 16.0});
    weights = await WeightStore.load();
  });

  testWidgets('La tab Allenamento mostra la scheda dal JSON', (tester) async {
    await tester.pumpWidget(MyWorkoutApp(weights: weights));
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
    await tester.pumpWidget(MyWorkoutApp(weights: weights));
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
    await tester.pumpWidget(MyWorkoutApp(weights: weights));
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
}

# myWorkout — contesto del progetto

App Flutter personale per iPhone: la mia scheda di allenamento, la dieta settimanale, la pesata del venerdì e la lista della spesa.
È anche un progetto **per imparare Flutter**: procediamo step by step.

## Come lavoriamo

- **Lingua**: rispondi in italiano. Spiega i concetti Flutter/Dart nuovi che ogni modifica introduce; commenti nel codice in italiano.
- **Ambiente**: Windows 11, VS Code + Android Studio, Flutter 3.47.9 (Dart 3.13). Provo l'app su un **emulatore Android** (la lancio io con F5); per iPhone compilo nel cloud (vedi "Build iPhone").
- **Verifica**: ogni modifica si chiude con `flutter analyze` (zero problemi) e `flutter test` (tutti verdi). Non installare/avviare l'app sul mio emulatore al posto mio.
- **Codice su GitHub**: https://github.com/salvatorenapolano/myWorkout (branch `main`, privato).

## Stato delle funzioni

| Tab | Stato |
|---|---|
| **Allenamento** | ✅ Fatto: scheda del giorno, A/B, dettaglio esercizio con video e pesi salvati |
| **Dieta** | ✅ Fatto: settimana tipo, pranzo e cena |
| **Pesata** | ✅ Fatto: promemoria del venerdì, storico pesate con differenze |
| **Spesa** | ✅ Fatto: liste Settimanale / Mensile con spunte e Reset |

## Stack

- Flutter + Material 3, tema chiaro/scuro automatico. Colore seme **verde petrolio `0xFF0E7C86`** (il rosso non mi piace), variante `DynamicSchemeVariant.fidelity` per tenere il petrolio pieno.
- Stile "lavagna della sala pesi": font **Barlow Semi Condensed** (in `assets/fonts/`, licenza OFL) per titoli e numeri, font di sistema per il testo; raggi 28 (banner) / 20 (card) / 12 (riquadri interni); pagine grigio chiaro con card bianche (in scuro: card più chiare dello sfondo). Tutto in `lib/app_theme.dart`.
- Pacchetti: `flutter_svg` (anteprime), `shared_preferences` (pesi salvati), `youtube_player_iframe` (video).
- Nessun backend: i contenuti sono **file JSON negli asset**, i dati dell'utente (pesi) sono salvati sul telefono.
- Android: permesso `INTERNET` nel manifest (serve ai video). Nome app sotto l'icona: **myWorkout**. Bundle id `com.salva.my_workout`.
- Icona: dopo `dart run flutter_launcher_icons` **ripristinare** `ios/Runner.xcodeproj/project.pbxproj` (`git checkout -- …`): la v0.14.4 lo modifica per errore (mette `AppIcon` in `ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS`).

## Struttura del codice

```
lib/
├── main.dart                 # carica WeightStore poi runApp
├── app.dart                  # MaterialApp, WeightScope sopra tutto
├── app_theme.dart            # AppTheme.light()/dark(): colori, font, raggi, componenti
├── home_shell.dart           # NavigationBar 3 tab + IndexedStack
├── models/                   # exercise.dart, workout_plan.dart, diet.dart (fromJson)
├── data/                     # workout_repository, diet_repository (leggono e validano i JSON)
│                             # weight_store.dart (ChangeNotifier + InheritedNotifier WeightScope)
├── utils/formatters.dart     # formatRest (120→2', 90→90"), formatWeight (22,5 kg), date in italiano
└── features/
    ├── workout/              # workout_page, exercise_detail_page, widgets/ (today_banner,
    │                         #   planned_exercise_tile, exercise_block_tile, exercise_media, exercise_preview, step_number)
    ├── diet/                 # diet_page (TabBar Lun…Dom), widgets/ (diet_day_view, meal_card)
    ├── weigh_in/             # weigh_in_page (storico, +), widgets/weigh_in_banner
    └── shopping/             # shopping_page (schede Settimanale/Mensile, checkbox, Reset)
lib/widgets/                  # condivisi: status_banner (riquadro in cima), weight_input_dialog, dividers
assets/data/                  # exercises.json, workout_plan.json, diet.json
assets/images/exercises/      # <id>.svg, una anteprima per esercizio
assets/images/muscles/        # illustrazioni muscoli (.webp scontornati, sfondo trasparente), scelte con "muscleImage"
tool/generate_exercise_previews.py   # genera tutti gli SVG (pose + colori)
tool/prepare_muscle_images.py        # ritaglia e scontorna le illustrazioni dei muscoli (python … <cartella_originali>)
tool/generate_app_icon.py            # icona: 💪 Noto (Apache 2.0) su gradiente petrolio → assets/icon/
flutter_launcher_icons.yaml          # poi `dart run flutter_launcher_icons` crea tutte le misure iOS/Android
test/                         # test su JSON, calendario, banner, pesi, widget
codemagic.yaml                # build iOS nel cloud
```

## I dati

### `exercises.json` — libreria esercizi (il "come")
Ogni esercizio: `id`, `name`, `category` (`warmup` | `weights` | `abs`), `muscles[]`, `description`, `tips[]`, `images[]`, `videoUrl`.
- Solo `weights` ha il riquadro "Il tuo peso".
- `videoUrl`: video YouTube presi dalle **pagine prodotto di gym80.de** (es. leg press → gym80.de/en/product/3030/). 13 esercizi coi pesi su 14 hanno un video; il goblet squat no.
- L'anteprima è `assets/images/exercises/<id>.svg` (ricavata dall'id).
- `muscleImage` (facoltativo, solo pesi): nome dell'illustrazione in `assets/images/muscles/` (petto, dorsali, femorali, spalle, bicipiti, tricipiti, glutei, retto_addominale, quadricipiti; addome_obliqui per ora non usata). Tutti i 14 esercizi coi pesi ce l'hanno.

### `workout_plan.json` — la scheda (il "quanto")
Fase 1 · Rimettersi in forma, v2 del personal trainer.
- `schedule`: lunedì, mercoledì, venerdì alle 15:00, rotazione **A, B, A, B…** dal **19/10/2026** al **27/11/2026** (18 sedute). Il calendario si calcola, non è scritto riga per riga.
- Seduta = **1 Riscaldamento** (10 min, 8 esercizi) → **2 Pesi** (Scheda A: 7 esercizi, Scheda B: 8) → **3 Addominali** (plank 3×30" +5"/settimana, plank laterale 20" per lato, leg raise 10–12, heel touch 12 per lato) → **4 Cardio** sul tapis roulant (`durationMinutes` 30, `inclinePercent` 10, `speedKmh` 5,5; in app: "⏱️ 30 min  ⛰️ 10%  💨 5,5 km/h").
- Ogni esercizio in scheda: `exerciseId`, `sets?`, `reps` (testo: "10–12", "30\"", "12 per lato"), `restSeconds?`, `notes?`, `alternatives[]` ("se è occupato").
- Nota generale: finire ogni serie con 2–3 ripetizioni "nel serbatoio".

### `diet.json` — la settimana tipo
- Catalogo `foods` (id, nome, **reparto**: Frutta e verdura, Carne e pesce, Frigo, Pane, Dispensa). La spesa NON è calcolata da qui: ha il suo `shopping.json`.
- `days`: 7 giorni, `training` true lun/mer/ven, ognuno con pasti `pranzo` (13:00) e `cena` (19:30–20:00). Domenica un unico slot "Pranzo e cena" libero con 3 regole.
- Ingredienti: `foodId`, `quantity?`, `quantityMax?` (intervalli 250–300 g), `unit`, `note`.
- Extra: riquadro "legumi a scelta" (solo mar/gio), note "Da sapere".
- `alternative` di un pasto = riquadro "se manca": martedì cena "Se manca il salmone…", lunedì cena "Se mancano le patate: 250–300 g di verdure." (le verdure non sono tra gli ingredienti). Mercoledì cena senza insalata (l'alimento resta nel catalogo, per ora non usato).
- Colazione e spuntini **mancano** (sono in un altro PDF, "La mia giornata", non ancora fornito).

### `shopping.json` — la lista della spesa
Due liste (`Settimanale` · fresco, `Mensile` · dispensa), ognuna con sezioni e prodotti `{id, name, quantity?}`, trascritte dal PDF del nutrizionista. Gli `id` devono essere unici (il repository lo controlla) e non vanno cambiati: servono a ricordare le spunte.

### Dati dell'utente (tutti in `shared_preferences`)
- Pesi per esercizio: chiave `weight_<exerciseId>`, in kg (anche decimali). Non è una checklist delle serie: è solo un promemoria del peso usato.
- Pesate: chiave `body_weights`, testo JSON `[{"date": "2026-11-06", "kg": 78.4}, …]`, una per giorno (`BodyWeightStore`).
- Spunte della spesa: chiave `shopping_checked`, lista degli id spuntati (`ShoppingStore`).

## Com'è fatta l'interfaccia

**Allenamento**
- In alto `TodayBanner`: "Oggi: Scheda A" (colorato) / "Oggi riposo · prossimo allenamento domani: Scheda B" / "Scheda terminata". Senza orario (resta nel JSON).
- Selettore Scheda A / Scheda B: parte sulla scheda di turno, che ha un'icona calendario.
- Sotto "2 · Pesi" niente nota generale (resta nel JSON).
- Righe esercizio: anteprima SVG (con **numero d'ordine** nell'angolo, solo nei pesi), nome, "3 × 10–12 · rec. 90\"", peso salvato a destra.
- Riscaldamento e addominali sono blocchi espandibili.

**Dettaglio esercizio** (tap su una riga): video YouTube al posto dell'anteprima se c'è, nome, card "in scheda" (serie, recupero, note), card **Il tuo peso** (− / + di 1 kg, tap per scriverlo), card **Muscoli** (illustrazione anatomica con muscolo in rosso + elenco; tap = schermo intero con zoom), "Come si esegue", consigli, "Se è occupato". Senza illustrazione i muscoli restano chip sotto il nome.

**Dieta**: schede Lun…Dom (si apre su oggi), chip **Palestra giallo** / Riposo bianco, una card per pasto: **☀️ Pranzo (13:00) con sfondo giallo tenue, 🌙 Cena (20:00) con sfondo blu tenue**. Intestazione del pasto centrata con divisore sotto, ingredienti a pallini. Niente riquadro "Da sapere" (le note restano nel JSON).

**Pesata** (tab con la bilancia): banner in cima solo col titolo, senza descrizione: "Oggi ti devi pesare" il venerdì (petrolio), "Pesata fatta: 78,4 kg", "Pesata di venerdì da fare" se l'hai saltata, altrimenti "Prossima pesata …". Storico dalla più recente: data, differenza dalla precedente (+0,4 / −0,6 / ±0), peso. **+** = pesata di oggi (se c'è già la sostituisce), tocco = correggi, trascina a sinistra = cancella (con Annulla).

**Spesa**: schede Settimanale / Mensile, sezioni con contatore "3/7", prodotto con checkbox e quantità; spuntato = barrato. Tasto **Reset** sempre in basso a destra: toglie le spunte **della scheda aperta** (la mensile non si azzera col reset settimanale), con Annulla.

**Anteprime esercizi**: stile "badge colorato" — omino bianco su quadrato arrotondato colorato per gruppo muscolare (gambe blu, petto rosa, schiena indaco, spalle viola, braccia arancio, core verde, riscaldamento corallo). Si rigenerano con `python tool/generate_exercise_previews.py`.

## Decisioni già prese (non riproporle)

- Niente card grande "prossimo allenamento": c'è il banner del giorno.
- Niente pulsante "avvia recupero" / timer per ora.
- Niente stretching finale.
- Plank solo negli addominali, non nella Scheda A.
- Dieta generica: giorni della settimana senza date.
- Video solo da gym80 (pagine prodotto gym80.de).

## Build iPhone (da Windows)

1. Push su GitHub → **Codemagic** usa `codemagic.yaml` (workflow "iOS per Sideloadly"): `flutter test`, poi `flutter build ios --release --no-codesign`, poi crea `myWorkout.ipa`.
2. **Sideloadly** su Windows (con iTunes/iCloud dal sito Apple) firma l'ipa con il mio Apple ID gratuito e lo installa via cavo.
3. Sull'iPhone: Modalità sviluppatore + "Autorizza" lo sviluppatore.
4. La firma gratuita **scade ogni 7 giorni**: si reinstalla sopra, i pesi restano. Alternativa futura: Apple Developer Program (99 €/anno) + TestFlight.

## Figma

File "myWorkout" con wireframe iniziali (pagine Wireframe/Componenti/Design, variabili colore e stili testo iOS). Il piano Starter ha esaurito le chiamate MCP, quindi il file non riflette le ultime modifiche: oggi **il riferimento è l'app**, non Figma.

## Da fare / idee

1. **Colazione e spuntini** quando arriva il PDF "La mia giornata".
2. ~~Icona dell'app~~ ✅ fatta: 💪 Noto Emoji su gradiente petrolio (colore principale).
3. Possibili: timer di recupero, storico dei pesi degli esercizi, grafico delle pesate, schede future dopo il 27/11.
4. Le descrizioni di plank laterale, leg raise e heel touch sono state scritte da Claude, non dal PT: da verificare.

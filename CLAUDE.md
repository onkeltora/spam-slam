# Spam Slam – Claude Context File

> Hinweis: Die `CLAUDE.md` im übergeordneten Ordner `SPIELENTWICKLUNG/` gehört zu **Pin a Million**
> und wird mitgeladen. Für dieses Projekt gilt diese Datei + `spam-filter-simulator-GDD.md`.

## Projekt
Reaktions-Sortier-Arcade (Godot 4.7, GDScript, GL Compatibility, Landscape 1280×720, mobile-first).
Kernloop (GDD Abschnitt 12) ist gebaut und läuft; onkeltora hat entschieden, ab hier Richtung
**vollwertiges Spiel** weiterzubauen statt neue Prototyp-Features. Vorgehen: erst das Rückgrat
(Meta-Progression), danach eine Ären-Skin-Abstraktion, erst dann Content pro Ära – beides jetzt
gebaut (siehe "Meta-Progression" und "Ären-System" unten), weil die DullOS-98-Oberfläche technisch
die Rendering-Schicht des gesamten Spiels war (MailCard/SortFolder/ScreenLayout etc.), nicht nur
"Ären-Content 90er", und sonst nachträglich hätte verallgemeinert werden müssen.

## Festgelegte Design-Entscheidungen (Prototyp v1)
- **Setting ~1999–2004:** Ego-Blick auf einen Röhrenmonitor („DullTron 17"“) mit Fantasie-OS **DullOS 98**
  (98-Look, dezenter CRT-Shader). Bewusst KEIN echtes Windows (keine Logos/Markennamen/Bliss-Wallpaper).
  Inhalte passend zur Zeit: Pixel-Smileys statt Emojis, .biz statt .xyz, Aktien-Tipps, DM-Beträge,
  deutsche Firmen-/Betrüger-Mails im „Sie“. Spieler-Anleitung (Titel) bleibt im „Du“.
- **Ego-Perspektive + Warteschlange:** Immer nur die vorderste Mail ist aktiv; Swipe irgendwo = sortieren.
  Dahinter kaskadieren die wartenden Fenster. Stapel = alle unsortierten Mails; `PILE_MAX` (12) =
  Fenster-Glitch + **Bluescreen** = Game Over. Leben weg = Monitor schaltet ab (CRT-Power-Off).
- **Diegetisches UI:** 4 Desktop-Ordner = Sortierziele, Regel = Post-it am Monitor, Stapelanzeige =
  Taskleisten-Button „Posteingang (n)“, Ansagen = DullOS-Dialogbox, Chef-Challenge = DullMessenger-Toast.
  Außerhalb des Monitors (HUD): Punkte/Leben links, Kaffeetasse, Webcam-Portrait.
- **Zeitkolorit-Deko:** Desktop-Icons `hairy_pussy.jpg` (ist natürlich ein Katzenbild), OCQ (ICQ),
  WhipAmp (Winamp), AOFF – America Offline (AOL); AOFF-Gratis-CD auf dem Tisch. Chef-Toast = OCQ,
  OCQ-Blume blinkt im Tray während der Chef-Challenge; WhipAmp-Visualizer im Tray zeigt die ECHTE
  Musik (Spektrum-Analyzer auf dem Music-Bus, nach dem Tiefpass → Dämpfung sichtbar).
  Der Dateiname steht als `DESKTOP_FILE_CAT` in der CSV → für ein store-taugliches Release dort tauschen.
- **Desktop-Programme:** Tap = Icon markieren, Doppel-Tap = Programm öffnen (Bildbetrachter mit haariger
  Katze, AOFF-Einwahl mit Fake-Tippen → „Leitung besetzt“, OCQ-Kontaktliste mit Chef-Verlauf des Runs,
  WhipAmp-Player im Dark-Skin, der den MusicManager WIRKLICH steuert: Prev/Play/Pause/Stop/Next, Spulen,
  Lautstärke (Music-Bus, nur für die Sitzung), echter Trackname/Zeit/Spektrum). Das Spiel läuft weiter; der erste Swipe/Pfeiltaste/ESC oder das X
  schließt das Fenster, erst danach wird wieder sortiert. Max. ein Programm gleichzeitig, Game Over
  schließt es. Eigenes Katzenbild: `cat_picture` am Node `World/AppWindows` in main.tscn.
- **Basisregel + Sonderregel:** Absendertyp bestimmt den Standardordner (Firma→Wichtig, Zeitung→Newsletter,
  ?→Spam, Schloss→Phishing, Legende unter den Ordnern). Die aktive Regel überschreibt das als Ausnahme.
- **Umstrukturierung:** Jedes 4. Regel-Event vertauscht die EDV zwei Ordner (Muscle-Memory-Rug-Pull).
- **Koffein-Boost:** Tasse füllt sich mit Streak → Boost verlangsamt Spawns. Jeder weitere Boost braucht
  +5 Treffer (sonst ist perfektes Spiel unendlich – per Bot-Simulation nachgewiesen).
- **Chef-Mail:** golden, gehört immer in WICHTIG → Challenge „5 Mails fehlerfrei“ → +1 Leben (max 5).
- **Sprache:** Basissprache Englisch, Deutsch via `localization/strings.csv`. Alle Texte über `tr()`-Keys.

## Meta-Progression (Rückgrat, erster Baustein Richtung Vollversion)
Bewusst als **Skelett** gebaut, nicht als voller Ären-Content: eine Währung, ein sequenzieller Shop
mit zwei reinen Deko-Items, um den Loop "Run → Budget-Punkte → Meta-Screen → Kauf → sichtbar auf
dem Tisch" zu beweisen. Bewusst noch NICHT gebaut: alles, was Spielbalance/Tempo berührt
(Auto-Filter-Slots), eine zweite Währung (Kaffeebohnen), Diegetisierung des Shops (eigenes
DullOS-Programm statt Overlay).
- **`autoload/meta_progress.gd`:** Budget-Punkte = `GameManager.score * SCORE_TO_BUDGET` (aktuell
  0,1, reiner Platzhalter-Umrechnungsfaktor – GDD Abschnitt 8 lässt den Faktor offen) bei jedem
  `GameManager.game_over`, unabhängig vom Run-Ausgang. Eigene Speicherdatei `user://progress.cfg`
  (nicht `save.cfg` von GameManager). `persist`-Flag wie `GameManager.persist_highscore`, vom Bot
  auf `false` gesetzt. `save_path` ist bewusst überschreibbar, damit Tests durch eine Scratch-Datei
  roundtripen können, ohne je die echte Datei anzufassen. `spend(amount)` ist der generische Zugriff,
  den andere Systeme (z. B. `EraManager`) für ihre eigenen Käufe aus demselben Budget nutzen.
- **`ITEMS`-Array:** sequenziell – nur `next_item()` ist kaufbar, entspricht "Schreibtisch als
  Fortschrittsbalken" (GDD Abschnitt 9). Neues Item = ein Eintrag in `ITEMS` + `SHOP_ITEM_*`-Key in
  der CSV + ein `_draw_xxx()`-Case in `desk.gd` (inkl. `_on_item_purchased`-Pop-in-Animation) +
  Koordinaten, die HUD-Widgets (Score/Leben links oben, Kaffeetasse unten links) und die Monitor-
  Bezel/AOFF-CD/Postit NICHT überschneiden. Freie Zonen: links x 0-168 (außer AOFF-CD-Bereich
  y 258-378 und Kaffeetassen-HUD y 530-660), rechts x 1112-1280 (außer Postit oben und der
  Kaffeering-Deko bei (1190,330)).
- **Meta-Screen:** kein eigenes System, sondern `Overlay.Mode.SHOP`/`Mode.ERA_SHOP` – zwei weitere
  Zustände im bestehenden Title-/Game-Over-Overlay, erscheinen NUR direkt nach Game Over (Tap auf
  die Statistiken → Deko-Shop → Tap → Ären-Shop → Tap startet den nächsten Run; Tap auf „Kaufen“
  kauft und bleibt im jeweiligen Shop). Bewusst schlicht/nicht-diegetisch, siehe "Bewusst NICHT" oben.

## Ären-System
Löst die harte Kopplung der DullOS-98-Optik an die generische Spiellogik (siehe "Projekt" oben) und
liefert die erste neue Ära. Zwei Ären sind aktuell gebaut: **90er** (Retrofit der bisherigen Optik,
unverändertes Gefühl, von Anfang an freigeschaltet) und **60er** (reine Papierpost, kein Monitor,
GDD Abschnitt 8 Punkt 1) – kaufbar im Ären-Shop, Kauf schaltet sofort um (kein Zurück-Umschalten
per UI, siehe `EraManager`-Kommentar). Bewusst noch NICHT gebaut: Telex/70er-80er, 2000er-Spam-
Explosion, KI-Ära, Auto-Filter-Slots, echte GDD-8b-Hybrid-Mechanik (Papier UND digital gleichzeitig
mit wanderndem Verhältnis – `paper_ratio` ist als Zahl zwischen 0.0/1.0 vorbereitet, aber nur die
Extremwerte sind belegt).
- **`autoload/era_manager.gd`:** `ERAS`-Array (wie `MetaProgress.ITEMS`) mit `has_monitor`,
  `paper_ratio`, `allowed_conditions` (Tag, aufgelöst über `get_allowed_conditions()`),
  `spawn_interval_scale`/`rule_change_scale` fürs 60er-Tempo. Eigene Speicherdatei `user://era.cfg`,
  gleiches `persist`/`save_path`-Muster wie `MetaProgress`. Neue Ära = Eintrag in `ERAS` + `ERA_*`-Key
  in der CSV + ggf. neue `MEDIUM_AGNOSTIC`-Einträge in `sort_rule.gd`, falls neue Regeln dazukommen.
- **Medium statt Ären-Fallunterscheidung überall:** `MailData.Medium` (DIGITAL/PAPER) wird pro Mail
  von `MailGenerator` aus `era.paper_ratio` gewürfelt – NICHT die Ära direkt. `main.gd` branch't beim
  Karten-Erzeugen auf `mail.medium`, nicht auf die Ära; eine künftige Misch-Ära (Papier + digital
  gleichzeitig, GDD 8b) braucht dadurch keine neue Logik an dieser Stelle.
- **Basisklassen-Split** (Vererbung, kein Duck-Typing): `MailPresenter` (Drag/Hit-Test/Fly-in) →
  `MailCard` (98-Chrome) / `PaperLetterCard` (Brief, Briefmarke/Wachssiegel, kein Pixel-Smiley-Icon –
  die sind laut "Zeitkolorit-Deko" oben ein 90er/2000er-Ding). `SortTarget` (Preview/Gulp/Shake) →
  `SortFolder` (Desktop-Icon) / `PaperTray` (Ablagekorb). `main.gd._rebuild_targets()` baut die 4
  Zielfächer **pro Run neu** (nicht nur in `_ready()`), weil die Ära zwischen Runs im Shop wechseln kann.
- **Regel-Filter:** `SortRule.MEDIUM_AGNOSTIC`/`medium_agnostic_conditions()` markiert Bedingungen,
  die ohne Monitor/E-Mail-Konzepte auskommen (bewusste Fail-safe-Liste: alles Ungelistete gilt als
  digital-only). `RulePool.create(allowed)` filtert damit; 6. Touch-Point neben den 5 im Kopf-
  kommentar von `sort_rule.gd`.
- **Monitor-Subsysteme:** `main.gd._apply_era_visuals()` blendet `Desktop`/`CRT`/`Bezel`/`Taskbar`/
  `AppWindows` für `has_monitor == false` aus (Desktop-Icons zusätzlich per `main.gd._on_tap()`
  entschärft, nicht nur unsichtbar). `InTrayMeter` (neu) ersetzt Taskbars Stapelanzeige als
  physisches Schild auf dem Tisch. `ScreenOverlay`/`SystemDialog`/`BossToast` bekommen intern
  `has_monitor`-Zweige (Papier-Absturz/Lampe-aus/Papier-Dialogkarte) statt eigener Subklassen, weil
  jeweils nur eine Instanz existiert. `scripts/world/desk.gd` zeichnet ohne Monitor Schreibmaschine
  + Wählscheibentelefon statt Monitorständer/Tastatur/AOFF-CD.

## Struktur
```
autoload/game_manager.gd   Autoload: State, Signals, ALLE Balancing-Konstanten oben in der Datei
autoload/meta_progress.gd  Autoload: Budget-Punkte + sequenzieller Deko-Shop, eigene Speicherdatei
autoload/era_manager.gd    Autoload: welche Ären unlocked/aktiv sind, Ären-Konfiguration (siehe oben)
autoload/music_manager.tscn  Autoload-SZENE: Playlist per Inspector (Tracks reinziehen), Music-Bus,
                           gedämpft (Low-Pass) auf Titel/Game Over, klar während eines Runs,
                           `get_spectrum(bands)` für Visualizer, Player-API (resume/pause/stop/
                           next/previous, seek, get_position/get_length, set_user_volume)
autoload/sound_manager.tscn  Autoload-SZENE: 8 Sound-Slots (SoundEvent) per Inspector, Voice-Pool auf Bus SFX,
                           hört selbst auf GameManager-Signale
scripts/audio/sound_event.gd  Resource pro Sound: Varianten-Array, Lautstärke, Pitch-Streuung,
                           Combo-Pitch, Mindestabstand
default_bus_layout.tres    Audio-Busse: Master, Music (Low-Pass + SpectrumAnalyzer), SFX
scripts/main.gd            Spawner, Warteschlange, Swipe-/Tasten-Input, Welt-Feedback, Ären-Umschaltung
scripts/mail_data.gd       Mail = Flags (caps, emojis, attachment…) → Text wird daraus gebaut, + Medium
scripts/sort_rule.gd       Regel-Resource: matches / make_match / make_near_miss pro Condition,
                           MEDIUM_AGNOSTIC-Liste fürs Regel-Filtern
scripts/rule_pool.gd       Regel-Pool (14 Regeln), optional nach Condition-Liste gefiltert
scripts/mail_generator.gd  Zufallsmails; 40 % passend zur aktiven Regel, 15 % Beinahe-Treffer,
                           würfelt Medium aus era.paper_ratio
scripts/pixel_icons.gd     12x12-Pixel-Icons als Zeichen-Grids (Smileys, Katze, Absender-Symbole…)
scripts/world/mail_presenter.gd  Basisklasse: Drag/Hit-Test/Fly-in-Physik, medium-unabhängig
scripts/world/mail_card.gd       98er-Mail-Fenster (extends MailPresenter)
scripts/world/paper_letter_card.gd  60er-Papierbrief (extends MailPresenter)
scripts/world/sort_target.gd     Basisklasse: Preview/Gulp/Shake-Animation, medium-unabhängig
scripts/world/sort_folder.gd     Desktop-Ordner-Icon (extends SortTarget)
scripts/world/paper_tray.gd      60er-Ablagekorb (extends SortTarget)
scripts/world/in_tray_meter.gd   60er-Ersatz für Taskbars Stapelanzeige, physisches Schild auf dem Tisch
scripts/world/app_icons.gd Vektor-Logos der Parodie-Apps (OCQ-Blume, WhipAmp-Blitz, AOFF-Dreieck)
scripts/world/app_windows.gd  Öffnet/schließt Desktop-Programme, Chef-Verlauf, Katzenbild-Slot
scripts/world/apps/        RetroWindow (Basis: Rahmen, Titel, Zoom-Animation, on_tap, überschreibbares
                           draw_window für eigene Skins) + ein Skript pro Programm
scripts/world/screen_layout.gd  ALLE Monitor-/Desktop-Maße + 98-Zeichenhelfer (raised/sunken/title bar)
scripts/world/             Monitor-Szene: Desktop, Mail-Fenster, Ordner, Fenster-Kaskade, Taskleiste,
                           Messenger-Toast, Dialogbox, Bluescreen/Power-Off, CRT, Gehäuse, Post-it, Tisch
                           (ScreenOverlay/SystemDialog/BossToast/desk.gd/InboxPile mit has_monitor-
                           bzw. medium-Zweig fürs 60er-Äquivalent statt eigener Subklasse)
shaders/crt.gdshader       CRT-Look (liest Screen-Texture; ColorRect über dem Bildschirmbereich).
                           Einstellungen (Helligkeit, Scanlines, Vignette …) als Inspector-Regler am
                           Node World/CRT (crt_effect.gd, @tool → live im Editor), NICHT im Material
scripts/ui/                HUD außerhalb des Monitors (Punkte, Leben, Tasse, Portrait) + Title/Game-Over/Shops
scripts/debug/autoplay.gd  Bot für Balancing, Screenshots und Regressionstests
localization/strings.csv   keys,en,de
```

## Konventionen
- Visuals programmatisch in `_draw()` (wie Pin a Million), Text über `DrawUtil`, Icons über `PixelIcons`
  (Node braucht `texture_filter = NEAREST`). Keine Unicode-Emojis im Bildschirm – passt nicht zur Ära.
- Z-Reihenfolge im Monitor (World-Kinder): Desktop -5 · Kaskade/Karten 0-2 · Ordner 5 · FX 10 ·
  Toast 18 · Taskleiste 20 · Dialog 25 · Bluescreen 30 · **CRT 40** · Gehäuse 45 · Post-it 50.
  Alles unter 40 bekommt den CRT-Look.
- Neue Regel = Enum-Eintrag in `SortRule.Condition` + je ein Case in `matches`/`make_match`/`make_near_miss`
  + `COND_*`-Key in der CSV + Eintrag in `RulePool`. Danach `--rule-test` laufen lassen.
- Neue Texte immer als Key in `strings.csv` (en + de), nie hartkodiert. Werte mit Komma in "…" setzen
  (z. B. englische Tausender „1,337“) – sonst verrutschen die Spalten.
- Nach CSV-Änderungen: Editor öffnen oder `godot --headless --import`.
- Audio: Musik über `MusicManager` (Bus "Music"), Effekte über `SoundManager` (Bus "SFX").
  Sound-Zuordnung: NEW_POPUP = Mail rückt nach vorne (`GameManager.mail_presented`), SORTED/MISTAKE,
  NEW_RULE (auch bei Ordner-Tausch), PILE_CRASH / NO_LIVES (Game Over; der tödliche Fehler spielt
  NUR NO_LIVES), COFFEE_BOOST, BONUS = Chef-Challenge geschafft, OCQ_MESSAGE = jede Chef-Nachricht im
  OCQ-Toast (Challenge erscheint / Chef antwortet; bei Erfolg 0,35 s nach BONUS), APP_OPEN = Desktop-
  Programm öffnet, AOFF_DIALUP = Modem-Einwahl (wird beim Schließen vor „besetzt“ abgewürgt).
  `SoundManager.play()` gibt die Stimme zurück, falls ein Sound vorzeitig gestoppt werden muss.
  Neuer Sound = Enum-Eintrag + @export SoundEvent + Case in `get_event` + Sub-Resource in der .tscn.

## Dev-Tools (Bot)
```bash
godot --path . -- --autoplay --think=0.6 --accuracy=0.92                    # Bot spielt sichtbar
godot --headless --path . -- --autoplay --runs=10 --think=0.6 --speed=4     # Balancing-Statistik
godot --path . -- --autoplay --shots=/pfad --shot-times=2,10,30             # Screenshots (+ Events)
godot --headless --path . -- --autoplay --swipe-test                        # Input-Regressionstest
godot --headless --path . -- --autoplay --rule-test                         # Regel-Logik-Test
godot --headless --path . -- --autoplay --music-test                        # MusicManager-Test (lautlos)
godot --headless --path . -- --autoplay --sound-test                        # SoundManager-Test (lautlos)
godot --path . -- --autoplay --app-test [--shots=/pfad]                     # Desktop-Programme per Tap/Swipe
godot --path . -- --autoplay --shop-test [--shots=/pfad]                    # MetaProgress + Shop-Screen, echte Taps
godot --path . -- --autoplay --era-test [--shots=/pfad]                     # EraManager: 60er + 90er-Retrofit
godot --path . -- --autoplay --card-gallery --shots=/pfad [--lang=en]       # Screenshots kniffliger Layouts
```
`--lang=en|de` setzt die Sprache nur für den Bot-Lauf (wird nicht gespeichert), `--crt=off` schaltet
den CRT-Shader für den Lauf ab (z. B. für Helligkeitsvergleiche per Screenshot), `--era=<id>` (z. B.
`sixties`) schaltet die Ära für den Lauf per Dev-Override frei/aktiv, ohne den Ären-Shop-Preis zu zahlen.
Achtung Godot 4: Ein pausierter AudioStreamPlayer meldet `playing == false` – Pause über `stream_paused` prüfen.
Bekannt & harmlos: Beim Beenden meldet Godot manchmal „AudioStreamMP3 still in use“ (laufende Musik,
Engine-Timing beim Shutdown).
Der Bot speichert keinen Highscore.

## Bewusst noch NICHT gebaut
Kopierer/Plotter, Aktenvernichter, Telex/70er-80er-Ära, 2000er-Spam-Explosions-Ära, KI-Ära,
Auto-Filter-Slots als Spielmechanik, echte GDD-8b-Hybrid-Mechanik (Papier+digital gleichzeitig mit
wanderndem Verhältnis), zweite Meta-Währung (Kaffeebohnen), Diegetisierung des Shops,
Monetarisierung, GDD-Abschnitt-14-Ideen. Der Budget-Punkte/Shop-Loop UND das Ären-System (90er-
Retrofit + 60er, s. o.) sind jetzt drin.

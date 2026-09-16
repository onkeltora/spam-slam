# Spam Slam – Claude Context File

> Hinweis: Die `CLAUDE.md` im übergeordneten Ordner `SPIELENTWICKLUNG/` gehört zu **Pin a Million**
> und wird mitgeladen. Für dieses Projekt gilt diese Datei + `spam-filter-simulator-GDD.md`.

## Projekt
Reaktions-Sortier-Arcade (Godot 4.7, GDScript, GL Compatibility, Landscape 1280×720, mobile-first).
Aktueller Stand: **MVP-Prototyp** laut GDD Abschnitt 12 – Kernloop zum Testen von Gefühl & Tempo.

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

## Struktur
```
autoload/game_manager.gd   Autoload: State, Signals, ALLE Balancing-Konstanten oben in der Datei
autoload/music_manager.tscn  Autoload-SZENE: Playlist per Inspector (Tracks reinziehen), Music-Bus,
                           gedämpft (Low-Pass) auf Titel/Game Over, klar während eines Runs,
                           `get_spectrum(bands)` für Visualizer, Player-API (resume/pause/stop/
                           next/previous, seek, get_position/get_length, set_user_volume)
autoload/sound_manager.tscn  Autoload-SZENE: 8 Sound-Slots (SoundEvent) per Inspector, Voice-Pool auf Bus SFX,
                           hört selbst auf GameManager-Signale
scripts/audio/sound_event.gd  Resource pro Sound: Varianten-Array, Lautstärke, Pitch-Streuung,
                           Combo-Pitch, Mindestabstand
default_bus_layout.tres    Audio-Busse: Master, Music (Low-Pass + SpectrumAnalyzer), SFX
scripts/main.gd            Spawner, Warteschlange, Swipe-/Tasten-Input, Welt-Feedback
scripts/mail_data.gd       Mail = Flags (caps, emojis, attachment…) → Text wird daraus gebaut
scripts/sort_rule.gd       Regel-Resource: matches / make_match / make_near_miss pro Condition
scripts/rule_pool.gd       Regel-Pool (14 Regeln)
scripts/mail_generator.gd  Zufallsmails; 40 % passend zur aktiven Regel, 15 % Beinahe-Treffer
scripts/pixel_icons.gd     12x12-Pixel-Icons als Zeichen-Grids (Smileys, Katze, Absender-Symbole…)
scripts/world/app_icons.gd Vektor-Logos der Parodie-Apps (OCQ-Blume, WhipAmp-Blitz, AOFF-Dreieck)
scripts/world/app_windows.gd  Öffnet/schließt Desktop-Programme, Chef-Verlauf, Katzenbild-Slot
scripts/world/apps/        RetroWindow (Basis: Rahmen, Titel, Zoom-Animation, on_tap, überschreibbares
                           draw_window für eigene Skins) + ein Skript pro Programm
scripts/world/screen_layout.gd  ALLE Monitor-/Desktop-Maße + 98-Zeichenhelfer (raised/sunken/title bar)
scripts/world/             Monitor-Szene: Desktop, Mail-Fenster, Ordner, Fenster-Kaskade, Taskleiste,
                           Messenger-Toast, Dialogbox, Bluescreen/Power-Off, CRT, Gehäuse, Post-it, Tisch
shaders/crt.gdshader       CRT-Look (liest Screen-Texture; ColorRect über dem Bildschirmbereich).
                           Einstellungen (Helligkeit, Scanlines, Vignette …) als Inspector-Regler am
                           Node World/CRT (crt_effect.gd, @tool → live im Editor), NICHT im Material
scripts/ui/                HUD außerhalb des Monitors (Punkte, Leben, Tasse, Portrait) + Title/Game-Over
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
godot --path . -- --autoplay --card-gallery --shots=/pfad [--lang=en]       # Screenshots kniffliger Layouts
```
`--lang=en|de` setzt die Sprache nur für den Bot-Lauf (wird nicht gespeichert), `--crt=off` schaltet
den CRT-Shader für den Lauf ab (z. B. für Helligkeitsvergleiche per Screenshot).
Achtung Godot 4: Ein pausierter AudioStreamPlayer meldet `playing == false` – Pause über `stream_paused` prüfen.
Bekannt & harmlos: Beim Beenden meldet Godot manchmal „AudioStreamMP3 still in use“ (laufende Musik,
Engine-Timing beim Shutdown).
Der Bot speichert keinen Highscore.

## Bewusst NICHT im Prototyp (GDD Abschnitt 12/14)
Kopierer/Plotter, Aktenvernichter, Ären/Automatisierung, Währungen/Shop, Monetarisierung, Backlog-Ideen.

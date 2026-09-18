# Spam Slam – Feature-Übersicht

> Reaktions-Sortier-Arcade · Godot 4.7 · GDScript · Landscape 1280×720 · Mobile-first

---

## Kernloop

- **Swipe-Sortierung** in vier Richtungen: Wichtig, Spam, Newsletter, Phishing
- **Aktive Mail** immer im Vordergrund; dahinter kaskadieren wartende Fenster
- **Zwei unabhängige Fail-Conditions:**
  - *Leben* (3 Stück) – falsche Sortierung kostet ein Leben
  - *Stapel-Überlauf* (`PILE_MAX = 12`) – zu viele unbearbeitete Mails → Fenster-Glitch → Bluescreen → sofortiges Game Over
- **Combo-Multiplikator** steigt mit Treffer-Streak, resettet bei Fehler
- **Tempo-Kurve** skaliert kontinuierlich mit Spielzeit und Score (Spawn-Rate + Bewegungsgeschwindigkeit)
- **Session-Länge:** 60–120 Sekunden pro Run

---

## Regel-System

- Pool aus **14 Regeln**, pro Run zufällig gezogen; Regelwechsel alle X Mails
- Regeln prüfen Merkmale wie Großschreibung, Emoji-Anzahl, Absender-Pattern, Anhangtyp u. a.
- **Basisregel:** Absendertyp → Standardordner (Firma → Wichtig, Zeitung → Newsletter, ? → Spam, Schloss → Phishing)
- **Sonderregel** überschreibt die Basisregel als laufende Ausnahme
- **Umstrukturierung:** jedes 4. Regel-Event tauscht zwei Ordner (Muscle-Memory-Rug-Pull)
- **Beinahe-Treffer (15 %):** Mails, die der Regel optisch ähneln, aber nicht entsprechen

---

## Mail-Generator

- **40 % Mails** passen zur aktiven Regel, **15 %** sind Beinahe-Treffer, Rest ist gemischter Pool
- Mails werden aus Flags generiert: CAPS, Emoji-Anzahl, Anhang, Absender-Typ, Betrag u. a.
- **Zeitkolorit ~1999–2004:** Pixel-Smileys, `.biz`-Domains, DM-Beträge, deutsche Firmen-/Betrüger-Mails im „Sie"
- Keine echten Marken oder Logos – bewusste Parodie-Ästhetik (DullOS 98, DullTron 17")

---

## Koffein-Boost

- Kaffeetasse füllt sich mit Treffer-Streak
- Volle Tasse → **Koffein-Boost:** verlangsamt Spawns vorübergehend
- Jeder weitere Boost erfordert **+5 zusätzliche Treffer** (verhindert unfendlichen Boost-Loop)

---

## Chef-Challenge

- **Golden schimmernde Mail** erscheint selten (~alle 20–30 Mails)
- Gehört immer in den Ordner *Wichtig*
- Löst **DullMessenger-Challenge** aus: „5 Mails fehlerfrei" → bei Erfolg **+1 Leben** (max. 5)
- OCQ-Blume blinkt im Tray während der Challenge; Chef antwortet im OCQ-Verlauf
- Kein Straf-Layer bei Nicht-Erfüllung (verpasste Chance)

---

## Setting & Ästhetik (DullOS 98)

- **Ego-Perspektive** auf einen CRT-Röhrenmonitor „DullTron 17""
- Fantasie-OS **DullOS 98** – Windows-98-Look, dezenter CRT-Shader (`shaders/crt.gdshader`)
- **Diegetisches UI:**
  - 4 Desktop-Ordner = Sortierziele
  - Post-it am Monitor = aktive Regel
  - Taskleisten-Button „Posteingang (n)" = Stapel-Indikator
  - DullOS-Dialogbox = Ansagen
  - DullMessenger-Toast = Chef-Challenge
- **Webcam-Portrait** des Charakters in einer Bildschirmecke (reagiert live auf Fehler, Combo, Bonus)
- **Punkte & Leben** im HUD außerhalb des Monitors

---

## Desktop-Programme (interaktiv, Spiel läuft weiter)

| Programm | Funktion |
|---|---|
| **Bildbetrachter** | `hairy_pussy.jpg` – ein Katzenbild (natürlich) |
| **AOFF – America Offline** | Fake-Modem-Einwahl → „Leitung besetzt" |
| **OCQ** | ICQ-Parodie; zeigt Chef-Verlauf des laufenden Runs |
| **WhipAmp** | Winamp-Parodie; steuert MusicManager wirklich (Play/Pause/Stop/Next/Prev, Spulen, Lautstärke, Trackname, Spektrum-Visualizer) |

- Tap = Icon markieren, Doppel-Tap = Programm öffnen
- Erster Swipe / Pfeiltaste / ESC oder X schließt das Fenster → danach wieder sortieren
- Max. ein Programm gleichzeitig; Game Over schließt es automatisch

---

## Audio-System

| Signal | Sound |
|---|---|
| Mail rückt nach vorne | `NEW_POPUP` |
| Richtig sortiert | `SORTED` |
| Falsch sortiert | `MISTAKE` |
| Regelwechsel / Ordner-Tausch | `NEW_RULE` |
| Stapel-Überlauf | `PILE_CRASH` |
| Letztes Leben verloren (Game Over) | `NO_LIVES` |
| Koffein-Boost | `COFFEE_BOOST` |
| Chef-Challenge geschafft | `BONUS` |
| Chef-Nachricht (OCQ-Toast) | `OCQ_MESSAGE` |
| Desktop-Programm öffnet | `APP_OPEN` |
| Modem-Einwahl (AOFF) | `AOFF_DIALUP` |

- **MusicManager:** Playlist per Inspector; Music-Bus mit Low-Pass-Dämpfung auf Titel/Game-Over-Screen; SpectrumAnalyzer für WhipAmp-Visualizer
- **SoundManager:** 8 Sound-Slots mit Varianten-Array, Pitch-Streuung, Combo-Pitch, Mindestabstand

---

## Technische Highlights

- Alle Visuals programmatisch in `_draw()` (keine externen Sprite-Sheets nötig)
- **12×12-Pixel-Icons** (`PixelIcons`): Smileys, Katze, Absender-Symbole
- **Vektor-App-Logos** (`AppIcons`): OCQ-Blume, WhipAmp-Blitz, AOFF-Dreieck
- **CRT-Shader** mit Inspector-Reglern (Helligkeit, Scanlines, Vignette) – live im Editor via `@tool`
- **Z-Order:** Desktop −5 → Karten 0–2 → Ordner 5 → FX 10 → Toast 18 → Taskleiste 20 → Dialog 25 → Bluescreen 30 → **CRT 40** → Gehäuse 45 → Post-it 50
- Volles **Lokalisierungs-System** (EN/DE) via `localization/strings.csv` + `tr()`-Keys
- **Debug-Bot** (`autoplay.gd`) für Balancing-Statistik, Screenshots, Input- und Regel-Regressionstests

---

## Dev-Tools (Bot)

```bash
godot --path . -- --autoplay --think=0.6 --accuracy=0.92          # sichtbarer Bot
godot --headless --path . -- --autoplay --runs=10 --speed=4        # Balancing-Statistik
godot --headless --path . -- --autoplay --rule-test                # Regel-Logik
godot --headless --path . -- --autoplay --sound-test               # SoundManager (lautlos)
godot --path . -- --autoplay --app-test                            # Desktop-Programme
godot --path . -- --autoplay --card-gallery --shots=/pfad          # Mail-Layout-Screenshots
```

---

## Noch nicht im Prototyp (GDD Abschnitt 12/14)

- Kopierer/Plotter-Mechanik (Anhang-Druck)
- Aktenvernichter (fünfte Sortieroption)
- Ären-System (60er → KI-Ära) & Automatisierungs-Slots
- Meta-Progression, Währungen, Shop
- Monetarisierung (Ads, IAP)
- Interrupt-Mechaniken (Telefon, Überwachungskamera)

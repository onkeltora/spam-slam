# Spam Slam – Claude Context File

> Hinweis: Die `CLAUDE.md` im übergeordneten Ordner `SPIELENTWICKLUNG/` gehört zu **Pin a Million**
> und wird mitgeladen. Für dieses Projekt gilt diese Datei + `spam-filter-simulator-GDD.md`.

## Projekt
Reaktions-Sortier-Arcade (Godot 4.7, GDScript, GL Compatibility, Landscape 1280×720, mobile-first).
Aktueller Stand: **MVP-Prototyp** laut GDD Abschnitt 12 – Kernloop zum Testen von Gefühl & Tempo.

## Festgelegte Design-Entscheidungen (Prototyp v1)
- **Ego-Perspektive + Warteschlange:** Immer nur die vorderste Mail ist aktiv; Swipe irgendwo = sortieren.
  Dahinter liegt der sichtbare Stapel. Stapel = alle unsortierten Mails; `PILE_MAX` (12) = Einsturz = Game Over.
- **Basisregel + Sonderregel:** Absendertyp bestimmt das Standardfach (🏢→Wichtig, 📰→Newsletter,
  ❓→Spam, 🔒→Phishing, Legende steht auf den Körben). Die aktive Regel überschreibt das als Ausnahme.
- **Umstrukturierung:** Jedes 4. Regel-Event tauscht die IT zwei Körbe (Muscle-Memory-Rug-Pull).
- **Koffein-Boost:** Tasse füllt sich mit Streak → Boost verlangsamt Spawns. Jeder weitere Boost braucht
  +5 Treffer (sonst ist perfektes Spiel unendlich – per Bot-Simulation nachgewiesen).
- **Chef-Mail:** golden, gehört immer in WICHTIG → Challenge „5 Mails fehlerfrei“ → +1 Leben (max 5).
- **Sprache:** Basissprache Englisch, Deutsch via `localization/strings.csv`. Alle Texte über `tr()`-Keys.

## Struktur
```
autoload/game_manager.gd   Autoload: State, Signals, ALLE Balancing-Konstanten oben in der Datei
scripts/main.gd            Spawner, Warteschlange, Swipe-/Tasten-Input, Welt-Feedback
scripts/mail_data.gd       Mail = Flags (caps, emojis, attachment…) → Text wird daraus gebaut
scripts/sort_rule.gd       Regel-Resource: matches / make_match / make_near_miss pro Condition
scripts/rule_pool.gd       Regel-Pool (14 Regeln)
scripts/mail_generator.gd  Zufallsmails; 40 % passend zur aktiven Regel, 15 % Beinahe-Treffer
scripts/world/             Mail-Karte, Körbe, Stapel, Schreibtisch, Floating Text (alles _draw())
scripts/ui/                HUD-Widgets (alle _draw()), Announcer, Title/Game-Over-Overlay
scripts/debug/autoplay.gd  Bot für Balancing, Screenshots und Regressionstests
localization/strings.csv   keys,en,de
```

## Konventionen
- Visuals programmatisch in `_draw()` (wie Pin a Million), Text über `DrawUtil`.
- Neue Regel = Enum-Eintrag in `SortRule.Condition` + je ein Case in `matches`/`make_match`/`make_near_miss`
  + `COND_*`-Key in der CSV + Eintrag in `RulePool`. Danach `--rule-test` laufen lassen.
- Neue Texte immer als Key in `strings.csv` (en + de), nie hartkodiert.
- Nach CSV-Änderungen: Editor öffnen oder `godot --headless --import`.

## Dev-Tools (Bot)
```bash
godot --path . -- --autoplay --think=0.6 --accuracy=0.92                    # Bot spielt sichtbar
godot --headless --path . -- --autoplay --runs=10 --think=0.6 --speed=4     # Balancing-Statistik
godot --path . -- --autoplay --shots=/pfad --shot-times=2,10,30             # Screenshots (+ Events)
godot --headless --path . -- --autoplay --swipe-test                        # Input-Regressionstest
godot --headless --path . -- --autoplay --rule-test                         # Regel-Logik-Test
```
Der Bot speichert keinen Highscore.

## Bewusst NICHT im Prototyp (GDD Abschnitt 12/14)
Kopierer/Plotter, Aktenvernichter, Ären/Automatisierung, Währungen/Shop, Monetarisierung, Backlog-Ideen.

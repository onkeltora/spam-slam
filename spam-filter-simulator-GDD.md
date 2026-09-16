# Spam Slam — Game Design Document (Prototyp v1)

**Spielname:** Spam Slam
**Hauptcharakter:** "Der Filter" (interner Arbeitsname, siehe Abschnitt 4)
**Genre:** Reaktions-Sortier-Arcade (mobile-first), 2D
**Engine:** Godot 4
**Referenzen:** Papers Please (Regelwechsel/Tempo), Fruit Ninja (Swipe-Feel), Scritchy Scratchy (Automatisierungs-/Prestige-Gefühl, aber anderes Kernloop-Genre)

---

## 1. Elevator Pitch

Du bist "Der Filter" — ein leicht genervter, koffeinabhängiger Büromensch, der im Sekundentakt E-Mails/Post in vier Fächer sortieren muss: **Wichtig, Spam, Newsletter, Phishing**. Die Regeln ändern sich ständig, das Tempo steigt kontinuierlich. Das Spiel spannt einen Zeitbogen von den 1960ern (alles per Hand) bis in die nahe Zukunft (KI übernimmt vollständig) — mit wachsender Automatisierung als zentraler Meta-Progression.

---

## 2. Core Loop (Moment-zu-Moment)

1. Ein Objekt (Brief/Mail, je nach Ära) fließt von rechts nach links über den Screen
2. Zeigt 1–2 sichtbare Merkmale (Betrag, Stempel, Symbol, Absender, Emoji-Anzahl etc.)
3. Spieler swiped es in Sekundenbruchteilen in eine von vier Richtungen (entspricht vier Ablagefächern auf dem Schreibtisch)
4. **Richtig** → Punkte + Combo-Multiplikator steigt, Kaffeetasse füllt sich
5. **Falsch** → Leben weg, Combo reset
6. Tempo steigt graduell; alle paar Objekte wechselt die aktive Regel (angezeigt am oberen Bildschirmrand)
7. Game Over bei 0 Leben ODER bei Stapel-Überlauf (siehe unten) → Score-Screen

**Session-Ziel:** 60–120 Sekunden pro Run.

**Stapel-Überlauf als zweite Fehlerart (ära-übergreifendes Prinzip):** Zusätzlich zum klassischen "falsch sortiert = Leben weg" gibt es eine zweite, unabhängige Fehlerquelle: Bleibt eine Mail zu lange unbearbeitet liegen, wächst ein sichtbarer Eingangsstapel. Wird der Stapel zu hoch, stürzt er ein → sofortiges Game Over, unabhängig vom Leben-Zähler. Das trennt "falsch entschieden" (Regelverstoß) von "zu langsam entschieden" (Rückstand) als zwei eigenständige Spannungsquellen. Ära-gerecht geskinnt: Papierstapel im Eingangskorb (60er–80er), rot blinkender Inbox-Zähler (90er–2010er), "System-Auslastung"-Anzeige (KI-Ära) — gleiches Grundprinzip, nur visuell angepasst.

---

## 3. Steuerung & Input

- **Swipe** (4 Richtungen) = Hauptmechanik, entspricht den 4 Ablagefächern
- **Tap** = Kopierer/Plotter bedienen (Anhang "drucken", bevor Mail sortierbar wird — kurze 1-Sekunden-Progress-Animation)
- **Fünfte Option (optional, später):** Aktenvernichter — freiwilliges Wegwerfen einer mehrdeutigen Mail, kostet Punkte/Combo, aber sicherer als raten. Manche Mails MÜSSEN geschreddert werden (Pflichtoption)

---

## 4. Charaktere & Schauplatz

**"Der Filter"** — muffiger, ungepflegter Typ in schmuddeligem, viel zu großem Hemd, Ärmel hochgekrempelt oder ständig rutschend. Krawatte schief bis halb offen, Kaffee-/Senffleck. Schütteres Haar, Dreitagebart, Augenringe ("seit drei Jahren nicht richtig geschlafen"). Optional Brille, die ständig verrutscht (liefert kostenlose Idle-Animation: hochschieben). Haltung eingesunken/hängende Schultern, richtet sich bei Combo-Streaks kurz auf. Reagiert visuell live auf Erfolg/Fehler (Augenrollen bei Fail, kurzes Grinsen bei Combo). Wenige Sprite-Frames reichen für viel Juice.

**Artstyle:** Pixel-Comic-Look — Pixel-Art-Basis (analog zur bestehenden Pillow-Pipeline: 4096px rendern, PIXEL_GRID-Downsampling, NEAREST-Upsampling) plus Comic-Overlays: dicke Outlines, übertriebene Ausdrücke, Speed-Lines, Symbol-Overlays (Schweißtropfen bei knappem Fail, Ausrufezeichen bei Chef-Bonus, "!"-Wölkchen bei Combo). Wichtig: Der Charakter darf detailreich/expressiv sein, die Mail-Objekte selbst müssen trotz Comic-Look sofort lesbar bleiben (Emoji-Anzahl, Absender-Pattern etc. sind das eigentliche Gameplay-UI).

**Ären-Look-Variation:** Der Charakter verändert sich optisch mit jeder Ära — in den 60ern adrett und stolz, mit jeder Automatisierungswelle zerrupfter/entmutigter, bis er in der KI-Ära fast resigniert nur noch danebensitzt. Farblich gedeckte, leicht vergilbte Bürotöne (Beige, Senfgelb, Grau), die sich gut von den bunten Mail-Icons abheben.

**Der Schreibtisch als UI:**
- 4 Ablagefächer/Körbe = die 4 Sortier-Kategorien, räumlich angeordnet (oben/unten/links/rechts)
- Kaffeetasse als Combo-Anzeige (füllt sich mit Streak, löst bei X Treffern kurzen "Koffein-Boost" aus: Zeitlupe oder Score-Multiplikator)
- Eingangskorb füllt sich mit unbearbeiteten Mails als sichtbare, spielrelevante Stapel-Überlauf-Anzeige (siehe Abschnitt 2) — kein reines Deko-Element, sondern zweite Fail-Condition neben dem Leben-System
- Kopierer/Plotter im Hintergrund (ratternde Animation, Sound) für die Anhang-Mechanik
- Aktenvernichter als fünftes Element, optisch klar abgesetzt (Warnfarbe)

---

## 4b. Kamera & Präsentation

**Perspektive:** Ego-Perspektive — die Kamera blickt aus den Augen von "Der Filter" auf die Schreibtischfläche. Mails spawnen mittig/leicht verkleinert und bewegen sich auf die Kamera zu (statt seitlich reinzufliegen), Hände/Unterarme können am unteren Bildrand sichtbar sein (greifen/stempeln/swipen).

**Fächer-Anordnung:** Vier Ablagekörbe klar sichtbar an den vier Bildschirmrändern (oben/unten/links/rechts) auf der Tischfläche platziert — korrespondiert direkt mit den vier Swipe-Richtungen, keine Umgewöhnung nötig.

**Portrait-Fenster (Charakter-Feedback):** Da das Gesicht in der Ego-Perspektive selbst nicht sichtbar ist, aber die Charakter-Reaktionen (Augenrollen, Schwitzen, Grinsen bei Combo) ein zentrales Feedback-Element sind, gibt es ein kleines, eigenständiges Portrait-Fenster (Gesicht/Oberkörper von "Der Filter"), fest in einer Bildschirmecke platziert — ähnlich einer Webcam-Ecke bei Streamern. Reagiert live auf Spielereignisse (Fehler, Combo, Chef-Bonus).

**Zusatznutzen des Portrait-Fensters:**
- Ort für den Ären-Look-Wandel des Charakters (adrett in den 60ern, zunehmend zerrupft/entmutigt bis zur KI-Ära) — sichtbar, ohne dass er im Spielraum selbst Platz braucht
- Chef-Bonus-Mails können mit einem eigenen kleinen Chef-Portrait-Popup daneben angekündigt werden, analog zum Charakter-Portrait

---

## 5. Regel-System

Ein zentraler Regel-Pool, aus dem pro Run/Phase Regeln gezogen werden. Regel wechselt alle X Objekte. Beispiele:

- "Alles in GROSSBUCHSTABEN = Spam"
- "Absender mit Zahlenkombo im Namen (xX_Deal420_Xx) = Phishing"
- "Betreff mit mehr als 2 Emojis = Spam"
- "Firmenlogo im Anhang = Wichtig, außer Absender endet auf .ru"
- "Newsletter mit 'Exklusiv' im Betreff = trotzdem Newsletter, nicht Wichtig" (bewusste Falle gegen Autopilot)
- Meta-Twist alle paar Level: "Ab jetzt gilt die vorherige Regel umgekehrt" (Rug-Pull-Moment)

**Für den Prototyp:** 15–20 Regeln reichen als Startpool, erweiterbar über eine simple Regel-Klasse/Resource.

---

## 6. Sub-Mechaniken

**Kopierer/Plotter:** Manche Mails haben Anhänge, die erst gedruckt werden müssen (Tap, kurze Animation), bevor die Mail vollständig lesbar/sortierbar ist. Bricht den reinen Swipe-Rhythmus auf, erzeugt Tempo-Spitzen ohne pauschal "alles schneller" zu machen.

**Aktenvernichter:** Manche Mails müssen zwingend geschreddert werden (fünfte Pflicht-Option). Optional als freiwillige "sichere" Ausweichoption bei Unsicherheit nutzbar (Risk/Reward).

---

## 7. Chef-Bonus-Mails (Variable-Reward-Layer)

- Golden schimmernde Mail mit Chef-Avatar erscheint selten (alle ~20–30 Mails)
- Zeigt Bonus-Bedingung mit Timer-Ring, z. B.:
  - "Bearbeite die nächsten 5 Mails fehlerfrei = Kurzurlaub-Bonus"
  - "Schaffe Combo x10 in 15 Sekunden = Kaffeebohnen-Bonus"
  - "Keine Fehler bis zum nächsten Regelwechsel = Bonuszahlung"
- Erfüllung → permanenter Run-Vorteil (Extra-Leben, Multiplikator, Zeitlupe) ODER Meta-Currency (Kaffeebohnen)
- Nicht-Erfüllung → keine Strafe, nur verpasste Chance (Bonus-Layer, kein Straf-Layer)

---

## 8. Ären-System & Automatisierung

Das Spiel durchläuft mehrere Ären, jede mit eigenem Artstyle und neuen mechanischen Elementen:

1. **1960er** — reine Papierpost, alles manuell, langsames Tempo (= narratives Tutorial)
2. **1970er/80er** — Telex/Karteikarten, Kopierer/Plotter-Mechanik wird eingeführt
3. **90er** — Computer/frühe E-Mail, Röhrenmonitor-Look, erster Auto-Filter-Slot wird freigeschaltet
4. **2000er/2010er** — Spam-Explosion, mehr Volumen, mehr Automatisierung im Hintergrund, Spieler bearbeitet zunehmend nur noch Grenzfälle
5. **Jetzt/nahe Zukunft** — KI-Panel übernimmt fast alles, Spieler bearbeitet nur noch eskalierte Sonderfälle, bis auch das automatisiert wird → Ending

**Automatisierungs-Mechanik:** Mit jedem Ären-Übergang wird ein Auto-Filter-Slot freigeschaltet, den der Spieler mit einer festen Regel belegt. Diese Kategorie sortiert sich fortan selbst; im Gegenzug steigt das Gesamtvolumen, sodass die Schwierigkeit konstant bleibt, sich aber qualitativ verschiebt (von "alles sortieren" zu "die Lücken finden").

**Ären-Progression (Ablauf):** Der Ären-Wechsel passiert **zwischen** Runs, nicht während eines Runs, über einen Meta-Screen/Shop:

1. **Run 1:** Spieler spielt in der 60er-Ära, erreicht 340 Punkte → wird 1:1 (oder mit Umrechnungsfaktor) in **Budget-Punkte** auf dem permanenten Meta-Konto gutgeschrieben
2. **Meta-Screen:** Zeigt nächstes freischaltbares Gerät, z. B. "Erster PC – Kosten: 1000 Budget-Punkte". Reicht das Guthaben noch nicht, spielt der Spieler weitere Runs
3. **Run 2–4:** Jeder Run bringt weitere Budget-Punkte (Guthaben sammelt sich kontoübergreifend, nicht run-gebunden)
4. **Kauf-Moment:** Sobald genug Budget-Punkte vorhanden sind, kauft der Spieler das Gerät bewusst im Meta-Screen (aktive Entscheidung, kein automatischer Trigger)
5. **Run 5 (erster Run nach dem Kauf):** Start weiterhin optisch in der bisherigen Ära, aber der PC steht jetzt zusätzlich auf dem Schreibtisch → ab hier gilt die Hybrid-Mechanik (Papier + digital, siehe Abschnitt 8b) und ein neuer Auto-Filter-Slot ist aktiv

Der Run selbst bleibt strukturell immer gleich (Swipe-Sortier-Loop); nur die Ausgangsbedingungen (aktuelle Ära, Anzahl aktiver Auto-Filter-Slots) ändern sich je nach Meta-Fortschritt. Ären-Wechsel sind linear und unumkehrbar (60er → 90er → 2000er/2010er → KI-Ära), **kein** Prestige-/Reset-Mechanismus wie bei Scritchy Scratchy — die Meta-Currency wird kontinuierlich investiert, nicht periodisch zurückgesetzt.

**Ending:** KI übernimmt vollständig — zwei mögliche Umsetzungen (bittersüß: Charakter geht in Rente / ironisch: KI patzt bei der letzten wichtigen Mail, kurzer Reaktivierungs-Epilog-Run). Danach optional Endless-Modus in der KI-Ära (Spieler supervised/trainiert die KI).

---

## 8b. Visuelle Evolution der Mail-Objekte

Die Mail-Objekte selbst durchlaufen denselben Ären-Bogen wie der Charakter — kein harter Schnitt, sondern ein organischer Übergang:

**Papier-Ära (60er–80er):** Briefe/Kuverts fliegen physisch rein, leicht schräg, mit Papier-Textur, Stempeln, evtl. Wachssiegel für "Wichtig". Handschrift/Schreibmaschinen-Font als Lesbarkeits-Merkmal. Flatternde, leicht schwerere Bewegung passend zum niedrigeren Grundtempo.

**Hybrid-Ära (90er, zentrale Übergangsmechanik):** Auf dem Schreibtisch steht jetzt ein Monitor, gleichzeitig flattern weiterhin Papierbriefe von der Seite rein. Zwei parallele Quellen/Zonen: Papierbriefe (physisch, wie gehabt) UND digitale Mails als Popup-Fenster auf dem Monitor (grüner Röhrenmonitor-Look, eckige Pixelschrift). Der Spieler muss beide Zonen im Blick behalten — organische Schwierigkeitssteigerung durch geteilte Aufmerksamkeit statt nur höherem Tempo. Das Verhältnis verschiebt sich graduell über die Ära (anfangs ~80% Papier/20% digital, dann 50/50, dann 20/80).

**Spam-Explosion (2000er/2010er):** Nur noch digitale Mails, aber visueller Lärm nimmt zu — buntere UI, mehr Icons (Anhang-Symbole, Absender-Avatare), leicht überladenes Fenster-Design als Ausdruck des Volumen-Anstiegs, ohne die Kern-Lesbarkeit zu gefährden.

**KI-Ära (jetzt/Zukunft):** Minimalistisches, cleanes Flat-Design, optional KI-Confidence-Score-Anzeige als visueller Gag (die der Spieler kaum noch braucht).

**Parallel-Erzählung Schreibtisch:** Mit fortschreitender Digitalisierung wird auch der physische Schreibtisch zunehmend leerer/steriler — von vollem Papier-Chaos bis zur fast leeren Tischfläche mit nur noch einem Monitor in der KI-Ära. Unterstützt den "Mensch wird überflüssig"-Unterton still im Hintergrund, ganz ohne Text.

**Marketing-Nutzen:** Die Mail-Evolution von Papier zu KI ist ein visuell selbsterklärender Trailer-/Store-Screenshot-Haken ("watch the mail evolve"), der organisch aus der Spielmechanik entsteht statt aufgesetzt zu wirken.

---

## 9. Meta-Progression & Währungen

- **Budget-Punkte** (Soft Currency, häufig, aus jedem Run) → Standard-Upgrades: Schreibtisch-Deko, Basis-Auto-Filter-Slots
- **Kaffeebohnen** (seltener, aus Chef-Boni) → Premium-Kosmetik, besondere Auto-Filter-Regeln, Kollegen-Skins
- **Firmenkreditkarte** (Premium/Echtgeld-Währung, komplett getrennt) → Cooldown-Skips, Extra-Leben-Pakete, exklusive Skins

**Fortschritts-Visualisierung:** Der Schreibtisch selbst ist der Fortschrittsbalken (schäbiges Büro → zweiter Monitor → Grünpflanze → Poster → Eckbüro). Kollegen-Skins als Charakter-Unlocks (Praktikant = einfacher Modus, gestresste Chefin, KI-Roboter-Kollege als Endgame-Unlock).

---

## 10. Monetarisierung (Mobile F2P)

- Rewarded Ads für "Weiterspielen nach Game Over" (Extra-Leben)
- Dezent getaktete Interstitials zwischen Runs
- Optionaler IAP für Werbefreiheit + Cosmetic-Startguthaben
- Tägliche "Inbox Zero Challenge" mit festem Mail-Set fürs Leaderboard (Retention-Hook)

---

## 12. Prototyp-Scope (MVP für v1)

**Drin:**
- Eine Ära (90er/E-Mail-Look, da visuell am einfachsten und thematisch am zugänglichsten)
- 4 Sortier-Fächer, Swipe-Mechanik
- Regel-Pool mit 10–15 Regeln, Regelwechsel alle X Objekte
- Tempo-Kurve (linear steigend, simpler Skalierungsfaktor)
- Leben-System (3 Leben), Combo-Multiplikator, Kaffeetassen-Anzeige
- Stapel-Überlauf als zweite Fail-Condition (unbearbeitete Mails stapeln sich, Überlauf = Game Over)
- Ein Chef-Bonus-Typ (z. B. "X Mails fehlerfrei")
- Score-Screen mit Highscore-Speicherung (lokal)

**Bewusst raus für v1 (spätere Iteration):**
- Kopierer/Plotter-Mechanik
- Aktenvernichter
- Ären-Wechsel/Automatisierungs-Slots
- Meta-Progression/Währungen/Shop
- Monetarisierung

---

## 13. Prompt für Claude Code (Prototyp-Setup)

```
Baue einen Godot 4 (GDScript) Prototyp für "Der Filter" (Spam-Filter-Simulator).

SCOPE: Nur der MVP-Kernloop aus Abschnitt 12 dieses GDD. Keine Ären, kein Meta-Progression-System,
keine Monetarisierung — reiner Arcade-Loop zum Testen von Gefühl und Tempo-Kurve.

Kernsystem:
- Ein Objekt-Spawner (Timer-basiert), der "Mail"-Objekte mit zufälligen Attributen generiert
  (Betreff-Merkmale wie GROSSBUCHSTABEN, Emoji-Anzahl, Absender-Pattern)
- Mails bewegen sich von rechts nach links über den Screen (einfache Node2D-Bewegung)
- Swipe-Erkennung über InputEventScreenTouch/InputEventScreenDrag (4 Richtungen),
  auf Desktop testbar per Maus-Drag als Fallback
- Eine Regel-Resource-Klasse mit aktiver Regel, aus einem Pool von 10-15 Regeln zufällig gezogen,
  wechselt alle 8-10 verarbeitete Mails
- GameManager-Autoload (Signal-basiert, wie im Pin-a-Million-Projekt) verwaltet:
  Score, Combo-Multiplikator, Leben (Start: 3), aktuelle Regel, Tempo-Skalierung, Stapelhöhe
- Tempo (Spawn-Rate + Bewegungsgeschwindigkeit) skaliert kontinuierlich mit Spielzeit/Score
- Stapel-Überlauf-Mechanik: Jede Mail hat einen internen Timer; bleibt sie zu lange unbearbeitet,
  erhöht sich eine globale Stapelhöhe-Variable (unabhängig vom Leben-System). Erreicht die
  Stapelhöhe einen kritischen Wert, sofortiges Game Over. Visuell reicht für den Prototyp ein
  simpler Balken/Stapel-Indikator, keine finale Grafik
- Einfaches Feedback: Screenshake + Partikel bei Treffer/Fehler, Combo-Anzeige als Kaffeetasse
  (Fortschrittsbalken reicht für den Prototyp, keine finale Grafik nötig)
- Game-Over bei 0 Leben ODER bei Stapel-Überlauf, Score-Screen mit lokal gespeichertem Highscore

Nicht bauen: Kopierer/Plotter, Aktenvernichter, Ären-System, Währungen/Shop, Ad-Integration.
Diese kommen erst nach Validierung des Kernloops in einer zweiten Iteration.

Platzhalter-Grafik reicht (einfache ColorRects/Placeholder-Sprites) — Fokus liegt auf Spielgefühl
und Tempo-Balancing, nicht auf finalem Artstyle.
```

---

*Stand: Ersterstellung als Brainstorm-Ergebnis, Grundlage für Prototyp-Entwicklung via Claude Code (analog zum bewährten Workflow bei Pin a Million: GDD/CLAUDE.md ins Projektverzeichnis legen, committen, Claude Code in VSCode greift automatisch darauf zu).*

---

## 14. Ideen-Backlog (Post-MVP, explizit NICHT für den ersten Prototyp)

Gesammelte Ideen, die Charme haben, aber bewusst zurückgestellt sind, um Scope Creep vor der MVP-Validierung zu vermeiden. Erst nach erfolgreichem Test des Kernloops erneut anschauen:

- **Ventilator/Klimaanlage** — Ambiente-Deko am Schreibtisch, ggf. kleine Idle-Animationen (Papier flattert stärker, Charakter fächelt sich Luft zu). Vermutlich unkritisch (reine Deko), aber trotzdem erst nach MVP
- **Nervige Ehefrau am Telefon** — potenzielle neue Interrupt-Mechanik (Anruf muss weggedrückt/kurz beantwortet werden, während weitergespielt wird). Echte neue Mechanik, nicht nur Flavor — braucht eigenes Balancing
- **Kameraüberwachung** — sichtbare Überwachungskamera, die den Charakter nervös macht (visuelles Feedback: Schwitzen, Zittern, evtl. leichte Fehleranfälligkeit bei aktiver Kamera). Könnte als Ära-spezifisches Stress-Element funktionieren, braucht aber eigene Balancing-Überlegungen

**Regel für diesen Abschnitt:** Nichts hiervon geht in den MVP-Scope (Abschnitt 12). Erst wenn der Kernloop nachweislich Spaß macht und der Suchtfaktor sich im Spieltest bestätigt, lohnt sich der Aufwand, einzelne dieser Ideen einzeln zu prüfen und zu bauen.

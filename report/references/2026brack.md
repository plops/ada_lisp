https://dl.acm.org/doi/epdf/10.1145/3779031.3779098

Hallo! Als Experte für formale Verifikation und Programmiersprachen freue ich mich sehr über dein Interesse. Die formale Verifikation von dynamischen Sprachen wie Lisp (insbesondere dem hier behandelten Dialekt **Scheme**) gilt in der Informatik als "Königsdisziplin", da diese Sprachen Features besitzen, die sich mathematisch nur schwer bändigen lassen.

Hier ist meine Zusammenfassung des vorliegenden Artikels **„BRacK: A Verified Compiler for Scheme via CakeML“** – verfasst so, dass die faszinierenden Konzepte auch ohne ein Informatikstudium greifbar werden.

---

### Worum geht es in dem Paper?
Das Paper stellt **BRacK** vor, einen neuen, mathematisch bewiesenen (formell verifizierten) Compiler für die Sprache Scheme (ein Lisp-Dialekt). Ein Compiler übersetzt menschenlesbaren Code in maschinenlesbaren Code. "Formell verifiziert" bedeutet: Die Forscher haben mit einem mathematischen Beweisprogramm (HOL4) unumstößlich bewiesen, dass der Compiler beim Übersetzen **niemals Fehler macht** oder das Verhalten des Programms verändert. 

### Wie verifiziert man Lisp/Scheme formell? (Die Methoden)

Die Autoren standen vor dem Problem, dass Scheme sehr mächtige, aber schwer zu beweisende Eigenschaften hat – vor allem dynamische Typisierung (Typen werden erst zur Laufzeit gecheckt) und extreme Kontrollfluss-Werkzeuge (dazu gleich mehr). Um das zu bewältigen, haben sie drei geniale Strategien angewandt:

#### 1. Huckepack-Strategie ("Backend Reuse")
Anstatt einen Compiler von Grund auf neu zu schreiben und den Weg von Lisp bis hinunter zum rohen Maschinencode aus Nullen und Einsen zu beweisen, nutzen sie einen Trick: Sie übersetzen Lisp in eine andere Sprache namens **ML** (genauer: in CakeML). CakeML ist ein bereits existierender, vollständig bewiesener Compiler. 
* *Beispiel:* Stell dir vor, du willst beweisen, dass eine Bauanleitung für ein Auto sicher ist. Anstatt das Rad neu zu erfinden, beweist du nur, wie man eine Lisp-Karosserie sicher auf ein bereits TÜV-geprüftes CakeML-Fahrgestell schraubt.

#### 2. Das Lisp-Regelwerk (Die Semantik)
Um überhaupt etwas beweisen zu können, braucht man ein Regelwerk, das exakt definiert, was ein Lisp-Programm Schritt für Schritt tun soll (die sogenannte "CESK-Maschine"). Die Forscher haben den Compiler nicht einfach "irgendwie" programmiert, sondern ihn durch rein mathematische Umformungen **direkt aus diesem Regelwerk abgeleitet**. Da der Compiler quasi das Regelwerk selbst ist, fällt der Beweis, dass er sich an die Regeln hält, extrem leicht.

#### 3. Der "Was-passiert-als-nächstes"-Trick (CPS-Transformation)
Das berüchtigtste Feature in Scheme/Lisp ist `call/cc` (Call-with-current-continuation). Es erlaubt dem Programmierer, den aktuellen Zustand des Programms abzuspeichern und später jederzeit genau dorthin zurückzuspringen.
* *Beispiel:* Das ist wie ein **"Save State" (Speicherstand) in einem Videospiel**. Wenn du vor einem Bossgegner speicherst, stirbst und neu lädst, bist du exakt wieder vor dem Boss – inklusive deiner genauen Lebenspunkte und Ausrüstung.
Für Compiler ist so etwas normalerweise ein Albtraum. Die Forscher lösen das, indem sie den gesamten Lisp-Code vor dem Übersetzen in den sogenannten **CPS (Continuation-Passing Style)** umschreiben. In diesem Stil wird das "Was als Nächstes passieren soll" (die *Continuation*) explizit wie ein Paket von Funktion zu Funktion weitergereicht. Ein "Save State" (`call/cc`) ist dann nichts anderes mehr, als dieses Paket zu kopieren und aufzuheben. Dadurch verliert dieses Lisp-Monster seinen Schrecken und lässt sich verifizieren.

#### 4. Der Beweis: Das "Simulations-Spiel"
Der eigentliche Beweis der Korrektheit funktioniert über eine Simulation. Die Forscher beweisen dem Computer: *„Egal welchen Zustand das Lisp-Programm gerade hat – wenn Lisp einen Schritt nach seinen Regeln macht, macht der von uns generierte CakeML-Code einen äquivalenten Schritt, und beide kommen exakt zum selben Ergebnis.“*

### Eine überraschende Erkenntnis der Forscher
Man sollte meinen, dass dieses Videospiel-Speicherstand-Feature (`call/cc`) am schwersten zu beweisen war. Die Autoren schreiben aber: Der Beweis dafür war dank der CPS-Transformation fast schon trivial!
Viel schlimmer und aufwendiger war paradoxerweise die **dynamische Typisierung** von Lisp (die Tatsache, dass eine Variable mal eine Zahl, mal Text, mal eine Liste sein kann). Warum? Weil sie in ihrem mathematischen Beweis für jeden einzelnen Rechenschritt alle möglichen Datentypen durchspielen und beweisen mussten, was passiert, wenn etwas schiefgeht (z.B. wenn man versucht, Text und Zahlen zu addieren).

---

### Fazit
Die Autoren zeigen, wie man selbst sehr komplexe, dynamische Sprachen wie Lisp formell absichern kann. Der Schlüssel liegt darin, komplexe Sprach-Features (wie Sprünge im Programmcode) durch mathematische Transformationen (CPS) zu entzaubern und auf den Schultern von bereits bewiesenen Systemen (CakeML) aufzubauen.

---

### 📖 Glossar (Verständliche Begriffserklärungen)

*   **Formale Verifikation:** Der Einsatz von Mathematik, um zu beweisen, dass Software fehlerfrei ist. Es ist kein Testen (wo man nur Stichproben macht), sondern ein lückenloser Beweis.
*   **Compiler:** Ein Übersetzungsprogramm. Es übersetzt den von Menschen geschriebenen Code (hier Scheme/Lisp) in Code, den die Maschine ausführen kann.
*   **Scheme / Lisp:** Eine sehr alte, aber extrem ausdrucksstarke Familie von Programmiersprachen. Bekannt für ihre vielen Klammern `(wie (hier))` und dafür, dass Code wie Daten behandelt werden kann.
*   **CakeML:** Ein bereits in der Vergangenheit formell bewiesener Compiler für eine andere Programmiersprache (ML). BRacK nutzt CakeML als Ziel-Plattform.
*   **Dynamische Typisierung:** Ein System, bei dem Datentypen (z.B. "Zahl" oder "Wort") erst geprüft werden, wenn das Programm läuft, nicht schon beim Schreiben des Codes. Typisch für Lisp, Python oder JavaScript.
*   **call/cc (Call-with-current-continuation):** Eine Lisp-Funktion, die den gesamten aktuellen Ausführungszustand ("Was muss das Programm noch alles tun?") einfriert und speicherbar macht. Vergleiche: Speichern/Laden-Knopf bei Emulatoren.
*   **CPS (Continuation-Passing Style):** Eine Art, Code zu schreiben, bei der Funktionen keine Werte mehr "zurückgeben". Stattdessen wird jeder Funktion eine Zusatz-Funktion (die *Continuation*) mitgegeben, die sagt: "Wenn du fertig bist, mach hiermit weiter".
*   **Theorembeweiser (hier: HOL4):** Ein Computerprogramm, das Mathematiker und Informatiker nutzen, um zu prüfen, ob ihre logischen Beweisketten fehlerfrei sind. Der Computer nimmt hier die Rolle eines unbestechlichen Korrektors ein.

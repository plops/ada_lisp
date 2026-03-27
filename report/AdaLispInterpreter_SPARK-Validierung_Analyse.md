# **Formale Validierung eines Ada-Lisp-Interpreters mittels SPARK: Beweisstrategien für rekursive Datenstrukturen**

## **1\. Einleitung: Der Paradigmenwechsel von Forth zu Lisp**

Die formale Programmverifikation zielt auf den rigorosen mathematischen Beweis der Fehlerfreiheit von Software ab. Während sich ein Forth-Interpreter aufgrund seiner flachen, iterativen Struktur und einfachen eindimensionalen Stacks exzellent für SMT-Solver (Satisfiability Modulo Theories) eignet, erfordert die Verifikation eines Lisp-Interpreters einen massiven methodischen Sprung.

Das vorliegende ada\_lisp-Projekt implementiert einen strikt limitierten Lisp-Kern (ohne Makros, GC oder dynamische Allokation), um SPARK-Beweisbarkeit zu ermöglichen. Im Gegensatz zu Forth bringt Lisp jedoch komplexe Eigenschaften mit sich:

* **Baumstrukturen:** Code und Daten bestehen aus verschachtelten Cons-Zellen (ASTs).  
* **Lexikalische Umgebungen:** Ausführungskontexte (Frames) müssen verkettet und erhalten werden (Closures).  
* **Gegenseitige Rekursion (Mutual Recursion):** Der Evaluator (Eval, Eval\_List, Eval\_Begin) ruft sich ständig selbst auf.

Diese Eigenschaften brechen die Standard-Beweisstrategien automatischer Solver. SMT-Solver sind historisch schwach darin, Induktion über rekursive Strukturen oder undurchsichtige Schleifen durchzuführen. Das Projekt befindet sich daher in einem Zustand fortgeschrittener, aber noch nicht vollständiger Verifikation. Es demonstriert, dass man bei Lisp nicht nur den *Code* verifizieren, sondern eine vollständige mathematische Modellierung (Refinement gegen ein Lisp.Model) vornehmen muss.

Dieser Bericht dokumentiert die neuen architektonischen Invarianten, die aufgetretenen "Proof Friction Points" (wie kombinatorische Explosionen) und die fortgeschrittenen SPARK-Taktiken, die notwendig sind, um einen Lisp-Kern formal abzudichten.

## **2\. Erweitertes Technisches Glossar: Lisp-spezifische SPARK-Konzepte**

Der Wechsel zu Lisp erfordert fortgeschrittene SPARK-Konstrukte, um dem Solver bei der Beweisfindung zu helfen.

### **Combinatorial Blowup (Kombinatorische Explosion)**

Ein Phänomen, bei dem der SMT-Solver unendlich lange rechnet (Timeout), weil er versucht, verschachtelte quantifizierte Ausdrücke aufzulösen. Wenn beispielsweise die Eindeutigkeit von Variablennamen im Environment durch (for all I... (for all J... Names(I) /= Names(J))) geprüft wird, überlastet dies den Solver. Die Lösung ist das Auslagern in eindimensionale Ghost-Funktionen.

### **Counterexample (Gegenbeispiel)**

Wenn der Solver wie alt-ergo eine Beweisverpflichtung nicht bestätigen kann, generiert er ein Gegenbeispiel, das die konkreten Variablenwerte zum Zeitpunkt des Scheiterns zeigt.1 Bei Lisp-Beweisen deuten Counterexamples oft nicht auf einen Laufzeitfehler hin, sondern auf eine fehlende Schleifeninvariante oder einen Informationsverlust des Solvers über den Zustand des Lisp-Heaps (Arena).

### **Flow Analysis (Datenflussanalyse)**

Die sehr schnelle, statische Analysephase in SPARK vor dem mathematischen Beweis.3 Sie stellt sicher, dass Variablen initialisiert sind und Verträge wie Global und Depends eingehalten werden. Bei den hochkomplexen in out Lisp.Runtime.State Übergaben im Lisp-Projekt garantiert die Flow-Analyse, dass keine versteckten Nebeneffekte (Aliasing) auftreten.

### **Ghost Code und Lemmas (Geistercode)**

In Lisp reicht es nicht, nur Verträge zu schreiben. Man muss dem Beweiser aktiv bei der Logik helfen. *Ghost Code* (Code, der vom Compiler restlos entfernt wird 4) wird hier massiv in Form von "Lemmas" eingesetzt. *Beispiel:* Prove\_Quote\_If\_Begin\_Known\_Distinct in lisp-runtime.adb. Diese Geisterprozedur führt zur Compile-Zeit einen mathematischen Hilfsbeweis durch, dass die reservierten IDs für quote, if und begin strukturell unterschiedlich sind.

### **Proof Obligation / Verification Condition (Beweisverpflichtung)**

Die mathematischen Formeln, die aus dem Ada-Code generiert und an Solver (via Why3) übergeben werden.6 Im Lisp-Projekt generiert allein der Parser hochkomplexe VCs, um zu beweisen, dass die Erzeugung verschachtelter Listen den Heap-Zustand (RT.Store) nicht korrumpiert.

### **Refinement (Verfeinerung gegen ein Modell)**

Die Königsdisziplin der formalen Methoden. Im Paket Proof.Refinement wird nicht nur bewiesen, dass der Lisp-Evaluator nicht abstürzt (Laufzeitsicherheit), sondern dass die *Ausführung* des ausführbaren Ada-Codes exakt den Ergebnissen des rein mathematischen, seiteneffektfreien Lisp.Model (Ghost Model) entspricht.

### **Subprogram\_Variant (Unterprogramm-Variante)**

SPARK verbietet Endlosrekursionen. Da Eval und Eval\_List sich gegenseitig aufrufen, *muss* dem Solver bewiesen werden, dass die Aufrufkette terminiert. Dies geschieht durch das Pragma Subprogram\_Variant \=\> (Decreases \=\> Fuel). Jede Rekursionsstufe muss mathematisch nachweisbar den Parameter Fuel reduzieren.

## ---

**3\. Design-Analyse: Architektur für beweisbare Baumstrukturen**

Die Übertragung von Lisp in ein SPARK-beweisbares Korsett zwingt den Entwickler zu fundamentalen Abweichungen von traditionellen Lisp-Architekturen.

### **3.1 Pointer-Freier Speicher: Die Arena (Lisp.Store)**

Klassisches Lisp nutzt Heap-Allokation (malloc / new) und Garbage Collection. Da dynamisches Speichermanagement (Access Types) in SPARK extrem schwer beweisbar ist, verwendet dieses Projekt ein fixes Array (Cell\_Array mit max. 4096 Zellen). Die "Pointer" sind lediglich Integer-Indizes (Cell\_Ref).

Das fundamentale Problem bei Listen-Indizes ist die Gefahr von Zyklen (Ringschlüssen), die rekursive Beweise zum Scheitern bringen. Die Architektur erzwingt daher eine geniale **topologische Invariante**:

* *Jede Zelle darf nur auf Referenzen zeigen, die strikt kleiner sind als ihre eigene ID (Left\_Value \< Ref).*

Dies verhindert mathematisch Zyklen. Wenn Eval einen Lisp-Baum traversiert, weiß der Solver automatisch, dass die Cell\_Ref-Werte strikt abnehmen (Decreases \=\> Expr). Dies erlaubt SPARK die Durchführung struktureller Induktionsbeweise. Ohne diese Invariante würde jeder Beweis von Eval sofort scheitern.

### **3.2 Lexikalische Umgebungen (Lisp.Env)**

Ähnlich wie der Speicher werden auch Scopes und Closures in einem fixen Array (Max\_Frames \= 512\) verwaltet. Auch hier gilt die strikte Invariante: Die Parent-ID eines Frames muss immer strikt kleiner sein als die eigene ID (Parent \< Frame).

### **3.3 Terminierungsgarantien durch "Fuel"**

Anstatt Lisp-Programme potenziell endlos laufen zu lassen (was das Halteproblem aufwirft und SPARK-Beweise blockiert), erhält die Eval-Prozedur expliziten Treibstoff (Fuel\_Count).

Jeder Abstieg in der AST-Auswertung, ob in Eval\_List oder bei einem Closure-Aufruf, reduziert den Fuel-Wert strikt (Fuel \- 1). Der SMT-Solver nutzt diesen Wert, um die totale Terminierung der Lisp-VM mathematisch abzusegnen.

## ---

**4\. Formale Validierung: Neue Probleme und Proof-Taktiken**

Die Lisp-Struktur bringt den alt-ergo SMT-Solver wiederholt an seine Timeout-Grenzen. Die Dokumentation des Projekts zeigt präzise, welche Taktiken entwickelt werden mussten, um den Beweiser zu "führen".

### **4.1 Das Problem opaker Schleifen und rekursiver Prädikate**

**Das Problem:** SMT-Solver sind hervorragend in Aussagenlogik, aber blind gegenüber Schleifen. Wenn eine Funktion den Lisp.Store durchsucht, vergisst der Solver nach jedem Schleifendurchlauf den Zustand des gesamten Arrays. Ebenso scheitern Solver katastrophal an rekursiven Gültigkeitsprüfungen (z.B. eine rekursive Valid-Funktion, die den Baum durchläuft).

**Die Taktik (Quantified Expressions):** Komplexe Gültigkeitsbedingungen (Lisp.Env.Valid) wurden komplett von prozeduralen Schleifen auf Ada 2012 Quantoren (for all...) umgeschrieben. Der SMT-Solver versteht Quantoren nativ. Anstatt zu schleifen, liefert der Entwickler dem Solver einen mathematischen Ausdruck: "Für alle Einträge I von 3 bis Next\_Free gilt die Invariante X".

### **4.2 Kombinatorische Explosion auflösen**

**Das Problem:** Um zu beweisen, dass Lisp-Variablen in einem Scope eindeutig sind, benötigt man verschachtelte Suchen:

(for all I... (for all J... Names(I) /= Names(J)))

Diese O(n²)-Quantifizierung führt im Solver zu einem Timeout, da er versucht, alle Kombinationen bei jeder Speicherveränderung neu zu instanziieren.

**Die Taktik:** Isolierung in Helper-Ghost-Funktionen. Durch die Kapselung der inneren Schleife in Binding\_Name\_Unique entfaltet der Solver die Logik nur dann, wenn er explizit den Beweis für genau diese Eindeutigkeit erbringen muss, was die Beweiszeiten drastisch senkt.

### **4.3 Fail-Fast und Stepping Stones (pragma Assert)**

**Das Problem:** Wenn ein komplexer Lisp-Postcondition-Vertrag (z.B. in Parse\_List) fehlschlägt, rechnet der Solver bis zum Timeout (Standard 1000 Schritte), ohne dem Entwickler zu verraten, *welcher* logische Zwischenschritt fehlte.

**Die Taktik:** Das Build-Skript prove.sh nutzt \--level=0 \--timeout=1. Der Beweiser muss sofort abbrechen. Der Entwickler streut dann im Code "Brotkrumen" aus – sogenannte *Stepping Stones* in Form von pragma Assert.

*Beispiel in Execute\_Word:*

pragma Assert (Lisp.Store.Cell\_Count (RT.Store) \>= Old\_Cell\_Count);

Bricht dieser Assert ab, weiß der Entwickler exakt, wo die Inferenzkette des Solvers gerissen ist, anstatt am Ende der Funktion im Dunkeln zu tappen.

### **4.4 Mutator-Verträge und State-Preservation**

Im Gegensatz zum simplen Forth-Stack iteriert der Lisp-Parser (Parse\_Expr) über Strings und modifiziert dabei parallel den Runtime-Heap (RT.Store). Der Solver nimmt bei jedem Unterprogrammaufruf pessimistisch an, dass *alles* zerstört wurde.

Daher müssen extreme Frame-Conditions in die Postconditions geschrieben werden:

Post \=\> Store\_Refs\_Preserved (RT.Store'Old, RT.Store)

Hiermit wird garantiert (und durch Ghost-Lemmas bewiesen), dass das Hinzufügen einer Lisp-Cons-Zelle (Make\_Cons) keine existierenden Elemente überschreibt.

## ---

**5\. Praktische Ergebnisse der Lisp-Verifikation**

Obwohl das Lisp-Projekt signifikant komplexer ist, dokumentiert der Status-Report (proof-status.md) enorme Erfolge:

* **Vollständig bewiesen:** Lisp.Config, Lisp.Types, Lisp.Arith (inklusive Abwesenheit von Integer-Overflows), Lisp.Text\_Buffers, Lisp.Store (Arena-Validität) und Lisp.Printer.  
* **Schlüsselelemente:** Das Herzstück, der Parser (Lisp.Parser), ist nun "clean". Dies ist ein massiver Erfolg, da er die Überführung von unstrukturierten Strings in gültige, topologisch sortierte Graphen beweist. Ebenfalls ist der Kern-Evaluator (Lisp.Eval) für Basisoperationen und quote/if/begin Formalismen bewiesen.  
* **Offene Verpflichtungen / Schwerpunkte:** Das ehrgeizige Ziel der "Refinement"-Verifikation (proof-refinement.adb), also der mathematische Beweis, dass der Lisp-Evaluator exakt einem abstrakten mathematischen Modell entspricht, ist für "pure" Subsets (ohne Zuweisungen und Seiteneffekte) bereits fokussiert bewiesen, erfordert aber noch eine vollständige End-to-End Abdeckung für Closures und Primitiv-Aufrufe.

**Der Wert für die Code-Qualität:**

Wie in den Architekturdokumenten erwähnt, wird Lisp erst durch diese harte Architektur formal beweisbar. Der Zwang, Verträge zu schreiben, deckte versteckte Komplexität im Lisp-Design auf (wie die Tatsache, dass Zyklen im AST eine Interpreter-Verifikation unmöglich machen). Die Beweise eliminieren völlig die Notwendigkeit von klassischen "Stack-Underflow" oder "Segfault"-Unit-Tests, die bei in C geschriebenen Lisp-Interpretern die Regel sind.

## ---

**6\. Fazit**

Der Versuch, einen Lisp-Interpreter in SPARK zu verifizieren, verdeutlicht die exponentielle Skalierung von Beweisaufwand bei dynamischen, graphbasierten Programmiersprachen. Während der Forth-Interpreter mit direkten Stack-Manipulationen gutmütig auf SMT-Beweise reagierte, erzwingt Lisp das Paradigma des **"Design for Verification"** in Reinform.

Der Verzicht auf echte Pointers, die Durchsetzung streng topologischer Graphen (Kinder-IDs \< Eltern-IDs), die Kapselung von Lexical Scopes in monoton wachsenden Arrays und die Begrenzung der totalen Berechnungszeit durch Evaluierungs-Treibstoff ("Fuel") sind keine reinen Design-Entscheidungen – sie sind mathematische Notwendigkeiten, um den Verifikationsbedingungen überhaupt Herr zu werden. Das ada\_lisp-Projekt ist somit weniger eine reine Lisp-Implementierung, sondern vielmehr eine meisterhafte Übung darin, wie man hochniveauvolle, funktionale Semantik auf einen beweisbaren, prädikatenlogischen Kern reduziert.

#### **Works cited**

1. Proving SPARK Verification Conditions with SMT Solvers \- Informatics Homepages Server, accessed March 27, 2026, [https://homepages.inf.ed.ac.uk/pbj/papers/vct-mar11-draft.pdf](https://homepages.inf.ed.ac.uk/pbj/papers/vct-mar11-draft.pdf)  
2. Instrumenting a Weakest Precondition Calculus for Counterexample Generation, accessed March 27, 2026, [https://www.researchgate.net/publication/325483828\_Instrumenting\_a\_Weakest\_Precondition\_Calculus\_for\_Counterexample\_Generation](https://www.researchgate.net/publication/325483828_Instrumenting_a_Weakest_Precondition_Calculus_for_Counterexample_Generation)  
3. Flow Analysis \- learn.adacore.com, accessed March 27, 2026, [https://learn.adacore.com/courses/intro-to-spark/chapters/02\_Flow\_Analysis.html](https://learn.adacore.com/courses/intro-to-spark/chapters/02_Flow_Analysis.html)  
4. Auto-Active Proof of Red-Black Trees in SPARK? \- AdaCore, accessed March 27, 2026, [https://www.adacore.com/uploads/blog/Auto-Active-Proof-of-Red-Black-Trees-in-SPARK.pdf](https://www.adacore.com/uploads/blog/Auto-Active-Proof-of-Red-Black-Trees-in-SPARK.pdf)  
5. SPARK 2014 Rationale: Ghost Code \- AdaCore, accessed March 27, 2026, [https://www.adacore.com/blog/spark-2014-rationale-ghost-code](https://www.adacore.com/blog/spark-2014-rationale-ghost-code)  
6. SPARK Proof Manual \- Documentation, accessed March 27, 2026, [https://docs.adacore.com/sparkdocs-docs/Proof\_Manual.htm](https://docs.adacore.com/sparkdocs-docs/Proof_Manual.htm)  
7. SPARK: An “Intensive Overview” \- SIGAda, accessed March 27, 2026, [http://www.sigada.org/conf/sigada2004/SIGAda2004-CDROM/SIGAda2004-Tutorials/SF2\_Chapman.pdf](http://www.sigada.org/conf/sigada2004/SIGAda2004-CDROM/SIGAda2004-Tutorials/SF2_Chapman.pdf)
Bad plan: “full Common Lisp, heap allocation, GC, REPL, then prove it later”. Good plan: a bounded core Lisp, one source expression per run, immutable array-backed cells, explicit frame tables, fuel for total evaluation, and a tiny non-SPARK I/O wrapper. As far as I can tell, there is >90% probability that a pointer-heavy first version turns into proof sludge: SPARK does support access types, but under a strict ownership policy, and AdaCore’s own documentation treats pointers as one of the places where full proof becomes infeasible or disproportionately costly. The features that actually help here are ordinary subprogram contracts, package/state contracts, ghost code, loop invariants, and subprogram variants. ([AdaCore Documentation][1])

Set the project up around a `.gpr` file, a `spark.adc` that defaults the project to `SPARK_Mode (On)`, and explicit `SPARK_Mode => Off` only on the non-SPARK wrappers. GNATprove is project-based; use `check_all`, `flow`, `prove`, and full `all` runs, use `-u` for touched units during development, and set a fixed `--steps` value for repeatable CI proofs. Project files are also where source directories and object/exec directories belong. ([AdaCore Documentation][2])

Since GNATprove assumes user contracts when analysing callers and proves them when analysing bodies, package boundaries need real pre/postconditions. Keep mutations in procedures, not functions, and write loop invariants that mention both progress and preservation of untouched array parts; predicates and ghost code are there to encode validity and helper facts. ([AdaCore Documentation][3])

The two invariants that make the whole thing tractable are simple.

1. Every cell only references smaller cell refs.
2. Every frame only references smaller frame ids.

Preserve those religiously. Everything else becomes much easier once those hold.

## Frozen v1 language

Do not build “Lisp”. Build this exact core.

```text
expr   ::= integer
         | nil
         | t
         | symbol
         | ' expr
         | ( )
         | ( expr+ )
         | ( expr+ . expr )
```

Semantics to freeze before coding:

* Data kinds: `nil`, `t`, integers, symbols, cons cells, primitive function values, closure values.
* `nil` and `t` are reserved constants, not ordinary bindable identifiers.
* Only `nil` is false. Everything else is true.
* `'x` is reader sugar for `(quote x)`.
* The printer is canonical. It does **not** emit quote shorthand. It prints `nil` instead of `()`.
* Dotted pairs are supported in the reader and printer. I do not care that this makes the parser slightly larger; without it, `cons` cannot print half its results sensibly.
* Special forms: `quote`, `if`, `begin`, `lambda`, `define`.
* `lambda` takes exactly two arguments: parameter list and one body expression. Multi-form bodies go through `(begin ...)`.
* `define` only supports `(define <symbol> <expr>)`, only at top level, and may not redefine reserved names.
* Application order is strict left-to-right: operator first, then arguments left-to-right.
* `car nil = nil` and `cdr nil = nil`.
* `atom` returns `t` for anything that is not a cons cell.
* `eq` returns `t` when refs are identical, or when two integers have the same numeric value, or when two symbols have the same symbol id; otherwise `nil`.
* One evaluation per fresh runtime. No REPL in v1. Use `(begin ...)` for multi-step programs.
* No macros, quasiquote, mutation of cons cells, strings, characters, vectors, floating point, variadics, GC, tail-call promises, or FFI.

## Directory structure

```text
.
├── lisp.gpr
├── spark.adc
├── README.md
├── docs/
│   ├── semantics.md
│   ├── invariants.md
│   └── proof-status.md
├── app/
│   └── lisp-main.adb
├── src/
│   ├── lisp-config.ads
│   ├── lisp-types.ads
│   ├── lisp-arith.ads
│   ├── lisp-arith.adb
│   ├── lisp-text_buffers.ads
│   ├── lisp-text_buffers.adb
│   ├── lisp-symbols.ads
│   ├── lisp-symbols.adb
│   ├── lisp-store.ads
│   ├── lisp-store.adb
│   ├── lisp-env.ads
│   ├── lisp-env.adb
│   ├── lisp-runtime.ads
│   ├── lisp-runtime.adb
│   ├── lisp-lexer.ads
│   ├── lisp-lexer.adb
│   ├── lisp-parser.ads
│   ├── lisp-parser.adb
│   ├── lisp-printer.ads
│   ├── lisp-printer.adb
│   ├── lisp-primitives.ads
│   ├── lisp-primitives.adb
│   ├── lisp-eval.ads
│   ├── lisp-eval.adb
│   ├── lisp-driver.ads
│   └── lisp-driver.adb
├── proofs/
│   ├── lisp-model.ads
│   ├── lisp-model.adb
│   └── proof-refinement.adb
├── tests/
│   ├── test-symbols.adb
│   ├── test-store.adb
│   ├── test-env.adb
│   ├── test-lexer.adb
│   ├── test-parser.adb
│   ├── test-printer.adb
│   ├── test-primitives.adb
│   ├── test-eval-core.adb
│   ├── test-eval-closure.adb
│   ├── test-eval-define.adb
│   └── test-end-to-end.adb
└── scripts/
    ├── build.sh
    ├── prove.sh
    └── test.sh
```

Required purpose of each file:

* `lisp.gpr`: source dirs, object dir, exec dir, config pragmas. Use `src`, `app`, `proofs`, `tests`.
* `spark.adc`: exactly `pragma SPARK_Mode (On);`
* `docs/semantics.md`: frozen syntax and evaluation rules above. No code generation starts until this file exists.
* `docs/invariants.md`: the two core invariants, plus package-local validity rules.
* `docs/proof-status.md`: one line per package listing intended proof status and current result.
* `app/lisp-main.adb`: non-SPARK wrapper only. File I/O, command-line parsing, printing, exit code mapping. No interpreter logic.
* `lisp-config.ads`: all numeric capacities and integer bounds.
* `lisp-types.ads`: enums, subtypes, fixed-size arrays, result/error records shared by all packages.
* `lisp-arith.*`: checked arithmetic helpers for `+`, `-`, `*`, comparisons.
* `lisp-text_buffers.*`: bounded append-only output buffer.
* `lisp-symbols.*`: fixed-capacity symbol table with interning.
* `lisp-store.*`: immutable cell arena plus ghost validity predicates and selectors/constructors.
* `lisp-env.*`: frame table for lexical environments plus top-level `define`.
* `lisp-runtime.*`: bundle of `Symbols`, `Store`, `Env`, and cached ids of reserved names; performs initial bootstrap.
* `lisp-lexer.*`: cursor-based tokenizer over source text.
* `lisp-parser.*`: reader from source text into store refs.
* `lisp-printer.*`: canonical printer from store refs into `Text_Buffer`.
* `lisp-primitives.*`: primitive dispatcher.
* `lisp-eval.*`: fuel-based evaluator.
* `lisp-driver.*`: SPARK end-to-end entry point `source -> parse -> eval -> print`.
* `proofs/lisp-model.*`: ghost reference semantics for the pure core subset.
* `proofs/proof-refinement.adb`: proof driver that the executable evaluator refines the model on the supported subset.
* `tests/*.adb`: tiny mains with `pragma Assert`-style tests; each file isolates one package or one integration layer.
* `scripts/*.sh`: dumb wrappers around build/prove/test commands. No cleverness.

Use this project skeleton for the build setup:

```gpr
project Lisp is
   for Source_Dirs use ("src", "app", "proofs", "tests");
   for Object_Dir  use "obj";
   for Exec_Dir    use "bin";

   package Compiler is
      for Local_Configuration_Pragmas use "spark.adc";
   end Compiler;
end Lisp;
```

## Rules for all agents

* Only touch the files listed in the current step.
* Do not introduce access types, allocators, Ada containers, tasking, exceptions for normal interpreter errors, or hidden global mutable state.
* All state mutation goes through procedures. Query operations may be functions.
* Use linear search everywhere in v1. I do not care about asymptotic elegance here.
* Every public package exposes a ghost `Valid` predicate on its state type.
* Every public procedure/function that consumes package state must have `Pre => Valid(...)`; every mutator must also guarantee `Post => Valid(...)`.
* Any recursive executable routine must decrease `Fuel` or a structural measure.
* Any loop over arrays or frames gets an explicit invariant, even if you think GNATprove might manage without it.
* Do not start downstream packages until upstream specs are frozen.
* If a public spec changes after another package depends on it, rerun the full proof gate.

## Standard proof gate

Use this after every step on the touched units, and use the full-project run before merging. `check_all` is for SPARK legality, `flow` is for initialisation/dataflow, `prove` checks run-time safety and contracts, `-u` narrows day-to-day analysis to changed units, and `--steps` makes proof runs repeatable. ([AdaCore Documentation][2])

```bash
gprbuild -P lisp.gpr

gnatprove -P lisp.gpr --mode=check_all -u <changed-files>
gnatprove -P lisp.gpr --mode=flow      -u <changed-files>
gnatprove -P lisp.gpr --mode=prove     --steps=1000 -u <changed-files>

# pre-merge / milestone gate
gnatprove -P lisp.gpr --mode=all --steps=1000
```

## Implementation plan

### 1. Freeze semantics and scaffold the project

Files:

* `lisp.gpr`
* `spark.adc`
* `README.md`
* `docs/semantics.md`
* `docs/invariants.md`
* `docs/proof-status.md`
* `scripts/build.sh`
* `scripts/prove.sh`
* `scripts/test.sh`

Task:

* Write the frozen v1 language definition exactly as above.
* Record the two core invariants explicitly.
* Record reserved names in this exact order: `quote`, `if`, `lambda`, `define`, `begin`, `atom`, `eq`, `cons`, `car`, `cdr`, `null`, `+`, `-`, `*`, `<`, `<=`.
* Create build and proof scripts with the standard gate.

Done when:

* The project builds as an empty skeleton.
* The docs exist and no later step has to guess semantics.

### 2. Define capacities, shared types, and error model

Files:

* `src/lisp-config.ads`
* `src/lisp-types.ads`

Task:

* Put all capacities in `Lisp.Config`:

  * `Max_Symbols`
  * `Max_Symbol_Length`
  * `Max_Cells`
  * `Max_Frames`
  * `Max_Frame_Bindings`
  * `Max_List_Elements`
  * `Max_Output_Length`
  * `Max_Fuel`
  * `Min_Int`
  * `Max_Int`
* Put all shared types in `Lisp.Types`:

  * `Lisp_Int`
  * `Cell_Ref`, `Frame_Id`, `Symbol_Id`, `Fuel_Count`
  * `Cell_Kind`
  * `Primitive_Kind`
  * `Error_Code`
  * fixed-size `Cell_Ref_Array`, `Symbol_Id_Array`
  * shared result record shape if needed
* Reserve `Cell_Ref = 0` as `No_Ref` and `Frame_Id = 0` as `No_Frame`.

Done when:

* No package below needs to invent a subtype or error code.
* Integer bounds are centralised and never duplicated.

### 3. Implement checked arithmetic and bounded text buffers

Files:

* `src/lisp-arith.ads`
* `src/lisp-arith.adb`
* `src/lisp-text_buffers.ads`
* `src/lisp-text_buffers.adb`

Task:

* `Lisp.Arith` provides total, checked helpers:

  * `Can_Add`, `Can_Sub`, `Can_Mul`
  * `Try_Add`, `Try_Sub`, `Try_Mul`
* These helpers return interpreter errors instead of relying on Ada exceptions.
* `Lisp.Text_Buffers` provides:

  * `type Buffer`
  * `Clear`
  * `Length`
  * `Remaining`
  * `Append_Char`
  * `Append_String`
* `Append_*` must preserve the existing prefix exactly.

Done when:

* Proof shows no overflow inside arithmetic helpers.
* Proof shows buffer append preserves earlier bytes and updates length correctly.
* `tests/test-printer.adb` can later rely on this package without touching internals.

### 4. Implement the symbol table

Files:

* `src/lisp-symbols.ads`
* `src/lisp-symbols.adb`
* `tests/test-symbols.adb`

Task:

* Use a fixed array of symbol slots.
* Each slot stores `Length` plus `Chars (1 .. Max_Symbol_Length)`.
* Public API:

  * `Initialize`
  * `Valid`
  * `Intern (Source, First, Last, Id, Error)`
  * `Lookup_Image (Id, Dest_Buffer, Error)` or equivalent
  * `Equal_Slice`
  * `Is_Reserved` is **not** here; that belongs in `Runtime`.
* Interning rule: same textual symbol always yields same `Symbol_Id`.
* Search rule: linear search over used prefix.
* Proof obligations:

  * used slots are unique by content
  * `Count` never decreases
  * interning an existing symbol does not modify the table
  * interning a new symbol only appends one slot

Representative tests:

* `foo` interned twice yields same id
* table-full error
* symbol-too-long error

### 5. Implement the immutable cell arena

Files:

* `src/lisp-store.ads`
* `src/lisp-store.adb`
* `tests/test-store.adb`

Task:

* Define the cell type with exactly these variants:

  * `Nil_Cell`
  * `True_Cell`
  * `Integer_Cell`
  * `Symbol_Cell`
  * `Cons_Cell`
  * `Primitive_Cell`
  * `Closure_Cell`
* Closure payload is `Params`, `Body`, `Captured_Frame`.
* Initialise the arena so:

  * ref `1` is `nil`
  * ref `2` is `t`
  * `Next_Free = 3`
* Public API:

  * `Initialize`
  * `Valid`
  * `Is_Valid_Ref`
  * `Kind_Of`
  * selectors for each kind
  * constructors `Make_Integer`, `Make_Symbol`, `Make_Cons`, `Make_Primitive`, `Make_Closure`
  * ghost predicates `Readable_Value`, `Proper_List`, `List_Length`
* The key invariant is mandatory:

  * every child ref stored in a used cell is either `No_Ref` or strictly smaller than the cell’s own ref

This is the package where most later proof pain is avoided. Get it right now.

Done when:

* All constructors preserve `Valid`.
* Old used cells are unchanged after appending a new cell.
* Recursive ghost functions over cells can decrease on the ref number.

### 6. Implement lexical environments

Files:

* `src/lisp-env.ads`
* `src/lisp-env.adb`
* `tests/test-env.adb`

Task:

* Use a fixed array of frames.
* Frame `1` is the global frame.
* Each frame stores:

  * `Parent : Frame_Id`
  * `Count : Natural`
  * fixed binding arrays of names and values
* No separate heap/list for bindings.
* Public API:

  * `Initialize`
  * `Valid`
  * `Lookup`
  * `Define_Global`
  * `Push_Frame`
  * `Frame_Count`
* Required invariants:

  * frame `1` exists and is global
  * for every frame `F > 1`, `Parent(F) < F`
  * used bindings in one frame have unique names
* `Define_Global` updates an existing binding if present; otherwise appends.

Representative tests:

* local frame shadows parent
* global define replaces value on duplicate name
* pushing a frame with duplicate parameters fails

### 7. Implement runtime bootstrap

Files:

* `src/lisp-runtime.ads`
* `src/lisp-runtime.adb`

Task:

* Define `Runtime.State` as a bundle of:

  * `Symbols : Lisp.Symbols.Table`
  * `Store   : Lisp.Store.Arena`
  * `Env     : Lisp.Env.State`
  * `Known   : Well_Known_Symbols`
* `Well_Known_Symbols` caches the ids of all reserved names in the exact frozen order.
* `Initialize` must:

  1. initialise symbols/store/env
  2. intern all reserved names in the frozen order
  3. allocate primitive cells in the store
  4. bind primitive names in the global frame
* Expose `Valid (RT)`.

Important restriction:

* reserved names may exist as symbol values in data, but `define` and `lambda` parameter lists may not bind them.

Done when:

* After `Initialize`, global lookups of primitive names succeed.
* Runtime validity implies sub-validity of symbols/store/env.

### 8. Implement the lexer

Files:

* `src/lisp-lexer.ads`
* `src/lisp-lexer.adb`
* `tests/test-lexer.adb`

Task:

* Token kinds:

  * `Tok_LParen`
  * `Tok_RParen`
  * `Tok_Dot`
  * `Tok_Quote`
  * `Tok_Integer`
  * `Tok_Nil`
  * `Tok_True`
  * `Tok_Symbol`
  * `Tok_EOF`
  * `Tok_Bad`
* Lexing rules:

  * `nil` and `t` are special tokens
  * `-123` is an integer
  * `-` by itself is a symbol
  * `.` is `Tok_Dot` only when standalone; otherwise part of a symbol token if you choose to allow that, but keep the rule explicit and tested
  * no comments in v1
* Public API:

  * `Next_Token (Source, Pos, Token, Next_Pos)`
* Contracts:

  * `Next_Pos >= Pos`
  * if not EOF and not bad token, progress is strict
  * integer token values are already range-checked

Representative tests:

* `()`
* `(a . b)`
* `'x`
* `-123` vs `-`
* malformed dot positions

### 9. Implement the parser / reader

Files:

* `src/lisp-parser.ads`
* `src/lisp-parser.adb`
* `tests/test-parser.adb`

Task:

* Public API:

  * `Parse_One (Source, Pos, RT, Ref, Next_Pos, Error)`
* Parser must read exactly one expression.
* Quote sugar expansion:

  * `'x` becomes `(quote x)` using the cached `quote` symbol id from `RT.Known`
* List construction algorithm:

  * parse element refs into a temporary fixed array
  * determine whether the list is proper or dotted
  * allocate cons cells from right to left
* That reverse build is mandatory, because it preserves the “children point backward” invariant.
* `()` parses directly to the `nil` ref.
* Concrete dotted notation is supported for data, but evaluator later rejects dotted parameter lists and dotted application argument lists where proper lists are required.

Representative tests:

* `()`
* `(a b c)`
* `(a . b)`
* `(a b . c)`
* `'x`
* `'(a b)`
* malformed: `(`, `)`, `(a . b c)`, `(. a)`

Done when:

* On success, the returned ref is valid and readable.
* On failure, runtime state remains valid.

### 10. Implement the canonical printer

Files:

* `src/lisp-printer.ads`
* `src/lisp-printer.adb`
* `tests/test-printer.adb`

Task:

* Public API:

  * `Print (RT, Ref, Buffer, Error)`
* Printing rules:

  * `nil` prints as `nil`
  * `t` prints as `t`
  * integers as decimal
  * symbols by their stored image
  * proper lists as `(a b c)`
  * improper lists as `(a b . c)`
  * closures as `#<closure>`
  * primitives as `#<primitive>`
* The printer is canonical:

  * no quote shorthand
  * no attempt to preserve user input formatting
* Round-trip target:

  * for `Readable_Value`, `parse(print(v)) = v`
  * this does **not** apply to closures or primitives

Representative tests:

* parser/printer round-trip on atoms, proper lists, dotted pairs
* buffer-full error
* canonicalisation of `()` to `nil`

### 11. Implement primitive application

Files:

* `src/lisp-primitives.ads`
* `src/lisp-primitives.adb`
* `tests/test-primitives.adb`

Task:

* Public API:

  * `Apply (RT, Prim, Args, Arg_Count, Result_Ref, Error)`
* Implement exactly:

  * `atom`
  * `eq`
  * `cons`
  * `car`
  * `cdr`
  * `null`
  * `+`
  * `-`
  * `*`
  * `<`
  * `<=`
* Arity is fixed:

  * unary for `atom`, `car`, `cdr`, `null`
  * binary for everything else
* Semantics:

  * `car nil = nil`
  * `cdr nil = nil`
  * `cons` allocates one new cons
  * arithmetic allocates one integer cell
  * comparison returns `t` or `nil`
* Use explicit case splits and contracts. This is a good place for `Contract_Cases`.

Representative tests:

* `atom nil = t`
* `atom (cons 1 nil) = nil`
* `eq 1 1 = t`
* `eq (cons 1 nil) (cons 1 nil) = nil`
* `car nil = nil`
* `cdr nil = nil`
* overflow on `*`

### 12. Implement evaluator core: atoms, symbols, `quote`, `if`, `begin`, primitive calls

Files:

* `src/lisp-eval.ads`
* `src/lisp-eval.adb`
* `tests/test-eval-core.adb`

Task:

* Public API:

  * `Eval (RT, Current_Frame, Expr, Fuel, Result_Ref, Error)`
* Fuel rules:

  * if `Fuel = 0`, return `Out_Of_Fuel`
  * every recursive evaluation call uses strictly smaller fuel
  * application consumes fuel too
* Core evaluation:

  * integers, `nil`, `t` self-evaluate
  * symbols look up in `Current_Frame`
  * `(quote x)` returns `x` unchanged
  * `(if c t e)` evaluates only one branch
  * `(begin ...)` evaluates forms left-to-right and returns the last, or `nil` if empty
  * general application evaluates operator, then arguments left-to-right, then dispatches if operator is a primitive
* At this step, closures are not implemented yet. Applying a non-primitive is `Not_Callable`.

Representative tests:

* `42`
* `nil`
* `(+ 1 2)`
* `(if nil 1 2)`
* `(begin 1 2 3)`

### 13. Extend evaluator with `lambda` and closure application

Files:

* `src/lisp-eval.ads`
* `src/lisp-eval.adb`
* `tests/test-eval-closure.adb`

Task:

* Add special form `lambda`.
* `lambda` rules:

  * parameter list must be a proper list of distinct, non-reserved symbols
  * body is exactly one expression
  * return a closure cell capturing `Current_Frame`
* Application rules for closures:

  * evaluate operator
  * evaluate args left-to-right into a fixed array
  * check arity against parameter count
  * push a new frame whose parent is the closure’s captured frame
  * bind parameters to evaluated args
  * evaluate body in the new frame
* Required helper:

  * a procedure to convert parameter-list refs into a fixed symbol id array, rejecting dotted or duplicate parameter lists

Representative tests:

* `((lambda (x) x) 7) -> 7`
* `((lambda (x) ((lambda (y) x) 0)) 9) -> 9`
* duplicate parameter rejection
* reserved parameter name rejection

### 14. Extend evaluator with top-level `define`; implement the SPARK driver and non-SPARK main

Files:

* `src/lisp-eval.ads`
* `src/lisp-eval.adb`
* `src/lisp-driver.ads`
* `src/lisp-driver.adb`
* `app/lisp-main.adb`
* `tests/test-eval-define.adb`
* `tests/test-end-to-end.adb`

Task:

* Add special form `define`.
* Rules:

  * only `(define <symbol> <expr>)`
  * only valid when `Current_Frame` is the global frame
  * name may not be reserved
  * evaluate RHS first, then update the global frame
  * return the symbol cell for the defined name
* `Lisp.Driver` must do:

  1. `Runtime.Initialize`
  2. `Parser.Parse_One`
  3. require end-of-input
  4. `Eval`
  5. `Printer.Print`
* `app/lisp-main.adb` is `SPARK_Mode => Off` and does only I/O. That split is exactly what `SPARK_Mode` is for when most of the system is in SPARK and a small wrapper is not. ([AdaCore Documentation][4])

Representative end-to-end tests:

* `(begin (define id (lambda (x) x)) (id 7)) -> 7`
* `(begin (define fact (lambda (n) (if (<= n 1) 1 (* n (fact (- n 1)))))) (fact 5)) -> 120`
* local `define` rejection
* reserved-name define rejection
* out-of-fuel on intentionally recursive input

I do not care about a REPL in v1. One input, one result, exit.

### 15. Harden proofs and regression tests

Files:

* `docs/proof-status.md`
* all `tests/*.adb`
* `scripts/prove.sh`
* `scripts/test.sh`

Task:

* Add negative tests for:

  * syntax errors
  * unbound symbol
  * arity error
  * type error
  * reserved-name error
  * out-of-fuel
  * arena-full / frame-full / symbol-table-full / buffer-full
* Update `proof-status.md` with one line per package:

  * intended proof target
  * current status
  * any remaining unproved checks
* Target at this step: zero unproved checks in all core SPARK packages.

Done when:

* full `gnatprove -P lisp.gpr --mode=all --steps=1000` is clean
* every test executable passes

### 16. Add a ghost reference model and prove refinement of the executable evaluator

Files:

* `proofs/lisp-model.ads`
* `proofs/lisp-model.adb`
* `proofs/proof-refinement.adb`

Task:

* Define a ghost model evaluator for the pure, closed core subset.
* Start with the subset that excludes:

  * `define`
  * resource exhaustion
  * out-of-fuel
  * printer opacity as an observable result
* The model may still include closures internally, but the theorem can restrict final results to readable values.
* State and prove the refinement theorem:

  * if parsing succeeds,
  * fuel is sufficient,
  * no capacity is exhausted,
  * the program is closed in the given environment,
  * then executable `Eval` returns the same logical result as `Model_Eval`
* Do not start this step until step 15 is completely proof-clean.

This is the step that turns “high-assurance implementation” into an actual semantic verification story.

## Final acceptance criteria

The implementation is done only when all of this is true:

* the code stays within the frozen v1 scope
* all core units are in SPARK
* `app/lisp-main.adb` is the only intentional non-SPARK wrapper
* full-project build is clean
* full-project proof gate is clean
* all package-level contracts are proved
* parser/printer round-trip tests pass for readable values
* evaluator tests pass for primitives, closures, top-level define, recursion, and error cases
* refinement proof for the pure core subset passes

As far as I can tell, this is the sane plan. The crucial choice is not Ada versus Lisp; it is whether you force the implementation into a proof-friendly shape from day one. Arrays, indices, fixed bounds, fuel, and frozen semantics do that. Pointers, GC, feature creep, and “we’ll prove it later” do not.

[1]: https://docs.adacore.com/spark2014-docs/html/ug/en/source/access.html "https://docs.adacore.com/spark2014-docs/html/ug/en/source/access.html"
[2]: https://docs.adacore.com/spark2014-docs/html/ug/en/source/how_to_run_gnatprove.html "https://docs.adacore.com/spark2014-docs/html/ug/en/source/how_to_run_gnatprove.html"
[3]: https://docs.adacore.com/R/docs/gnat-25.1/spark2014/html/spark2014_ug/en/source/how_to_write_subprogram_contracts.html "https://docs.adacore.com/R/docs/gnat-25.1/spark2014/html/spark2014_ug/en/source/how_to_write_subprogram_contracts.html"
[4]: https://docs.adacore.com/spark2014-docs/html/ug/en/spark_mode.html "4. Identifying SPARK Code — SPARK User's Guide 27.0w"

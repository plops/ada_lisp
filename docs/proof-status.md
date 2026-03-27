# Proof Status

- `Lisp.Config`: intended full SPARK proof, current status core proof project clean
- `Lisp.Types`: intended full SPARK proof, current status core proof project clean
- `Lisp.Arith`: intended overflow and contract proof, current status core proof project clean
- `Lisp.Text_Buffers`: intended state and append proof, current status core proof project clean
- `Lisp.Symbols`: intended table validity proof, current status core proof project clean after slice-bound contract cleanup
- `Lisp.Store`: intended arena validity proof, current status core proof project clean after readability helper cleanup
- `Lisp.Env`: intended frame validity proof, current status core proof project clean after restoring solver-friendly frame-preservation lemmas and closing the remaining bounded gate obligations
- `Lisp.Runtime`: intended bootstrap validity proof, current status core proof project clean, and now also carries prover-friendly helpers for structurally well-formed `quote` and `if` forms plus immediate-result accessors for literal-or-quoted expressions; the `if` child accessors now expose exact structural projections and `child < parent` facts for downstream recursive proofs, `Immediate_Result` now exposes the literal-vs-quote result split directly in its postcondition, and the runtime surface now also includes shared `if`-immediate-form/result helpers for the next refinement slice
- `Lisp.Lexer`: intended token progress proof, current status core proof project clean after position/bounds invariants
- `Lisp.Parser`: intended runtime preservation proof, current status core proof project clean
- `Lisp.Printer`: intended canonical output proof, current status core proof project clean
- `Lisp.Primitives`: intended contract and safety proof, current status core proof project clean
- `Lisp.Eval`: intended fuel and contract proof, current status core proof project clean, including bounded postconditions for positive-fuel literal atoms and structurally well-formed `quote` forms
- `Lisp.Driver`: intended end-to-end SPARK proof, current status core proof project clean
- `Lisp.Model`: intended ghost reference semantics for a closed pure fragment, current status focused `GNATPROVE_LEVEL=0 GNATPROVE_TIMEOUT=1 ./scripts/prove-adacore.sh -u lisp-model.adb` clean on March 27, 2026; the model now proves literals, `(quote ...)`, closed `if`, and closed `begin` expressions, and the proof layer now carries an explicit local readability predicate plus a ghost lemma showing pure model values satisfy it, plus a quote-shape lemma showing pure-subset quote forms expose pure quoted payloads, and `Pure_Subset_Expr` now exposes pure-subset facts for structurally well-formed `if` children through its postcondition, but the model still does not cover primitives or allocation
- `Proof.Refinement`: intended executable-vs-model refinement theorem, current status still scaffolded; focused `GNATPROVE_LEVEL=0 GNATPROVE_TIMEOUT=1 ./scripts/prove-adacore.sh -u proof-refinement.adb` is clean on March 27, 2026 apart from the expected warning about the currently unreferenced scaffold procedure, and the scaffold now evaluates the model and executable from the same successfully parsed term and copied initial runtime state, proves local readability for successful model results on the closed pure fragment, proves direct model/executable result equality for both literal atoms and structurally well-formed `quote` forms in that shared-state setup, and now also carries a local ghost helper that proves the two evaluators agree on any immediate literal-or-quote subexpression under that shared-state setup using `Lisp.Runtime.Immediate_Result` directly; the runtime/model contract surface now also exposes enough `if` child structure for the next refinement slice without a separate model-side `if` lemma procedure, but the full semantic theorem is still pending
- `app/lisp-main.adb`: intentional non-SPARK wrapper

Latest dedicated core-proof summary from `./scripts/prove-adacore.sh`:

- status note: a fresh full bounded `./scripts/prove-adacore.sh` run completed clean on March 27, 2026 with the script defaults, and the remaining proof-sensitive units are also clean under their focused lanes; `Lisp.Env` now closes in the full gate after restoring explicit frame-preservation and copied-name uniqueness lemmas
- warnings note: the current non-failing warnings are the expected unreferenced scaffold procedure in `proof-refinement.adb`, the unused initial values in `lisp-symbols.ads` and `lisp-env.ads`, the initialization-has-no-effect warnings in `lisp-primitives.adb`, and the local cursor initialization warning in `lisp-parser.adb`
- notes: focused semantic proof units remain clean on March 27, 2026 at `GNATPROVE_LEVEL=0` and `GNATPROVE_TIMEOUT=1`, except that the current `lisp-eval.adb` lane still benefits from `GNATPROVE_TIMEOUT=2`; the env uniqueness obligations also close with a stronger focused budget at `GNATPROVE_JOBS=32 GNATPROVE_LEVEL=0 GNATPROVE_TIMEOUT=2 GNATPROVE_PROVER=all ./scripts/prove-adacore.sh -u lisp-env.adb`, the quote-result contract slice remains clean in focused `lisp-eval.adb`, `lisp-model.adb`, and `proof-refinement.adb` runs, the runtime helper layer now includes a clean `if`-shape/accessor groundwork slice with explicit child ordering facts, a stronger `Immediate_Result` contract, and shared `if`-immediate-form/result helpers, the model now exports pure-subset facts for those `if` children directly from `Pure_Subset_Expr`, and `./scripts/with-adacore.sh ./scripts/test.sh` passes against the current tree

Project split:

- `lisp_prove.gpr` is the proof gate for `src/`, `app/`, and `proofs/`
- `lisp.gpr` remains the build-and-test project and includes `tests/`
- `scripts/prove.sh` serializes runs with a lock file, defaults to `-j0`, and
  passes through GNATprove selectors, uses `GNATPROVE_LEVEL=0` and
  `GNATPROVE_TIMEOUT=1` by default for fail-fast proof iteration, and accepts an optional
  `GNATPROVE_PROVER` override
- `scripts/install-adacore-community.sh` installs a repo-local Alire/AdaCore
  community toolchain under `.toolchains/adacore-community`
- `scripts/prove-adacore.sh` runs the same proof gate with that repo-local
  toolchain on `PATH`
- `scripts/test.sh` enforces executable regression coverage for the test programs

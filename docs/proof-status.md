# Proof Status

- `Lisp.Config`: intended full SPARK proof, current status core proof project clean
- `Lisp.Types`: intended full SPARK proof, current status core proof project clean
- `Lisp.Arith`: intended overflow and contract proof, current status core proof project clean
- `Lisp.Text_Buffers`: intended state and append proof, current status core proof project clean
- `Lisp.Symbols`: intended table validity proof, current status core proof project clean after slice-bound contract cleanup
- `Lisp.Store`: intended arena validity proof, current status core proof project clean after readability helper cleanup
- `Lisp.Env`: intended frame validity proof, current status core proof project clean for the dedicated proof gate
- `Lisp.Runtime`: intended bootstrap validity proof, current status core proof project clean
- `Lisp.Lexer`: intended token progress proof, current status core proof project clean after position/bounds invariants
- `Lisp.Parser`: intended runtime preservation proof, current status core proof project clean
- `Lisp.Printer`: intended canonical output proof, current status core proof project clean
- `Lisp.Primitives`: intended contract and safety proof, current status core proof project clean
- `Lisp.Eval`: intended fuel and contract proof, current status core proof project clean
- `Lisp.Driver`: intended end-to-end SPARK proof, current status core proof project clean
- `Lisp.Model`: intended ghost reference semantics for a closed pure fragment, current status focused `GNATPROVE_LEVEL=0 GNATPROVE_TIMEOUT=1 ./scripts/prove-adacore.sh -u lisp-model.adb` clean on March 27, 2026; the model now proves literals, `(quote ...)`, closed `if`, and closed `begin` expressions, and the proof layer now carries an explicit local readability predicate plus a ghost lemma showing pure model values satisfy it, but the model still does not cover primitives or allocation
- `Proof.Refinement`: intended executable-vs-model refinement theorem, current status still scaffolded; focused `GNATPROVE_LEVEL=0 GNATPROVE_TIMEOUT=1 ./scripts/prove-adacore.sh -u proof-refinement.adb` is clean on March 27, 2026 apart from the expected warning about the currently unreferenced scaffold procedure, and the scaffold now proves that successful model evaluation on the closed pure fragment produces a locally readable result; the full semantic theorem is still pending
- `app/lisp-main.adb`: intentional non-SPARK wrapper

Latest dedicated core-proof summary from `./scripts/prove-adacore.sh`:

- status note: focused semantic proof units remain clean on March 27, 2026 at `GNATPROVE_LEVEL=0` and `GNATPROVE_TIMEOUT=1`, but a fresh full bounded `./scripts/prove-adacore.sh` clean rebuild now reports additional medium messages in `lisp-primitives.ads`, `lisp-parser.adb`, `lisp-env.adb`, and `lisp-eval.ads`, so the repo-wide “full gate clean” claim should be treated as stale pending that broader cleanup
- warnings note: the focused semantic lane still only carries the expected non-failing warning about the currently unreferenced `Readable_Result_Refines_Model` scaffold procedure in `proof-refinement.adb`
- notes: parser contract cleanup now carries token cursor bounds, store-ref preservation, and environment validity through nested parse helpers, and the runtime/test scaffolding is aligned to the current `Max_Fuel` budget; use focused `./scripts/prove.sh -u ...` runs for local iteration, then widen back out to `./scripts/prove-adacore.sh`

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

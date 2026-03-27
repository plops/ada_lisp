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
- `Lisp.Model`: intended ghost reference semantics for a closed pure fragment, current status full bounded `./scripts/prove-adacore.sh` clean on March 27, 2026; the model now proves literals, `(quote ...)`, closed `if`, and closed `begin` expressions without delegating back to `Lisp.Eval`, but it does not yet cover primitives or allocation
- `Proof.Refinement`: intended executable-vs-model refinement theorem, current status still scaffolded; full bounded `./scripts/prove-adacore.sh` is clean on March 27, 2026 apart from the expected warning about the currently unreferenced scaffold procedure, and the full semantic theorem is still pending
- `app/lisp-main.adb`: intentional non-SPARK wrapper

Latest dedicated core-proof summary from `./scripts/prove-adacore.sh`:

- status note: clean with the repo-local AdaCore toolchain on March 27, 2026 using the script defaults `GNATPROVE_LEVEL=0`, `GNATPROVE_TIMEOUT=1`, and `GNATPROVE_JOBS=0`
- warnings note: expected non-failing warnings remain in `proof-refinement.adb`, `lisp-symbols.ads`, `lisp-env.ads`, `lisp-primitives.adb`, and `lisp-parser.adb`
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

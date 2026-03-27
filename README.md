[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/plops/ada_lisp)

# Ada Lisp v1

This repository implements the bounded Lisp core defined in `docs/semantics.md`.
The interpreter is designed for SPARK-first development: fixed capacities, array-
backed state, explicit fuel for evaluation, and a tiny non-SPARK I/O wrapper.

Recommended layout:

- `src/`: SPARK-capable interpreter units
- `proofs/`: ghost model and refinement checks
- `app/`: non-SPARK executable wrapper
- `tests/`: executable regression tests
- `scripts/`: build, test, and proof entry points

Build:

```bash
./scripts/build.sh
```

Proof:

```bash
./scripts/prove.sh
```

The proof script serializes concurrent runs with a lock file and uses a reduced
default proof budget. Override with `GNATPROVE_STEPS=<n>`,
`GNATPROVE_TIMEOUT=<seconds>`, optional `GNATPROVE_PROVER=<name>`, or
`GNATPROVE_JOBS=<n>` when a deeper run is needed.

For quick local iterations, pass GNATprove selectors directly, for example:

```bash
GNATPROVE_LEVEL=0 GNATPROVE_TIMEOUT=1 ./scripts/prove.sh -u lisp-eval.adb --limit-subp=Lisp.Eval.Eval
```

Tests:

```bash
./scripts/test.sh
```

## Alire-Based AdaCore Toolchain

For proof work, this repository also supports a repo-local Alire-installed
toolchain using the official community binaries. This avoids relying on the
system compiler/prover packaging.

Install:

```bash
./scripts/install-adacore-community.sh
```

By default the installer expects Alire at `~/Downloads/alire/bin/alr`. Override
that location with `ALR=/path/to/alr` if needed.

The install is kept local to this repository:

- Alire settings: `.alire-settings/`
- Toolchain prefix: `.toolchains/adacore-community/`

Run proofs with that toolchain:

```bash
./scripts/prove-adacore.sh
```

Run any other command with the same toolchain on `PATH`:

```bash
./scripts/with-adacore.sh gnatprove --version
./scripts/with-adacore.sh ./scripts/build.sh
./scripts/with-adacore.sh ./scripts/test.sh
```

Focused proof iteration works the same way through the wrapper:

```bash
GNATPROVE_LEVEL=0 GNATPROVE_TIMEOUT=1 ./scripts/prove-adacore.sh -u lisp-parser.adb
```

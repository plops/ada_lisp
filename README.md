# Ada Lisp v1

This repository implements the bounded Lisp core defined in `docs/semantics.md`.
The interpreter is designed for SPARK-first development: fixed capacities, array-
backed state, explicit fuel for evaluation, and a tiny non-SPARK I/O wrapper.

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
`GNATPROVE_TIMEOUT=<seconds>`, `GNATPROVE_PROVER=<name>`, or
`GNATPROVE_JOBS=<n>` when a deeper run is needed.

Tests:

```bash
./scripts/test.sh
```

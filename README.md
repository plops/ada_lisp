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

Tests:

```bash
./scripts/test.sh
```

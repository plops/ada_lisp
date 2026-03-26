# AGENTS

This file describes how to work in this repository without rediscovering the
same build and proof details each time.

## Purpose

`ada_lisp` is a bounded Lisp interpreter written for SPARK-oriented verification.
The codebase uses fixed capacities, array-backed state, explicit evaluation fuel,
and a small ghost model in `proofs/` for semantic refinement work.

## Repository Layout

- `src/`: main interpreter units and SPARK contracts
- `proofs/`: ghost model and refinement driver
- `app/`: executable entry point outside the proof core
- `tests/`: compiled regression tests
- `docs/`, `doc/`: semantics, invariants, proof notes, and implementation notes
- `scripts/`: canonical entry points for build, test, and proof runs

## Canonical Commands

Build the executable:

```bash
./scripts/build.sh
```

Run regression tests:

```bash
./scripts/test.sh
```

Run the default proof gate with the system toolchain:

```bash
./scripts/prove.sh
```

Run the default proof gate with the repo-local Alire/AdaCore toolchain:

```bash
./scripts/prove-adacore.sh
```

Use the AdaCore toolchain for any other command:

```bash
./scripts/with-adacore.sh gnatprove --version
./scripts/with-adacore.sh ./scripts/test.sh
```

## Toolchain Notes

The repository supports two modes:

- System toolchain: whatever `gnat`, `gprbuild`, and `gnatprove` are on `PATH`
- Repo-local Alire toolchain: installed under `.toolchains/adacore-community/`

Install the repo-local toolchain with:

```bash
./scripts/install-adacore-community.sh
```

By default this script uses `~/Downloads/alire/bin/alr`. Override with `ALR=...`
if Alire is somewhere else.

The directories `.alire-settings/` and `.toolchains/` are local state and should
not be committed.

## Proof Workflow

`lisp.gpr` is the build-and-test project.

`lisp_prove.gpr` is the proof project. The proof script:

- builds with `gprbuild -P lisp_prove.gpr`
- runs `gnatprove` in `check_all`, `flow`, then `prove`
- serializes concurrent proof runs with a lock file in `/tmp`
- defaults to a low proof budget for iterative work

Useful knobs:

- `GNATPROVE_LEVEL`
- `GNATPROVE_TIMEOUT`
- `GNATPROVE_STEPS`
- `GNATPROVE_JOBS`
- `GNATPROVE_PROVER`

Focused proof runs are preferred during contract work. Example:

```bash
GNATPROVE_LEVEL=0 GNATPROVE_TIMEOUT=1 ./scripts/prove-adacore.sh -u lisp-eval.adb --limit-subp=Lisp.Eval.Eval
```

## Current Proof Shape

The heavy proof debt is usually concentrated in:

- `Lisp.Parser`
- `Lisp.Eval`
- `Lisp.Env`
- `Lisp.Model`
- `Lisp.Printer`
- `Lisp.Primitives`

Typical issues are:

- cursor and slice bounds
- `Source'Last + 1` arithmetic
- fuel-decreasing recursive calls
- propagation of `Lisp.Runtime.Valid`
- list-element validity facts across loops and helpers

When proofs stall, prefer smaller helpers and stronger postconditions over piling
on local assertions.

## Editing Expectations

- Keep proof-oriented edits small and rerunnable.
- Do not revert unrelated user changes in a dirty worktree.
- Do not claim a proof status improvement without rerunning the relevant script.
- Prefer updating contracts and helper structure before adding many assertions.
- Keep documentation in sync when proof entry points or toolchain assumptions change.

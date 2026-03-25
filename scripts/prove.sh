#!/usr/bin/env bash
set -eu

lock_file="${TMPDIR:-/tmp}/ada_lisp_prove.lock"
prove_steps="${GNATPROVE_STEPS:-200}"
prove_jobs="${GNATPROVE_JOBS:-0}"
prove_timeout="${GNATPROVE_TIMEOUT:-10}"
prove_prover="${GNATPROVE_PROVER:-}"
prove_level="${GNATPROVE_LEVEL:-}"

exec 9>"$lock_file"
flock 9

units=()
for unit in src/*.ads src/*.adb proofs/*.ads proofs/*.adb; do
    units+=("$(basename "$unit")")
done

gprbuild -P lisp_prove.gpr
common_args=(-j"${prove_jobs}" -P lisp_prove.gpr "$@")

if [ "$#" -eq 0 ]; then
    common_args+=(-u "${units[@]}")
fi

gnatprove "${common_args[@]}" --mode=check_all
gnatprove "${common_args[@]}" --mode=flow

prove_args=("${common_args[@]}" --mode=prove --timeout="${prove_timeout}")
if [ -n "${prove_prover}" ]; then
    prove_args+=(--prover="${prove_prover}")
fi
if [ -n "${prove_level}" ]; then
    prove_args+=(--level="${prove_level}")
else
    prove_args+=(--steps="${prove_steps}")
fi

gnatprove "${prove_args[@]}"

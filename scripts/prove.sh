#!/usr/bin/env bash
set -eu

lock_file="${TMPDIR:-/tmp}/ada_lisp_prove.lock"
prove_steps="${GNATPROVE_STEPS:-200}"
prove_jobs="${GNATPROVE_JOBS:-0}"
prove_timeout="${GNATPROVE_TIMEOUT:-10}"
prove_prover="${GNATPROVE_PROVER:-cvc5}"

exec 9>"$lock_file"
flock 9

units=()
for unit in src/*.ads src/*.adb proofs/*.ads proofs/*.adb; do
    units+=("$(basename "$unit")")
done

gprbuild -P lisp_prove.gpr
gnatprove -j"${prove_jobs}" -P lisp_prove.gpr --mode=check_all -u "${units[@]}"
gnatprove -j"${prove_jobs}" -P lisp_prove.gpr --mode=flow -u "${units[@]}"
gnatprove -j"${prove_jobs}" -P lisp_prove.gpr --mode=prove --prover="${prove_prover}" --steps="${prove_steps}" --timeout="${prove_timeout}" -u "${units[@]}"

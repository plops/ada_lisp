#!/usr/bin/env bash
set -eu

units=()
for unit in src/*.ads src/*.adb proofs/*.ads proofs/*.adb; do
    units+=("$(basename "$unit")")
done

gprbuild -P lisp_prove.gpr
gnatprove -j0 -P lisp_prove.gpr --mode=check_all -u "${units[@]}"
gnatprove -j0 -P lisp_prove.gpr --mode=flow -u "${units[@]}"
gnatprove -j0 -P lisp_prove.gpr --mode=prove --steps=1000 -u "${units[@]}"

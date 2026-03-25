#!/usr/bin/env bash
set -eu

units=()
for unit in src/*.ads src/*.adb proofs/*.ads proofs/*.adb; do
    units+=("$(basename "$unit")")
done

gprbuild -P lisp.gpr
gnatprove -j0 -P lisp.gpr --mode=check_all -u "${units[@]}"
gnatprove -j0 -P lisp.gpr --mode=flow -u "${units[@]}"
gnatprove -j0 -P lisp.gpr --mode=prove --steps=1000 -u "${units[@]}"

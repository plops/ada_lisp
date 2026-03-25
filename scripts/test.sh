#!/usr/bin/env bash
set -eu

for test_src in tests/*.adb; do
    gprbuild -P lisp.gpr "$(basename "$test_src")"
done

for test_bin in bin/test-*; do
    "$test_bin"
done

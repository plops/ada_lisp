#!/usr/bin/env bash
set -eu

gprbuild -j0 -P lisp.gpr app/lisp-main.adb

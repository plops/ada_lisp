#!/usr/bin/env bash
set -eu

gprbuild -P lisp.gpr
gnatprove -P lisp.gpr --mode=check_all
gnatprove -P lisp.gpr --mode=flow
gnatprove -P lisp.gpr --mode=prove --steps=1000

#!/usr/bin/env bash
set -eu

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
toolchain_bin="${repo_root}/.toolchains/adacore-community/bin"

if [ ! -x "${toolchain_bin}/gnatprove" ]; then
    echo "error: AdaCore toolchain not installed in ${toolchain_bin}" >&2
    echo "run ./scripts/install-adacore-community.sh first" >&2
    exit 1
fi

export PATH="${toolchain_bin}:${PATH}"

exec "$@"

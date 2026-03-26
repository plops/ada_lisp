#!/usr/bin/env bash
set -eu

script_dir="$(cd "$(dirname "$0")" && pwd)"

exec "${script_dir}/with-adacore.sh" "${script_dir}/prove.sh" "$@"

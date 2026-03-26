#!/usr/bin/env bash
set -eu

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
alr_bin="${ALR:-$HOME/Downloads/alire/bin/alr}"
settings_dir="${repo_root}/.alire-settings"
install_prefix="${repo_root}/.toolchains/adacore-community"

if [ ! -x "${alr_bin}" ]; then
    echo "error: Alire not found at ${alr_bin}" >&2
    exit 1
fi

mkdir -p "${settings_dir}" "${install_prefix}"

"${alr_bin}" -n -s "${settings_dir}" install \
    --prefix="${install_prefix}" \
    gnat_native=15.2.1 \
    gprbuild=25.0.1 \
    gnatprove=15.1.0

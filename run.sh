#!/usr/bin/env bash

BLOG_ROOT="$(dirname ${0})"
SCRIPT_DIR="$(nix-build -A ${1} --no-out-link ${BLOG_ROOT}/make.nix)"
exec "${SCRIPT_DIR}/bin/script.sh"

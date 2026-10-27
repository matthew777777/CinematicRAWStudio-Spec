#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Backward-compatible local entry point; the shared installer also supports Linux.
set -euo pipefail
[[ "$(uname -s)" == Darwin ]] || { echo 'Use scripts/install.sh on Linux.' >&2; exit 1; }
if [[ -n "${PREFIX:-}" ]]; then export CRAW_PREFIX="$PREFIX"; fi
exec bash "$(cd "$(dirname "$0")" && pwd)/install.sh" "$@"

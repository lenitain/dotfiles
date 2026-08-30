#!/usr/bin/env bash
# DEPRECATED — thin wrapper around wrfm-shot.py, kept so old invocations of
# wrfm-shot.sh keep working unchanged. wrfm-shot.py is the real entry point
# (it adds shot ids, refuses to overwrite an existing PNG, and prints the
# identity line you must verify against the image). Prefer calling
# wrfm-shot.py directly; this wrapper only forwards to it.
#
# Usage (identical to before, all arguments are passed through):
#   wrfm-shot.sh <model.wrfm> <out.png>                  # six standard views, 2x3 montage
#   wrfm-shot.sh <model.wrfm> <out.png> --views front    # extra args go to `wrfm render`
set -euo pipefail

exec python3 "$(dirname "$0")/wrfm-shot.py" "$@"

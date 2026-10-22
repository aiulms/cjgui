#!/usr/bin/env bash
# Linux-native entry. See ../APPLICATION_TOOLS.md for explicit configuration.
set -euo pipefail
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$script_dir/linux_application.py" "$@"

#!/usr/bin/env bash
# Optional transport only. No default machine, framework, SDK or consumer.
# Example: linux_guest.sh --guest user@host -- build --app /linux/app ...
set -euo pipefail
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$script_dir/linux_application.py" ssh "$@"

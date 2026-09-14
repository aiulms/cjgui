#!/usr/bin/env zsh
set -euo pipefail

APP_DIR="$(cd "$(dirname "$0")" && pwd)"
if [[ -z "${CJGUI_ROOT:-}" ]]; then
  CJGUI_ROOT="$(cd "$APP_DIR/../.." && pwd)"
  export CJGUI_ROOT
fi
exec zsh "$CJGUI_ROOT/scripts/run_macos_application.sh" "$APP_DIR/cjgui_macos_app.sh" "$@"

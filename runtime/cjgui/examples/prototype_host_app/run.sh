#!/usr/bin/env zsh
set -euo pipefail

APP_DIR="$(cd "$(dirname "$0")" && pwd)"
CJGUI_ROOT="$(cd "$APP_DIR/../.." && pwd)"
export CJGUI_ROOT
exec zsh "$CJGUI_ROOT/scripts/run_macos_application.sh" "$APP_DIR/cjgui_macos_app.sh" "$@"

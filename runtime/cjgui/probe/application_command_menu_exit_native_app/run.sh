#!/usr/bin/env zsh
set -euo pipefail

APP_DIR="$(cd "$(dirname "$0")" && pwd)"
exec zsh "$APP_DIR/../../scripts/run_macos_application.sh" "$APP_DIR/cjgui_macos_app.sh" "$@"

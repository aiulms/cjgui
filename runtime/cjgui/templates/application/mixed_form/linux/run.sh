#!/usr/bin/env bash
# Build/run this application through the framework's Linux entry.
# CJGUI_CANGJIE_TOOLCHAIN is required (envsetup.sh or a toolchain directory).
set -euo pipefail
APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRAMEWORK_REL="$(python3 - "$APP_DIR/cjpm.toml" <<'PY'
import sys, tomllib
with open(sys.argv[1], "rb") as stream:
    print(tomllib.load(stream)["dependencies"]["cjgui"]["path"])
PY
)"
FRAMEWORK="$(cd "$APP_DIR/$FRAMEWORK_REL" && pwd)"
RUNNER="$FRAMEWORK/platforms/linux/scripts/run_linux_application.sh"
SOURCES="$FRAMEWORK/platforms/linux/framework-sources.txt"
TOOLCHAIN="${CJGUI_CANGJIE_TOOLCHAIN:-}"
OUTPUT="${CJGUI_LINUX_OUTPUT:-$APP_DIR/.cjgui/linux}"

usage() {
  cat >&2 <<'EOF'
usage: ./run.sh [all|build|run|package DEST|clean|diagnose] [-- app args]
  all (default)  build then run; use "./run.sh -- arg" to pass app args
  build          build only (extra runner flags allowed)
  run            run the existing receipt without rebuilding
  package DEST   package the existing receipt as a self-contained .tar.gz preview
  clean          retire this application's private target
  diagnose       one explicit build plus closure diagnostic
CJGUI_CANGJIE_TOOLCHAIN must name envsetup.sh or a toolchain directory.
EOF
  exit 2
}

[ -x "$RUNNER" ] || { echo "run: Linux application runner missing: $RUNNER" >&2; exit 2; }
[ -f "$SOURCES" ] || { echo "run: framework source list missing: $SOURCES" >&2; exit 2; }
[ -n "$TOOLCHAIN" ] || { echo "run: set CJGUI_CANGJIE_TOOLCHAIN to envsetup.sh or a toolchain directory" >&2; exit 2; }
BUILD_ARGS=(--app "$APP_DIR" --framework "$FRAMEWORK" --toolchain "$TOOLCHAIN"
            --output "$OUTPUT" --framework-sources "$SOURCES")
MODE="${1:-all}"
[ "$#" -gt 0 ] && shift

case "$MODE" in
  all|--)
    "$RUNNER" build "${BUILD_ARGS[@]}"
    exec "$RUNNER" run --output "$OUTPUT" -- "$@"
    ;;
  build) exec "$RUNNER" build "${BUILD_ARGS[@]}" "$@" ;;
  run) exec "$RUNNER" run --output "$OUTPUT" -- "$@" ;;
  package)
    [ "$#" -ge 1 ] || usage
    exec "$RUNNER" package --output "$OUTPUT" --destination "$1"
    ;;
  clean) exec "$RUNNER" clean --output "$OUTPUT" "$@" ;;
  diagnose) exec "$RUNNER" diagnose "${BUILD_ARGS[@]}" "$@" ;;
  *) usage ;;
esac
